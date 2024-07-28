# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(tree_sitter_library VERSION 0.0.1 LANGUAGES C)

include_directories("include")
add_library(tree_sitter SHARED
  "tree_sitter.c"
)

target_compile_definitions(tree_sitter PUBLIC DART_SHARED_LIB)
