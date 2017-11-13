#!/bin/sh

./base.sh
. ./config.sh
eval `opam config env`

#obi-docker phase1 -vv &

ssh ${HOST_ARM64} git -C ocaml-docker-infra pull
ssh ${HOST_ARM64} sh -c obi-docker phase1 -vv

