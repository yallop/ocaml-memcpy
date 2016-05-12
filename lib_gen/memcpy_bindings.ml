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

module C(F: Cstubs.FOREIGN) = struct
  open F

  let memcpy dst src =
    foreign "memcpy_with_offsets"
      (dst @-> src @-> size_t @-> int @-> int @-> returning (ptr void))

  let s = ocaml_bytes and p = ptr void
  let memcpy_bytes_bytes = memcpy s s
  let memcpy_bytes_ptr   = memcpy s p
  let memcpy_ptr_bytes   = memcpy p s
  let memcpy_ptr_ptr     = memcpy p p
end
