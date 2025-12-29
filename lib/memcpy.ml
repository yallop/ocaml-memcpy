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

module C = Memcpy_bindings.C(Memcpy_generated)

type safe = Safe
type unsafe = Unsafe

type (_, _) spec =
    OCaml_bytes : (safe, Bytes.t) spec
  | Bigarray :
      < ba_repr : 'a; bigarray : 'b; carray : 'c; dims : 'd; element : 'e;
        layout: Bigarray.c_layout > bigarray_class *
      'd *
      ('e, 'a) Bigarray.kind ->
    (safe, 'b) spec
  | Pointer : (unsafe, _ ptr) spec
  | CArray : (safe, _ carray) spec

let ocaml_bytes = OCaml_bytes
let bigarray b k s = Bigarray (b, k, s)
let pointer = Pointer
let carray = CArray

type 'a safespec = (safe, 'a) spec


let convert_pointer : 'a. 'a ptr -> int -> unit ptr =
  fun ptr offset -> to_voidp ptr +@ offset


let rec unsafe_memcpy : type s d s' d'.src:s -> dst:d -> ?src_off:int -> ?dst_off:int ->
                                           len:int -> (s', s) spec -> (d', d) spec -> unit =
  fun ~src ~dst ?(src_off=0) ?(dst_off=0) ~len  inspec outspec ->
    match inspec, outspec with
    | _, Bigarray (cls, _, _) ->
      unsafe_memcpy ~src ~dst:(bigarray_start cls dst) ~src_off ~dst_off ~len inspec Pointer
    | Bigarray (cls, _, _), _ ->
      unsafe_memcpy ~src:(bigarray_start cls src) ~dst ~src_off ~dst_off ~len Pointer outspec
    | _, CArray ->
      unsafe_memcpy ~src ~dst:(CArray.start dst) ~src_off ~dst_off ~len inspec Pointer
    | CArray, _ ->
      unsafe_memcpy ~src:(CArray.start src) ~dst ~src_off ~dst_off ~len Pointer outspec
    | OCaml_bytes, OCaml_bytes ->
      ignore (C.memcpy_bytes_bytes (ocaml_bytes_start dst) (ocaml_bytes_start src)
                (Unsigned.Size_t.of_int len) dst_off src_off : unit ptr)
    | OCaml_bytes, Pointer ->
      ignore (C.memcpy_ptr_bytes (to_voidp dst) (ocaml_bytes_start src)
                (Unsigned.Size_t.of_int len) dst_off src_off : unit ptr)
    | Pointer, OCaml_bytes ->
      ignore (C.memcpy_bytes_ptr (ocaml_bytes_start dst) (to_voidp src)
                (Unsigned.Size_t.of_int len) dst_off src_off : unit ptr)
    | Pointer, Pointer ->
      ignore (C.memcpy_ptr_ptr (to_voidp dst) (to_voidp src)
                (Unsigned.Size_t.of_int len)  dst_off src_off : unit ptr)


let length : type a. (safe, a) spec -> a -> int =
  fun spec v -> match spec with
    OCaml_bytes -> Bytes.length v
  | Bigarray (cls, dims, k) -> sizeof (Ctypes.bigarray cls dims k)
  | CArray -> CArray.length v * sizeof (CArray.element_type v)
  

let memcpy : type s d. src:s -> dst:d -> ?src_off:int -> ?dst_off:int -> len:int ->
                           (safe, s) spec -> (safe, d) spec -> unit =
  fun ~src ~dst ?(src_off=0) ?(dst_off=0) ~len inspec outspec ->
    if len < 0 || src_off < 0 || src_off > length inspec src - len
               || dst_off < 0 || dst_off > length outspec dst - len 
    then invalid_arg "Memcpy.memcpy"
    else unsafe_memcpy inspec outspec ~src ~dst ~src_off ~dst_off ~len

let memcpy_from_string ~src ?dst_off ~dst d =
  memcpy ~src:(Bytes.unsafe_of_string src) ?src_off:None
    ~dst ?dst_off ~len:(String.length src) OCaml_bytes d

let memcpy_from_bytes ~src ?dst_off ~dst d =
  memcpy ~src ?src_off:None
    ~dst ?dst_off ~len:(Bytes.length src) OCaml_bytes d
