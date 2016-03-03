.PHONY: all depend sync add-submodules diff clean

all:
	./dockerfile-ocaml.ml
	./dockerfile-opam.ml
	./dockerfile-archive.ml

depend:
	opam install -y ocamlscript dockerfile

clean:
	rm -f *.ml.exe
