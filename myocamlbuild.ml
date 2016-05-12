open Ocamlbuild_plugin;;
open Ocamlbuild_pack;;

let ctypes_libdir = Sys.getenv "CTYPES_LIB_DIR" in

dispatch begin
  function
  | After_rules ->

    rule "cstubs: lib/x_bindings.ml -> x_stubs.c, x_generated.ml"
      ~prods:["lib/%_stubs.c"; "lib/%_generated.ml"]
      ~deps: ["lib_gen/%_bindgen.byte"]
      (fun env build ->
        Cmd (A(env "lib_gen/%_bindgen.byte")));

    copy_rule "cstubs: lib_gen/x_bindings.ml -> lib/x_bindings.ml"
      "lib_gen/%_bindings.ml" "lib/%_bindings.ml";

    (* Linking cstubs *)
    flag ["c"; "compile"; "use_ctypes"] & S[A"-I"; A ctypes_libdir];
    flag ["c"; "compile"; "debug"] & A"-g";

    (* Linking generated stubs *)
    flag ["ocaml"; "link"; "byte"; "library"; "use_memcpy_stubs"] &
      S[A"-dllib"; A"-lmemcpy_stubs"];
    flag ["ocaml"; "link"; "native"; "library"; "use_memcpy_stubs"] &
      S[A"-cclib"; A"-lmemcpy_stubs"];

    (* Linking tests *)
    flag ["ocaml"; "link"; "byte"; "program"; "use_memcpy_stubs"] &
      S[A"-dllib"; A"-lmemcpy_stubs"; A"-I"; A"lib/"];
    dep ["ocaml"; "link"; "native"; "program"; "use_memcpy_stubs"]
      ["lib/libmemcpy_stubs"-.-(!Options.ext_lib)];
  | _ -> ()
end;;
