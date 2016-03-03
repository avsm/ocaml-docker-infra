OCaml and OPAM Docker scripts
-----------------------------

This repository uses the [OCaml Dockerfile](https://avsm.github.io/ocaml-dockerfile)
library to generate a series of Dockerfiles for various combinations of
[OCaml](http://ocaml.org) and the [OPAM](https://opam.ocaml.org) package manager.
There are a set of small scripts that output all the combinations and are easy
to modify, extend or duplicate for your own use.

    opam install docker-infra

They are all executed directly as a shell script by using the
[OCamlScript](http://mjambon.com/ocamlscript.html) engine.  The installed
scripts are:

- `dockerfile-ocaml`: installs base OCaml packages
- `dockerfile-opam`: installs OPAM and OCaml switches
- `dockerfile-archive`: builds an OPAM source package archive and HTTP server
- `dockerfile-gen`: builds a dev environment with installed OPAM packages

## Docker Repostories

The generated Dockerfiles are split into a sequence of containers that build on
each other, making it easy to pick the ones you need for your own purposes.
The default behaviour is to output the files into independent Git repositories:

- [docker-ocaml-build](https://github.com/ocaml/ocaml-dockerfiles) is the base
  OCaml compiler added on top of various Linux distributions.
- [docker-opam-build](https://github.com/ocaml/opam-dockerfiles) layers the
  OPAM package manager over this image, and initialises it to the central
  OPAM remote.
  The [opam-depext](https://github.com/ocaml/opam-depext) plugin is
  also globally installed, so external library dependencies can also be automatically
  installed in all of the OS variants with a single command (`opam depext -ui ssl`).

There are automated builds triggered from pushes to these repository from the
[Docker Hub](http://hub.docker.com):

- `docker pull ocaml/ocaml` *[(link)](registry.hub.docker.com/u/ocaml/ocaml)*
- `docker pull ocaml/opam` *[(link)](registry.hub.docker.com/u/ocaml/opam)*
