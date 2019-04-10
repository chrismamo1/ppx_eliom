#!/usr/bin/env ocaml
#directory "pkg";;
#use "topkg.ml";;
#use "filelist.ml"

(* DEBUG ONLY *)
let nothing_should_be_rebuilt=false
let except = function
  (* cmxs are regerated every time ( bug in ocamlbuild rule) *)
  | ".cmxs" when nothing_should_be_rebuilt -> false
  | _ -> true
(* END *)

let exts_syntax = List.filter except [".cmo";".cmx";".cma";".cmxa";".cmxs";".a"]
let exts_modlib = List.filter except Exts.module_library
let exts_lib = List.filter except Exts.library

let _ =

  list_to_file "src/ppx/ppx.mllib" ppx_mllib;
  list_to_file "src/ppx/ppx.mldylib" ppx_mllib;
  list_to_file "src/ppx/api.odocl" ppx_api;

  list_to_file "src/ppx/ppx.mllib" ppx_mllib;
  list_to_file "src/ppx/ppx.mldylib" ppx_mllib;
  list_to_file "src/ppx/api.odocl" ppx_api

let spf = Printf.sprintf

let nothing =
  if nothing_should_be_rebuilt
  then "-nothing-should-be-rebuilt"
  else ""

let builder = `Other ("_build/build/build.native","_build")

let with_man3 = Env.bool "manpage"

let () =
  Pkg.describe "eliom" ~builder ([
    (* META *)
    Pkg.lib "pkg/META";

    (* MANPAGE *)
    Pkg.man ~dst:"man1/eliomc.1" "pkg/man/eliomc.1";
    Pkg.man ~dst:"man1/eliomcp.1" "pkg/man/eliomc.1";
    Pkg.man ~dst:"man1/eliomopt.1" "pkg/man/eliomc.1";
    Pkg.man ~dst:"man1/eliomdep.1" "pkg/man/eliomc.1";
    Pkg.man ~dst:"man1/js_of_eliom.1" "pkg/man/eliomc.1";
    Pkg.man ~dst:"man1/eliom-distillery.1" "pkg/man/eliom-distillery.1";

    Pkg.man ~cond:with_man3 ~dst:"man3/%.3oc" ~target:"src/lib/client/api.mandocdir/man.3oc" "src/lib/client/api.mandocdir/%.3oc";
    Pkg.man ~cond:with_man3 ~dst:"man3/%.3os" ~target:"src/lib/server/api.mandocdir/man.3os" "src/lib/server/api.mandocdir/%.3os";
    Pkg.man ~cond:with_man3 ~dst:"man3/%.3o"  ~target:"src/ocamlbuild/api.mandocdir/man.3o"  "src/ocamlbuild/api.mandocdir/%.3o";
    Pkg.man ~cond:with_man3 ~dst:"man3/%.3o"  ~target:"src/ppx/api.mandocdir/man.3o"  "src/ppx/api.mandocdir/%.3o";

    (* PPX *)
    Pkg.lib ~exts:Exts.module_library ~dst:"ppx/ppx_eliom" "src/ppx/ppx_eliom";
    Pkg.lib ~exts:Exts.module_library ~dst:"ppx/ppx_eliom_client" "src/ppx/ppx_eliom_client";
    Pkg.lib ~exts:Exts.module_library ~dst:"ppx/ppx_eliom_type" "src/ppx/ppx_eliom_type";
    Pkg.lib ~exts:Exts.module_library ~dst:"ppx/ppx_eliom_server" "src/ppx/ppx_eliom_server";

    Pkg.bin ~auto:true ~dst:"ppx_eliom_client" "src/ppx/ppx_eliom_client_ex" ;
    Pkg.bin ~auto:true ~dst:"ppx_eliom_server" "src/ppx/ppx_eliom_server_ex" ;
    Pkg.bin ~auto:true ~dst:"ppx_eliom_types" "src/ppx/ppx_eliom_types_ex"

  ] @ [
    (* MISC *)

    Pkg.doc "README.md";
    Pkg.doc "CHANGES";
    Pkg.etc "pkg/etc/mime.types"
  ] @ (
    List.flatten (
      List.map (fun (name,files) ->
          List.map (fun file ->
              Pkg.lib ~dst:(spf "templates/%s/%s" name file) (spf "%s/%s/%s" templates_dir name file)
            ) files) templates_files )
  ))
