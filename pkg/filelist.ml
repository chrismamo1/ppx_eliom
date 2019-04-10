type descr = {
  interface_only : string list;
  interface : string list;
  internal : string list;
}

let ocamlbuild = {
  interface_only = [];
  interface = [ "ocamlbuild_eliom" ];
  internal = []

}

let ppx = {
  interface_only = [];
  interface = [ "ppx_eliom" ; "ppx_eliom_client" ; "ppx_eliom_type" ; "ppx_eliom_server" ];
  internal = [ "ppx_eliom_utils" ];
}


let (-.-) name ext = name ^ "." ^ ext
let exts el sl =
  List.flatten (
    List.map (fun ext ->
        List.map (fun name ->
            name -.- ext) sl) el)

let list_to_file filename list =
  let oc = open_out filename in
  List.iter (fun s ->
      output_string oc s;
      output_char oc '\n';
    ) list;
  close_out oc;;

let ocamlbuild_mllib = ocamlbuild.interface @ ocamlbuild.internal
let ocamlbuild_extra =
  exts ["cmi"] (ocamlbuild.interface_only @ ocamlbuild.interface) @
  exts ["cmx"] (ocamlbuild.interface @ ocamlbuild.internal)
let ocamlbuild_api = ocamlbuild.interface_only @ ocamlbuild.interface

let ppx_mllib = ppx.interface @ ppx.internal
let ppx_extra =
  exts ["cmi"] ppx.interface @
  exts ["cmx"] (ppx.interface @ ppx.internal)
let ppx_api = ppx.interface


let templates_dir = "pkg/distillery"
let templates = Array.to_list (Sys.readdir templates_dir)
let templates_files =
  List.map (fun name ->
    name, Array.to_list (Sys.readdir (templates_dir^"/"^name))) templates
