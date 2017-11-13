#!/bin/sh 

if [ ! -d ocaml-dockerfile ]; then
  git clone -b v4dev git://github.com/avsm/ocaml-dockerfile
else
  git -C ocaml-dockerfile pull
fi

if [ ! -d obi ]; then
  git clone git://github.com/avsm/obi
else
  git -C obi pull
fi

jbuilder build
jbuilder uninstall
jbuilder install

