.PHONY: all depend push

REPOS=ocaml-dockerfiles opam-dockerfiles opam-archive-dockerfiles opam-dev-dockerfiles

all:
	./dockerfile-ocaml.ml
	./dockerfile-opam.ml -o opam-dockerfiles --opam-version=1.2
	./dockerfile-opam.ml -o opam-dev-dockerfiles --opam-version=master
	./dockerfile-archive.ml && (cd opam-archive-dockerfiles && git commit -m sync -a)
	#./dockerfile-gen.ml -c 4.02.3,4.03.0 -g -o opam-dev-dockerfiles conf-vim conf-emacs merlin annot utop tuareg lwt jenga

depend:
	opam install -y ocamlscript dockerfile
	for i in $(REPOS); do \
		rm -rf $$i && \
		git clone git://github.com/ocaml/$$i && \
		git -C $$i remote add worigin git@github.com:ocaml/$$i; done

push-%:
	git -C $*-dockerfiles push worigin --all --force

clean:
	rm -f *.ml.exe
