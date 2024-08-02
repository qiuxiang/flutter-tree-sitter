version = 0.22.6

init:
	mkdir -p build
	curl https://github.com/tree-sitter/tree-sitter/archive/refs/tags/v${version}.tar.gz -Lo build/src.tar.gz
	tar -xf build/src.tar.gz -C build
	mv build/tree-sitter-${version} build/src
	mv build/src/lib/src src/tree-sitter
	mv build/src/lib/include src/
