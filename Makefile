.PHONY: all depend push

REPOS=ocaml-dockerfiles opam-dockerfiles opam-archive-dockerfiles

all:
	./dockerfile-ocaml.ml
	./dockerfile-opam.ml
	./dockerfile-archive.ml && (cd opam-archive-dockerfiles && git commit -m sync -a)
	./dockerfile-gen.ml -c all -g -o opam-dev-dockerfiles merlin utop mirage tuareg lwt core

depend:
	opam install -y ocamlscript dockerfile
	for i in $(REPOS); do \
		rm -rf $$i && \
		git clone git://github.com/ocaml/$$i && \
		git -C $$i remote add worigin git@github.com:ocaml/$$i; done
	rm -rf opam-dev-dockerfiles
	git clone git://github.com/avsm/opam-dev-dockerfiles
	git -C opam-dev-dockerfiles remote add worigin git@github.com:avsm/opam-dev-dockerfiles

push-%:
	git -C $*-dockerfiles push worigin --all --force

clean:
	rm -f *.ml.exe
