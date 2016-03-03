.PHONY: all depend sync add-submodules diff clean

all:
	./dockerfile-ocaml.ml
	./dockerfile-opam.ml
	./dockerfile-archive.ml

depend:
	opam install -y ocamlscript dockerfile
	for i in ocaml-dockerfiles opam-dockerfiles opam-archive-dockerfiles; do \
		rm -rf $$i && git clone git://github.com/ocaml/$$i; done

clean:
	rm -f *.ml.exe
