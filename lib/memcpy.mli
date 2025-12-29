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

(** Efficient copies between various types of memory blocks: bytes, bigarrays,
    addresses and arrays *)

open Ctypes

(** The types of memory are divided into two classes: [safe], where the bounds
    can be checked, and [unsafe], where no bounds information is available. *)
type safe and unsafe

(** A specification for the type of memory involved in the copy. *)
type ('safe, 'typ) spec

val ocaml_bytes : (safe, Bytes.t) spec
(** A specification for OCaml's bytes type *)

val bigarray :
  < ba_repr : 'a; bigarray : 'b; carray : 'c; dims : 'd; element : 'e;
    layout: Bigarray.c_layout > bigarray_class ->
  'd -> ('e, 'a) Bigarray.kind -> (safe, 'b) spec
(** A specification for a bigarray type *)

val pointer : (unsafe, _ ptr) spec
(** A specification for a Ctypes pointer type *)

val carray : (safe, _ carray) spec
(** A specification for a Ctypes array type *)

val memcpy : src:'s -> dst:'d -> ?src_off:int -> ?dst_off:int -> len:int -> (safe, 's) spec -> (safe, 'd) spec -> unit
(** [memcpy ~src ~dst ~src_off ~dst_off ~len s d] copies [len] bytes from
    offset [src_off] of [src] to offset [dst_off] of [dst].

    @raise [Invalid_argument "Memcpy.memcpy"] if the memory between [src_off]
    and [src_off + len] does not fall within [src] or if the memory between
    [dst_off] and [dst_off + len] does not fall within [dst]. *)

val unsafe_memcpy : src:'s -> dst:'d -> ?src_off:int -> ?dst_off:int -> len:int -> (_, 's) spec -> (_, 'd) spec -> unit
(** [unsafe_memcpy ~src ~dst ~src_off ~dst_off ~len s d] copies [len] bytes from
    offset [src_off] of [src] to offset [dst_off] of [dst].

    No attempt is made to check that the specified regions of memory actually
    fall within [src] and [dst]. *)

val memcpy_from_string : src:string -> ?dst_off:int -> dst:'d -> (safe, 'd) spec -> unit
(** [memcpy_from_string ~src ~dst ~dst_off d] copies [src] to offset [dst_off] of [dst].

    @raise [Invalid_argument "Memcpy.memcpy"] if the memory between
    [dst_off] and [dst_off + len] does not fall within [dst]. *)

val memcpy_from_bytes : src:Bytes.t -> ?dst_off:int -> dst:'d -> (safe, 'd) spec -> unit
(** [memcpy_from_bytes ~src ~dst ~dst_off d] copies [src] to offset [dst_off] of [dst].

    @raise [Invalid_argument "Memcpy.memcpy"] if the memory between
    [dst_off] and [dst_off + len] does not fall within [dst]. *)
