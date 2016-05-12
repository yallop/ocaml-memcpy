(*
 * Copyright (c) 2016 Jeremy Yallop <yallop@gmail.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

open Ctypes

let prologue = "
#include <string.h>

static void *memcpy_with_offsets
  (char *dst, const char *src, size_t len, int dst_off, int src_off)
{
  return memcpy(dst + dst_off, src + src_off, len);
}
"

let () =
  let prefix = "memcpy_" in
  let stubs_oc = open_out "lib/memcpy_stubs.c" in
  let fmt = Format.formatter_of_out_channel stubs_oc in
  Format.fprintf fmt "%s@." prologue;
  Cstubs.write_c fmt ~prefix (module Memcpy_bindings.C);
  close_out stubs_oc;

  let generated_oc = open_out "lib/memcpy_generated.ml" in
  let fmt = Format.formatter_of_out_channel generated_oc in
  Cstubs.write_ml fmt ~prefix (module Memcpy_bindings.C);
  close_out generated_oc
