#!/usr/bin/env ocamlscript
Ocaml.packs := ["dockerfile-opam"]
--
(* Generate an OPAM archive server that serves content via
   an HTTP server. ISC License is at the end of the file. *)

open Dockerfile
open Dockerfile_opam

let generate ~opam_version ~output_dir =
  let opam_archive =
    header "ocaml/opam" "latest" @@
    run_as_opam "cd /home/opam/opam-repository && git pull origin master" @@
    run_as_opam "opam update -u -y" @@
    run_as_opam "OPAMYES=1 OPAMJOBS=2 OPAMVERBOSE=1 opam depext -u -i lwt ssl tls cohttp" @@
    label ["built_on", (string_of_float (Unix.gettimeofday ()))] @@
    run_as_opam "cd /home/opam/opam-repository && opam-admin make" @@
    workdir "/home/opam/opam-repository" @@
    expose_port 8081 @@
    cmd "opam config exec -- cohttp-server-lwt -p 8081"
  in
  Dockerfile_distro.generate_dockerfile output_dir opam_archive

let _ =
  Dockerfile_opam_cmdliner.cmd
    ~name:"dockerfile-archive"
    ~version:"1.1.0"
    ~summary:"the OPAM package archive"
    ~manual:"installs the OPAM package archive and an HTTP server using
             $(i,cohttp) to serve the contents.  This is useful when deployed
             as a linked Docker container for bulk builds."
    ~default_dir:"opam-archive-dockerfiles"
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
