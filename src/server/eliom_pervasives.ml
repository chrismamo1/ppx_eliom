
include Eliom_pervasives_base

module Filename = Ocsigen_pervasives.Filename
module Printexc = Ocsigen_pervasives.Printexc

(*****************************************************************************)

module Url = struct

  include Ocsigen_pervasives.Url

  let remove_internal_slash u =
    let rec aux = function
      | [] -> []
      | [a] -> [a]
      | ""::l -> aux l
      | a::l -> a::(aux l)
    in match u with
    | [] -> []
    | a::l -> a::(aux l)

  let change_empty_list = function
    | [] -> [""] (* It is not possible to register an empty URL *)
    | l -> l
  let make_encoded_parameters = Netencoding.Url.mk_url_encoded_parameters

  let encode = Ocsigen_pervasives.Url.encode
  let decode = Ocsigen_pervasives.Url.decode

end

(*****************************************************************************)

module String = struct

  include Ocsigen_pervasives.String

  (* Cut a string to the next separator *)
  let basic_sep char s =
    try
      let seppos = String.index s char in
      ((String.sub s 0 seppos),
       (String.sub s (seppos+1)
          ((String.length s) - seppos - 1)))
    with Invalid_argument _ -> raise Not_found

  (* returns the index of the first difference between s1 and s2,
     starting from n and ending at last.
     returns (last + 1) if no difference is found.
   *)
  let rec first_diff s1 s2 n last =
    try
      if s1.[n] = s2.[n]
      then
	if n = last
	then last+1
	else first_diff s1 s2 (n+1) last
      else n
    with Invalid_argument _ -> n

  let may_append s1 ~sep = function
    | "" -> s1
    | s2 -> s1^sep^s2

  let may_concat s1 ~sep s2 = match s1, s2 with
  | _, "" -> s1
  | "", _ -> s2
  | _ -> String.concat sep [s1;s2]

  let make_cryptographic_safe = Ocsigen_pervasives.String.make_cryptographic_safe

end

(*****************************************************************************)

module List = struct
  include Ocsigen_pervasives.List
  let rec remove_all_assoc a = function
    | [] -> []
    | (b, _)::l when a = b -> remove_all_assoc a l
    | b::l -> b::(remove_all_assoc a l)
  let rec remove_first_if_any a = function
    |  [] -> []
    | b::l when a = b -> l
    | b::l -> b::(remove_first_if_any a l)
  let rec remove_first_if_any_q a = function
    |  [] -> []
    | b::l when a == b -> l
    | b::l -> b::(remove_first_if_any_q a l)
end

(*****************************************************************************)

module Ip_address = struct

  include Ocsigen_pervasives.Ip_address

  let network_of_ip ip mask4 (mask61, mask62) = match ip with
  | IPv4 a -> IPv4 (Int32.logand a mask4)
  | IPv6 (a, b) -> IPv6 (Int64.logand a mask61, Int64.logand b mask62)

  let inet6_addr_loopback =
    fst (parse (Unix.string_of_inet_addr Unix.inet6_addr_loopback))

end

(*****************************************************************************)

module Int = struct

  module Table = Map.Make(struct
    type t = int
    let compare = compare
  end)

end

(*****************************************************************************)

let to_json ?typ v =
  match typ with
    | Some typ -> Deriving_Json.to_string typ v
    | None -> assert false (* implemented only client side *)

let of_json ?typ s =
  match typ with
    | Some typ -> Deriving_Json.from_string typ s
    | None -> assert false (* implemented only client side *)

module XML = struct
  include Eliom_pervasives_base.RawXML

  let cdata s = (* GK *)
    (* For security reasons, we do not allow "]]>" inside CDATA
       (as this string is to be considered as the end of the cdata)
     *)
    let s' = "\n<![CDATA[\n"^
      (Netstring_pcre.global_replace
	 (Netstring_pcre.regexp_string "]]>") "" s)
      ^"\n]]>\n" in
    encodedpcdata s'

  let cdata_script s = (* GK *)
    (* For security reasons, we do not allow "]]>" inside CDATA
       (as this string is to be considered as the end of the cdata)
     *)
    let s' = "\n//<![CDATA[\n"^
      (Netstring_pcre.global_replace
	 (Netstring_pcre.regexp_string "]]>") "" s)
      ^"\n//]]>\n" in
    encodedpcdata s'

  let cdata_style s = (* GK *)
    (* For security reasons, we do not allow "]]>" inside CDATA
       (as this string is to be considered as the end of the cdata)
     *)
    let s' = "\n/* <![CDATA[ */\n"^
      (Netstring_pcre.global_replace
	 (Netstring_pcre.regexp_string "]]>") "" s)
      ^"\n/* ]]> */\n" in
    encodedpcdata s'

  let make_unique ?copy elt =
    let id = match copy with
      | Some copy -> copy.unique_id
      | None -> Some (String.make_cryptographic_safe ()) in
    { elt with unique_id = id }

  (** Ref tree *)

  let cons_attrib att acc = match racontent att with
    | RACamlEvent (n,oc) -> (n, oc) :: acc
    | _ -> acc

  let rec make_ref_tree elt =
    let id = get_unique_id elt in
    let attribs, childrens = match content elt with
      | Empty | EncodedPCDATA _ | PCDATA _
      | Entity _ | Comment _  -> [], []
      | Leaf (_, attribs) ->
	List.fold_right cons_attrib attribs [],
	[]
      | Node (_, attribs, elts) ->
	List.fold_right cons_attrib attribs [],
	make_ref_tree_list elts
    in
    match id, attribs, childrens with
      | None, [], [] -> Ref_empty 0
      | _ -> Ref_node (id, attribs, childrens)

  and make_ref_tree_list l =
    let aggregate elt acc =
      let elt = make_ref_tree elt in
      if elt = Ref_empty 0 then
	match acc with
	  | [] -> []
	  | Ref_empty i :: acc -> Ref_empty (succ i) :: acc
	  | acc -> Ref_empty 1 :: acc
      else elt :: acc in
    List.fold_right aggregate l []

  and make_attrib_list l =
    let aggregate a acc = match racontent a with
      | RACamlEvent (n, ev) ->
	(n, ev) :: acc
      | _ -> acc in
    List.fold_right aggregate l []


end

module SVG = struct
  module M = struct
      include SVG_f.Make(XML)
      let unique elt = tot (XML.make_unique (toelt elt))
  end
  module P = XML_print.MakeTypedSimple(XML)(M)
end

module HTML5 = struct
  module M = struct
      include HTML5_f.Make(XML)(SVG.M)
      let unique elt = tot (XML.make_unique (toelt elt))
  end
  module P = XML_print.MakeTypedSimple(XML)(M)
end

module XHTML = struct
  module M = XHTML_f.Make(XML)
  module M_01_00 = XHTML_f.Make_01_00(XML)
  module M_01_01 = XHTML_f.Make_01_01(XML)
  module M_01_00_compat = XHTML_f.Make_01_00_compat(XML)
  module M_01_01_compat = XHTML_f.Make_01_01_compat(XML)
  module P = XML_print.MakeTypedSimple(XML)(M)
  module P_01_01 = XML_print.MakeTypedSimple(XML)(M_01_01)
  module P_01_00 = XML_print.MakeTypedSimple(XML)(M_01_00)
  module P_01_01_compat = XML_print.MakeTypedSimple(XML)(M_01_01_compat)
  module P_01_00_compat = XML_print.MakeTypedSimple(XML)(M_01_00_compat)
end

type file_info = Ocsigen_extensions.file_info
