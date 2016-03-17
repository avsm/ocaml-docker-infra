#!/usr/bin/env ocamlscript
Ocaml.packs := ["dockerfile.opam"; "cmdliner"]
--
(* ISC License is at the end of the file. *)

open Dockerfile
open Dockerfile_opam
module DD = Dockerfile_distro

let generate remotes pins dev_pins packages prs odir use_git distros ocaml_versions =
  List.iter (fun (name,url) -> Printf.eprintf "remote : %s,%s\n%!" name url) remotes;
  List.iter (fun (pkg,url) -> Printf.eprintf "pins : %s,%s\n%!" pkg url) pins;
  List.iter (Printf.eprintf "dev-pins : %s\n%!") dev_pins;
  List.iter (Printf.eprintf "package: %s\n%!") packages;
  Printf.eprintf "distros: %s\n%!" (String.concat "," (List.map DD.tag_of_distro distros));
  let npins = List.length pins + (List.length dev_pins) in
  let filter (d,ov,_) = (List.mem ov ocaml_versions) && (List.mem d distros) in
  let matrix =
    DD.map ~filter ~org:"ocaml/opam"
      (fun ~distro ~ocaml_version base ->
        let dfile =
          ((((base @@@
          List.map (fun (name,url) -> run_as_opam "opam remote add %s %s" name url) remotes) @@@
          List.map (fun (p,v) -> run_as_opam "cd /home/opam/opam-repository && git pull %s %s && opam update -u" p v) prs) @@@
          List.map (fun (pkg,url) -> run_as_opam "opam pin add -n %s %s" pkg url) pins) @@@
          List.map (run_as_opam "opam pin add -n %s --dev") dev_pins) @@
          (if npins > 0 then run_as_opam "opam update -u" else empty) @@
          run_as_opam "opam depext -u %s" (String.concat " " packages) @@
          run_as_opam "opam install -y -j 2 -v %s" (String.concat " " packages)
        in
        let tag = DD.opam_tag_of_distro distro ocaml_version in
        (tag, dfile))
  in
  (* If there are unknown compiler versions for which there is no premade tag, base
     them over the latest tag with a compiler switch *)
  let unknown_compilers = List.filter (fun v -> not (List.mem v DD.ocaml_versions)) ocaml_versions in
  let unknown_matrix = List.flatten (List.map (fun unknown_version ->
    DD.map ~filter:(fun (d,ov,_) -> (ov = "4.02.3") && (List.mem d distros))
      (fun ~distro ~ocaml_version base ->
        let dfile =
          (((base @@@
          List.map (fun (name,url) -> run_as_opam "opam remote add %s %s" name url) remotes) @@
          run_as_opam "opam switch %s" unknown_version @@@
          List.map (fun (pkg,url) -> run_as_opam "opam pin add -n %s %s" pkg url) pins) @@@
          List.map (run_as_opam "opam pin add -n %s --dev") dev_pins) @@
          (if npins > 0 then run_as_opam "opam update -u" else empty) @@
          run_as_opam "opam depext -u %s" (String.concat " " packages) @@
          run_as_opam "opam install -y -j 2 -v %s" (String.concat " " packages)
        in
        let tag = DD.opam_tag_of_distro distro unknown_version in
        (tag, dfile))
    ) unknown_compilers)
  in
  let matrix = matrix @ unknown_matrix in
(*
  let ssh_matrix2 =
     DD.map ~filter ~org:"ocaml/opam"
      (fun ~distro ~ocaml_version base ->
        let branch = Printf.sprintf "release_%s" (DD.opam_tag_of_distro distro ocaml_version) in
        let dfile =
          base @@
          run "ssh-keyscan github.com >> /home/opam/.ssh/known_hosts" @@
          run "git clone git@github.com:avsm/mirage-bulk-logs /home/opam/logs" @@
          workdir "/home/opam/logs" @@
          run "git checkout -b %s" branch @@
          run "mkdir -p core" @@
          workdir "/home/opam/logs/core" @@
          run "opam depext %s > depext_build_log 2>&1" (String.concat " " packages) @@
          run "opam install -j 2 -y -v %s > build_log 2>&1" (String.concat " " packages) @@
          run "git add depext_build_log build_log" @@
          run "git commit -m \"build %s on %s\"" (String.concat " " packages) branch @@
          run "git push --force git@github.com:avsm/mirage-bulk-logs %s" branch
        in
        let tag = tag_prefix ^ (DD.opam_tag_of_distro distro ocaml_version) in
        (tag, dfile))
  in
*)
  match use_git with
  | true -> Dockerfile_distro.generate_dockerfiles_in_git_branches odir matrix
  | false -> Dockerfile_distro.generate_dockerfiles odir matrix

open Cmdliner

let remotes =
  let doc = "OPAM remote to add to the generated Dockerfile (format: name,url)" in
  Arg.(value & opt_all (pair string string) [] & info ["r";"remote"] ~docv:"REMOTES" ~doc)

let pr =
  let doc = "OPAM repository branch to merge against current OPAM repository (format: url,branch)" in
  Arg.(value & opt_all (pair string string) [] & info ["b";"branch"] ~docv:"OPAM_REPO_BRANCH" ~doc)

let pins =
  let doc = "OPAM package pin to add to the generated Dockerfile (format: package,url)" in
  Arg.(value & opt_all (pair string string) [] & info ["p";"pin"] ~docv:"PIN" ~doc)

let dev_pins =
  let doc = "OPAM package to pin to the development version" in
  Arg.(value & opt_all string [] & info ["dev-pin"] ~docv:"DEV-PIN" ~doc)

let odir =
  let doc = "Output directory to place the generated Dockerfile into.  If not specified then all the Dockerfiles will be suffixed with their release in the filename." in
  Arg.(value & opt string "." & info ["o";"output-dir"] ~docv:"OUTPUT_DIR" ~doc)

let use_git =
  let doc = "Output as Git branches instead of subdirectories. This requires that the output directory be an already initialised $(git) repository.  The command will destructively create branches with the prefix $(i,release-) that contain a Dockerfile.  These can be built on the Docker Hub using the wildcard branch building facility." in
  Arg.(value & flag (info ["g";"git"] ~docv:"OUTPUT_GIT_BRANCH" ~doc))

let packages =
  let doc = "OPAM packages to install" in
  Arg.(non_empty & pos_all string [] & info [] ~docv:"PACKAGES" ~doc)

let ocaml_versions =
  let versions =
    let parse s =
      match Str.(split (regexp_string ",") s) with
      | [] -> `Error "empty string for OCaml versions"
      | vs -> `Ok (List.flatten (
          List.map (function
            |"stable" -> ["4.02.3"]
            |"dev" -> ["4.03.0+trunk"]
            |"all" -> ["4.00.1";"4.01.0";"4.02.3";"4.03.0+trunk"]
            |v -> [v]) vs))
     in
     let print ppf vs =
       Format.fprintf ppf "%s" (String.concat "," vs) in
     parse, print
  in
  let doc = "Comma-separated list of compiler switches to use, such as 4.02.3. Can use $(i,stable), $(i,dev) and $(i,all) as aliases to the stable compiler, the development branch and all supported compilers. If the compiler is not recognised as one of the prebuilt images, then a local switch will be performed." in
  Arg.(value & opt versions ["4.02.3";"4.03.0+beta1"] & info ["c";"compilers"] ~docv:"COMPILERS" ~doc)

let distros =
  let distros =
   let parse s =
      let rec fn d acc =
        match d with
        | [] -> `Ok acc
        | hd::tl -> begin
            match hd with
            |"all" -> `Ok DD.distros
            |hd -> begin
              match DD.distro_of_tag hd with
              | None -> raise (Failure ("unknown distro " ^ hd))
              | Some d -> fn tl (d::acc)
            end
        end
     in try fn (Str.(split (regexp_string ",") s)) [] with Failure e -> `Error e
   in
   let print ppf l =
     let s =
       if (List.sort compare l = (List.sort compare DD.distros)) then "all" else 
         String.concat "," (List.map DD.tag_of_distro l)
     in
     Format.fprintf ppf "%s" s in
   parse, print
  in
  let doc = "Comma-separated list of distributions to generate, such as debian-7,alpine-3.3. Can use $(i,all) as an alias for all the supported distributions." in
  Arg.(value & opt distros DD.distros & info ["d";"distros"] ~docv:"DISTROS" ~doc)

let cmd =
  let doc = "generate Dockerfiles for an OCaml/OPAM project" in
  let man = [
    `S "DESCRIPTION";
    `S "BUGS";
    `P "Report them to via e-mail to <opam-devel@lists.ocaml.org>, or
        on the issue tracker at <https://github.com/avsm//issues>";
    `S "SEE ALSO";
    `P "$(b,opam)(1)" ]
  in
  Term.(pure generate $ remotes $ pins $ dev_pins $ packages $ pr $ odir $ use_git $ distros $ ocaml_versions),
  Term.info "opam-dockerfile-gen" ~version:"1.0.0" ~doc ~man

let () =
  match Term.eval cmd
  with `Error _ -> exit 1 | _ -> exit 0

(*
 * Copyright (c) 2016 Anil Madhavapeddy <anil@recoil.org>
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
 *
 *)
