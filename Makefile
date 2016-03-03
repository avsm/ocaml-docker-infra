.PHONY: all depend push

REPOS=ocaml-dockerfiles opam-dockerfiles opam-archive-dockerfiles

all:
	./dockerfile-ocaml.ml
	./dockerfile-opam.ml
	./dockerfile-archive.ml

depend:
	opam install -y ocamlscript dockerfile
	for i in $(REPO); do \
		rm -rf $$i && \
		git clone git://github.com/ocaml/$$i && \
		git -C $$i remote add worigin git@github.com:ocaml/$$i; done
push-%:
	git -C $*-dockerfiles push worigin --all --force

clean:
	rm -f *.ml.exe
