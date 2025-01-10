version = 0.22.6

init:
	mkdir -p build
	curl https://github.com/tree-sitter/tree-sitter/archive/refs/tags/v${version}.tar.gz -Lo build/src.tar.gz
	tar -xf build/src.tar.gz -C build
	mkdir -p src/tree-sitter
	cp -r build/tree-sitter-${version}/lib/src/* src/tree-sitter/
	cp -r build/tree-sitter-${version}/lib/include/* src/tree-sitter/
