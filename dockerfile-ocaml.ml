#!/usr/bin/env ocamlscript
Ocaml.packs := ["dockerfile-opam"]
--
(* Generate OCaml base images with the default system installation of OCaml
   for that distribution.  ISC License is at the end of the file. *)

open Dockerfile

let generate ~opam_version ~output_dir =
  let maintainer = "Anil Madhavapeddy <anil@recoil.org>" in
  let apt_base base tag  = 
    Dockerfile_opam.header ~maintainer base tag @@
    Dockerfile_linux.Apt.dev_packages () @@
    Dockerfile_linux.Apt.install_system_ocaml
  in
  let rpm_base ?(ocaml=true) base tag =
    Dockerfile_opam.header ~maintainer base tag @@
    Dockerfile_linux.RPM.update @@
    Dockerfile_linux.RPM.dev_packages () @@
    (if ocaml then Dockerfile_linux.RPM.install_system_ocaml else empty)
  in
  let apk_base ?(add_custom_apk=false) base tag = 
    Dockerfile_opam.header ~maintainer base tag @@
    Dockerfile_linux.Apk.dev_packages () @@
    Dockerfile_linux.Apk.install_system_ocaml ~add_custom_apk tag
  in
  let zypper_base base tag =
    Dockerfile_opam.header ~maintainer base tag @@
    Dockerfile_linux.Zypper.dev_packages () @@
    Dockerfile_linux.Zypper.install_system_ocaml
  in
  Dockerfile_distro.generate_dockerfiles_in_git_branches output_dir [
     "ubuntu-12.04", apt_base "ubuntu" "precise";
     "ubuntu-14.04", apt_base "ubuntu" "trusty";
     "ubuntu-15.04", apt_base "ubuntu" "vivid";
     "ubuntu-15.10", apt_base "ubuntu" "wily";
     "ubuntu-16.04", apt_base "ubuntu" "xenial";
     "ubuntu-16.10", apt_base "ubuntu" "yakkety";
     "ubuntu-17.04", apt_base "ubuntu" "zesty";
     "ubuntu", apt_base "ubuntu" "xenial"; (* latest stable ubuntu *)
     "debian-9", apt_base "debian" "stretch"; (* 9 isnt tagged on Hub yet *)
     "debian-8", apt_base "debian" "8";
     "debian-7", apt_base "debian" "7";
     "raspbian-8", apt_base "resin/rpi-raspbian" "jessie";
     "debian", apt_base "debian" "stable";
     "debian-stable", apt_base "debian" "stable";
     "master", apt_base "debian" "stable";
     "debian-testing", apt_base "debian" "testing";
     "debian-unstable", apt_base "debian" "unstable";
     "centos-7", rpm_base "centos" "centos7";
     "centos-6", rpm_base "centos" "centos6";
     "fedora-21", rpm_base "fedora" "21";
     "fedora-22", rpm_base "fedora" "22";
     "fedora-23", rpm_base "fedora" "23";
     "fedora-24", rpm_base "fedora" "24";
     "fedora-25", rpm_base "fedora" "25";
     "fedora", rpm_base "fedora" "24"; (* latest fedora *)
     "oraclelinux-7", rpm_base ~ocaml:false "oraclelinux" "7";
     "oraclelinux", rpm_base ~ocaml:false "oraclelinux" "7"; (* latest oraclelinux *)
     "alpine-3.5", apk_base "alpine" "3.5";
     "alpine-3.4", apk_base ~add_custom_apk:true "alpine" "3.4";
     "alpine-3.3", apk_base ~add_custom_apk:true "alpine" "3.3";
     "alpine-3", apk_base "alpine" "3.5";
     "alpine", apk_base "alpine" "3.5"; (* latest alpine *)
     "opensuse-42.1", zypper_base "opensuse" "42.1";
     "opensuse-42.2", zypper_base "opensuse" "42.2";
     "opensuse", zypper_base "opensuse" "42.2"; (* latest opensuse *)
  ]

let _ =
  Dockerfile_opam_cmdliner.cmd
    ~name:"dockerfile-ocaml"
    ~version:"1.2.0"
    ~summary:"the OCaml compiler"
    ~manual:"installs the OCaml byte and native code compiler and the
             Camlp4 preprocessor.  The version of OCaml that is installed
             is the default one available for that particular distribution.
             To customise the compiler version, use the $(b,opam-dockerfile-opam)
             command that installs OPAM and a custom compiler switch instead."
    ~default_dir:"ocaml-dockerfiles"
    ~generate
  |> Dockerfile_opam_cmdliner.run

(*
 * Copyright (c) 2015 Anil Madhavapeddy <anil@recoil.org>
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

