#!/usr/bin/env ocamlscript
Ocaml.packs := ["dockerfile.opam"; "cmdliner"]
--
(* Generate base images for Jane Street Core.
   ISC License is at the end of the file. *)

open Dockerfile
open Dockerfile_opam
module DD = Dockerfile_distro

let generate remotes pins dev_pins packages odir use_git ocaml_versions =
  let tag_prefix = "release-" in
  List.iter (fun (name,url) -> Printf.eprintf "remote : %s,%s\n%!" name url) remotes;
  List.iter (fun (pkg,url) -> Printf.eprintf "pins : %s,%s\n%!" pkg url) pins;
  List.iter (Printf.eprintf "dev-pins : %s\n%!") dev_pins;
  List.iter (Printf.eprintf "package: %s\n%!") packages;
  let npins = List.length pins + (List.length dev_pins) in
  let filter (distro,ov,_) =
    match ocaml_versions with
    |`Latest -> ov = "4.02.3"
    |`Dev -> ov = "4.02.3" || ov = "4.03.0+trunk"
    |`All -> true in
  let matrix =
    DD.map ~filter ~org:"ocaml/opam"
      (fun ~distro ~ocaml_version base ->
        let dfile =
          (((base @@@
          List.map (fun (pkg,url) -> run_as_opam "opam pin add -n %s %s" pkg url) pins) @@@
          List.map (fun (name,url) -> run_as_opam "opam remote add %s %s" name url) remotes) @@@
          List.map (run_as_opam "opam pin add -n %s --dev") dev_pins) @@
          (if npins > 0 then run_as_opam "opam update -u" else empty) @@
          run_as_opam "opam depext -u %s" (String.concat " " packages) @@
          run_as_opam "opam install -y -j 2 -v %s" (String.concat " " packages)
        in
        let tag = tag_prefix ^ (DD.opam_tag_of_distro distro ocaml_version) in
        (tag, dfile))
  in
(*
  let ssh_matrix2 =
     DD.map ~filter ~org:"ocaml/opam"
      (fun ~distro ~ocaml_version base ->
        let branch = Printf.sprintf "release_%s" (DD.opam_tag_of_distro distro ocaml_version) in
        let dfile =
          base @@
          run "mkdir /home/opam/.ssh" @@
          add ~src:[".ssh-logs/mirage-bulk-logs_id_rsa"] ~dst:"/home/opam/.ssh/id_rsa" @@
          add ~src:[".ssh-logs/mirage-bulk-logs_id_rsa.pub"] ~dst:"/home/opam/.ssh/id_rsa.pub" @@
          run "sudo chown -R opam /home/opam/.ssh/*" @@
          run "chmod -R 600 /home/opam/.ssh/*" @@
          run "touch /home/opam/.ssh/known_hosts" @@
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

let pins =
  let doc = "OPAM package pin to add to the generated Dockerfile (format: package,url)" in
  Arg.(value & opt_all (pair string string) [] & info ["p";"pin"] ~docv:"PIN" ~doc)

let dev_pins =
  let doc = "OPAM package to pin to the development version" in
  Arg.(value & opt_all string [] & info ["dev-pin"] ~docv:"DEV-PIN" ~doc)

let odir =
  let doc = "Output directory to place the generated Dockerfile into." in
  Arg.(value & opt string "." & info ["o";"output-dir"] ~docv:"OUTPUT_DIR" ~doc)

let use_git =
  let doc = "Output as Git branches instead of subdirectories. This requires that the output directory be an already initialised $(git) repository.  The command will destructively create branches with the prefix $(i,release-) that contain a Dockerfile.  These can be built on the Docker Hub using the wildcard branch building facility." in
  Arg.(value & flag (info ["g";"git"] ~docv:"OUTPUT_GIT_BRANCH" ~doc))

let packages =
  let doc = "OPAM packages to install" in
  Arg.(non_empty & pos_all string [] & info [] ~docv:"PACKAGES" ~doc)

let ocaml_versions = 
  Arg.(value & vflag `Latest
    [ `All, info ["ocaml-all"] ~doc:"Support all OCaml versions";
      `Latest, info ["ocaml-latest"] ~doc:"Support the latest stable and previous release (the default)";
      `Dev, info ["ocaml-dev"] ~doc:"Support the latest stable and development versions of OCaml"
    ])

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
  Term.(pure generate $ remotes $ pins $ dev_pins $ packages $ odir $ use_git $ ocaml_versions ),
  Term.info "opam-dockerfile" ~version:"1.0.0" ~doc ~man

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
