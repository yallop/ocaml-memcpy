(*
 * Copyright (c) 2016 Jeremy Yallop.
 *
 * This file is distributed under the terms of the MIT License.
 * See the file LICENSE for details.
 *)

open OUnit2
open Bigarray


module type BUF =
sig
  type t
  type safe
  val name : string
  val t : int -> (safe, t) Memcpy.spec
  val to_string : t -> string
  val of_string : string -> t
end

module Bytes_buf :
  BUF with type t = Bytes.t
       and type safe = Memcpy.safe =
struct
  include Bytes
  type safe = Memcpy.safe
  let t _ = Memcpy.ocaml_bytes
  let name = "bytes"
end

module Bigarray_buf :
  BUF with type t = (char, int8_unsigned_elt, c_layout) Array1.t
       and type safe = Memcpy.safe =
struct
  type t = (char, int8_unsigned_elt, c_layout) Array1.t
  type safe = Memcpy.safe
  let t sz = Memcpy.bigarray Ctypes.array1 sz Bigarray.char

  let to_string a =
    let len = Array1.dim a in
    let buf = Bytes.make len '\000' in
    begin
      for i = 0 to len - 1 do
        Bytes.set buf i (Array1.get a i)
      done;
      Bytes_buf.to_string buf
    end

  let of_string s =
    let arr = Array1.create char c_layout (String.length s) in
    let () = String.iteri (Array1.set arr) s in
    arr

  let name = "bigarray"
end

module CArray_buf :
  BUF with type t = char Ctypes.carray
       and type safe = Memcpy.safe =
struct
  type t = char Ctypes.carray
  type safe = Memcpy.safe
  let t sz = Memcpy.carray

  let to_string a =
    let len = Ctypes.CArray.length a in
    let buf = Bytes.make len '\000' in
    begin
      for i = 0 to len - 1 do
        Bytes.set buf i (Ctypes.CArray.get a i)
      done;
      Bytes_buf.to_string buf
    end

  let of_string s =
    let arr = Ctypes.(CArray.make char) (String.length s) in
    let () = String.iteri (Ctypes.CArray.set arr) s in
    arr

  let name = "carray"
end


module type TESTS = sig val tests : test end


module Safe_tests
    (In:  BUF with type safe = Memcpy.safe)
    (Out: BUF with type safe = Memcpy.safe) : TESTS =
struct
  let check_bounds_failure ?src_off ?dst_off ?len ~from ~into () =
    let dstlen = String.length into
    and srclen = String.length from
    and dst = Out.of_string into
    and src = In.of_string from in
    let len = match len with None -> srclen | Some len -> len in
    assert_raises (Invalid_argument "Memcpy.memcpy")
      (fun () ->
         Memcpy.memcpy (In.t srclen) (Out.t dstlen)
           ~src ~dst ?src_off ?dst_off ~len)

  let check_copying ?src_off ?dst_off ?len ~from ~into ~produces () =
    let dstlen = String.length into
    and srclen = String.length from
    and dst = Out.of_string into
    and src = In.of_string from in
    let len = match len with None -> srclen | Some len -> len in
    let () = Memcpy.memcpy (In.t srclen) (Out.t dstlen)
        ~src ~dst ?src_off ?dst_off ~len
    in
    assert_equal produces (Out.to_string dst)
      ~printer:(fun x -> x)

  let check_copying_bytes ?dst_off ~from ~into ~produces () =
    let dstlen = String.length into
    and dst = Out.of_string into
    and src = Bytes.of_string from in
    let () = Memcpy.memcpy_from_bytes (Out.t dstlen)
      ~src ~dst ?dst_off
    in
    assert_equal produces (Out.to_string dst)
      ~printer:(fun x -> x)

  let check_copying_string ?dst_off ~from ~into ~produces () =
    let dstlen = String.length into
    and dst = Out.of_string into
    and src = from in
    let () = Memcpy.memcpy_from_string (Out.t dstlen)
      ~src ~dst ?dst_off
    in
    assert_equal produces (Out.to_string dst)
      ~printer:(fun x -> x)

  let test_full_overlap _ =
    check_copying
      ~from:    "abcdefghijkl"
      ~into:    "0123456789AB"
      ~produces:"abcdefghijkl"
      ()

  let test_full_overlap_bytes _ =
    check_copying_bytes
      ~from:    "abcdefghijkl"
      ~into:    "0123456789AB"
      ~produces:"abcdefghijkl"
      ()

  let test_full_overlap_string _ =
    check_copying_string
      ~from:    "abcdefghijkl"
      ~into:    "0123456789AB"
      ~produces:"abcdefghijkl"
      ()

  let test_short_src _ =
    check_copying
      ~from:    "abc"
      ~into:    "0123456789AB"
      ~produces:"abc3456789AB"
      ()

  let test_short_src_with_dst_offset _ =
    check_copying
      ~dst_off:3
      ~from:    "abc"
      ~into:    "0123456789AB"
      ~produces:"012abc6789AB"
      ()

  let test_short_src_with_dst_offset_bytes _ =
    check_copying_bytes
      ~dst_off:3
      ~from:    "abc"
      ~into:    "0123456789AB"
      ~produces:"012abc6789AB"
      ()

  let test_short_src_with_dst_offset_string _ =
    check_copying_string
      ~dst_off:3
      ~from:    "abc"
      ~into:    "0123456789AB"
      ~produces:"012abc6789AB"
      ()

  let test_with_src_offset_and_len _ =
    check_copying
      ~src_off:5
      ~len:3
      ~from:    "abcdefghijkl"
      ~into:    "0123456789AB"
      ~produces:"fgh3456789AB"
      ()

  let test_with_src_offset_and_dst_offset_and_len _ =
    check_copying
      ~src_off:5
      ~dst_off:1
      ~len:3
      ~from:    "abcdefghijkl"
      ~into:    "0123456789AB"
      ~produces:"0fgh456789AB"
      ()

  let test_bounds_failure_src_offset_below_zero _ =
    check_bounds_failure
      ~src_off:(-1)
      ~len:1
      ~from: "abc"
      ~into: "def"
      ()

  let test_bounds_failure_len_below_zero _ =
    check_bounds_failure
      ~len:(-1)
      ~from: "abc"
      ~into: "def"
      ()

  let test_bounds_failure_dst_offset_below_zero _ =
    check_bounds_failure
      ~dst_off:(-1)
      ~from: "abc"
      ~into: "def"
      ()

  let test_bounds_failure_length_exceeds_src_length _ =
    check_bounds_failure
      ~len:4
      ~from: "abc"
      ~into: "def"
      ()

  let test_bounds_failure_length_exceeds_dst_length _ =
    check_bounds_failure
      ~len:4
      ~from: "abcd"
      ~into: "def"
      ()

  let test_bounds_failure_offset_plus_length_exceeds_src_length _ =
    check_bounds_failure
      ~src_off:2
      ~len:2
      ~from: "abc"
      ~into: "def"
      ()

  let test_bounds_failure_offset_plus_length_exceeds_dst_length _ =
    check_bounds_failure
      ~len:2
      ~dst_off:2
      ~from: "abcd"
      ~into: "def"
      ()

  let tests =
    Printf.sprintf "safe tests (from %s to %s)"
      In.name Out.name >::: [
      "full overlap" >::
      test_full_overlap;
      
      "full overlap (bytes)" >::
      test_full_overlap_bytes;
      
      "full overlap (string)" >::
      test_full_overlap_string;
      
      "short source" >::
      test_short_src;

      "short source with dst offset" >::
      test_short_src_with_dst_offset;

      "short source with dst offset (bytes)" >::
      test_short_src_with_dst_offset_bytes;

      "short source with dst offset (string)" >::
      test_short_src_with_dst_offset_string;

      "short source with src offset and length" >::
      test_with_src_offset_and_len;

      "short source with src offset and dst offset and length" >::
      test_with_src_offset_and_dst_offset_and_len;

      "test failure when src_off is_below_zero" >::
      test_bounds_failure_src_offset_below_zero;

      "test failure when length is_below_zero" >::
      test_bounds_failure_len_below_zero;

      "test failure when dst_off is_below_zero" >::
      test_bounds_failure_dst_offset_below_zero;

      "test failure when length exceeds src length" >::
      test_bounds_failure_length_exceeds_src_length;

      "test failure when length exceeds dst length" >::
      test_bounds_failure_length_exceeds_dst_length;

      "test failure when offset+length exceeds src length" >::
      test_bounds_failure_offset_plus_length_exceeds_src_length;

      "test failure when offset+length exceeds dst length" >::
      test_bounds_failure_offset_plus_length_exceeds_dst_length;
    ]
end


let suite =
  "Memcpy tests" >:::
  List.map (fun (module T: TESTS) -> T.tests)
    ([(module Safe_tests(Bytes_buf)    (Bytes_buf));
      (module Safe_tests(Bytes_buf)    (Bigarray_buf));
      (module Safe_tests(Bytes_buf)    (CArray_buf));
      (module Safe_tests(Bigarray_buf) (Bytes_buf));
      (module Safe_tests(Bigarray_buf) (Bigarray_buf));
      (module Safe_tests(Bigarray_buf) (CArray_buf));
      (module Safe_tests(CArray_buf)   (Bytes_buf));
      (module Safe_tests(CArray_buf)   (Bigarray_buf));
      (module Safe_tests(CArray_buf)   (CArray_buf));
    ] : (module TESTS) list)



let _ =
  run_test_tt_main suite
