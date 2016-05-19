## ocaml-memcpy

There are several ways of storing and accessing blocks of memory in an OCaml program, including

* [`bytes`][bytes] and [`string`][string] values for mutable and immutable strings that reside in the OCaml heap
* [`bigarray`][bigarray] values for reference-counted blocks that reside in the OCaml heaps
* [Ctypes][ocaml-ctypes] [`ptr`][ctypes-pointer] values that can be used to address arbitrary addresses using typed descriptions of the memory layout.
* Ctypes [`carray`][ctypes-array] values that provide bounds-checked access to `ptr`-addressed memory.

The [`Memcpy`][memcpy-module] provides functions for safely and efficiently copying blocks of memory between these different representations.

[string]: http://caml.inria.fr/pub/docs/manual-ocaml/libref/String.html
[bytes]: http://caml.inria.fr/pub/docs/manual-ocaml/libref/Bytes.html
[bigarray]: http://caml.inria.fr/pub/docs/manual-ocaml/libref/Bigarray.html
[ctypes-pointer]: http://ocamllabs.github.io/ocaml-ctypes/Ctypes.html#pointer_types
[ctypes-array]: http://ocamllabs.github.io/ocaml-ctypes/Ctypes.html#4_Carraytypes
[ocaml-ctypes]: https://github.com/ocamllabs/ocaml-ctypes/
[memcpy-module]: https://github.com/yallop/ocaml-memcpy/blob/master/lib/memcpy.mli
