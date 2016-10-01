#!/usr/bin/env ocamlscript
Ocaml.packs := ["dockerfile.opam"; "dockerfile.opam-cmdliner"]
--
(* Generate OPAM base images with particular revisions of OCaml and OPAM.
   ISC License is at the end of the file. *)

let pin = None
let extra = Dockerfile_distro.slow_distros
let extra_ocaml_versions = Dockerfile_distro.dev_ocaml_versions
let matrix ~opam_version () = Dockerfile_distro.dockerfile_matrix ~opam_version ~extra ~extra_ocaml_versions ?pin ()
let latest_matrix ~opam_version () = Dockerfile_distro.latest_dockerfile_matrix ~opam_version ~extra ?pin ()

(* Generate Markdown list of tags for the README master *)
let master_markdown_index ~opam_version =
  let open Dockerfile_distro in
  let open Printf in
  let system = "&#127362;" in
  let default = "&#127347;" in
  let gen_sws distro ocaml_version =
    match builtin_ocaml_of_distro distro with
    | None -> sprintf "%s %s" ocaml_version default
    | Some v when v = ocaml_version -> sprintf "%s %s%s" ocaml_version system default
    | Some v -> sprintf "%s %s, %s %s" v system ocaml_version default
  in
  [sprintf "This repository contains a set of [Docker](http://docker.com) container definitions for various combination of [OCaml](https://ocaml.org) and the [OPAM](https://opam.ocaml.org) package manager.  The containers all come preinstalled with a working compiler and an OPAM environment.  Using it as simple as:\n\n```\ndocker pull ocaml/opam\ndocker run -ti ocaml/opam bash\n```\n\n...to get a working development environment.  You can grab a specific distribution and test out external dependencies as well:\n```\ndocker run ocaml/opam:ubuntu-14.04_ocaml-4.02.3 opam depext -i cohttp lwt ssl\n```\n";
   sprintf "Distributions\n==========\n";
   sprintf "The default `latest` tag points to the following distribution:\n";
   sprintf "Distribution | Available Switches | Command";
   sprintf "------------ | ------------------ | -------";
   sprintf "%s | %s | `docker pull ocaml/opam`\n" (human_readable_short_string_of_distro master_distro) (gen_sws master_distro latest_ocaml_version);
   sprintf "The latest stable distributions are summarised below.  The default OCaml version available in the container is marked with a %s symbol, and a system installation of OCaml (as opposed to a locally compiled switch) is marked with a %s symbol.\n" default system;
   sprintf "Distribution | Available Switches | Command";
   sprintf "------------ | ------------------ | -------" ] @
  List.map (fun (distro, dfile) ->
     let name = human_readable_short_string_of_distro distro in
     let tag = latest_tag_of_distro distro in
     let sws = gen_sws distro latest_ocaml_version in
     sprintf "%s | %s | `docker pull ocaml/opam:%s`" name sws tag;
  ) (latest_matrix ~opam_version ()) @
  [sprintf "\nThere are also individual containers available for each combination
   of an OS distribution and an OCaml revision. These should be useful for
   testing and continuous integration, since they will remain pinned to these
   versions for as long as the upstream distribution is supported.  Note that
   older releases may have security issues if upstream stops maintaining them.\n";
   "Distro | Compiler | Command";
   "------ | -------- | -------";
  ] @
  List.map (fun (distro, ocaml_version, dfile) ->
    let tag = opam_tag_of_distro distro ocaml_version in
    let name = human_readable_string_of_distro distro in
    let sws =
      match builtin_ocaml_of_distro distro with
      | None -> sprintf "%s %s" ocaml_version default
      | Some v when v = ocaml_version -> sprintf "%s %s%s" ocaml_version system default
      | Some v -> sprintf "%s %s" ocaml_version default
    in
    sprintf "%s | %s | `docker pull ocaml/opam:%s`" name sws tag
  ) (matrix ~opam_version ()) @
  ["\n\nUsing the Containers\n================\n";
  "Each container comes with an initialised OPAM repository pointing to the central repository. The default user in the container is called `opam`, and `sudo` is configured to allow password-less access to `root`.\n";
  "To build an environment for the [Jane Street Core](https://realworldocaml.org/) library on the latest stable OCaml, a simple Dockerfile looks like this:\n";
  "```\nFROM ocaml/opam\nopam depext -i core\n```";
  "You can build and use this image locally for development by saving the Dockerfile and:\n";
  "```\ndocker build -t ocaml-core .\ndocker run -ti ocaml-core bash\n```\n";
  "You can also use the Docker [volume sharing](https://docs.docker.com/engine/reference/builder/#volume) to map in source code from your host into the container to persist the results of your build.  You can also construct more specific Dockerfiles that use the full range of OPAM commands for a custom development environment.  For example, to build the [MirageOS](https://mirage.io) bleeding edge OCaml environment, this Dockerfile will add in a custom remote:\n";
  "```\nFROM ocaml/opam:ubuntu-15.10_ocaml-4.02.3\nopam remote add dev git://github.com/mirage/mirage-dev\nopam depext -i mirage\n```\n";
  "\n\nContributing\n==========\n\nTo discuss these containers, please e-mail Anil Madhavapeddy <anil@recoil.org> or the OPAM development list at <opam-devel@lists.ocaml.org>. Contributions of Dockerfiles for additional OS distributions are most welcome! The files here are all autogenerated from the [ocaml-docker-scripts](https://github.com/avsm/ocaml-docker-scripts) repository, so please do not submit any PRs directly to this location. The containers are built and hosted on the Docker Hub [ocaml organisation](https://hub.docker.com/u/ocaml)."]
  |> String.concat "\n"

 (* Generate a git branch per Dockerfile combination *)
let generate ~opam_version ~output_dir =
  let open Dockerfile_distro in
  [("master", to_dockerfile ?pin ~opam_version ~ocaml_version:latest_ocaml_version ~distro:master_distro ())]
    |> generate_dockerfiles_in_git_branches ~readme:(master_markdown_index ~opam_version) ~crunch:true output_dir;
  List.map (fun (distro,ocamlv,dfile) ->
    (opam_tag_of_distro distro ocamlv), dfile) (matrix ~opam_version ())
    |> generate_dockerfiles_in_git_branches ~crunch:true output_dir;
  List.map (fun (distro,dfile) ->
    (latest_tag_of_distro distro), dfile) (latest_matrix ~opam_version ())
    |> generate_dockerfiles_in_git_branches ~crunch:true output_dir
 
let _ =
  Dockerfile_opam_cmdliner.cmd
    ~name:"dockerfile-opam"
    ~version:"1.1.0"
    ~summary:"the OPAM source package manager"
    ~manual:"installs the OPAM source-based package manager and a combination
             of local compiler switches for various Linux distributions.  It
             depends on the base OCaml containers that are generated via the
             $(b,opam-dockerfile-ocaml) command."
    ~default_dir:"opam-dockerfiles"
    ~generate
  |> Dockerfile_opam_cmdliner.run

(*
 * Copyright (c) 2015-2016 Anil Madhavapeddy <anil@recoil.org>
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
