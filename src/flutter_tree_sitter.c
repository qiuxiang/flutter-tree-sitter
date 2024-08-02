#include "tree-sitter/lib.c"

TSTreeCursor *tree_cursor_new(TSNode node) {
  TSTreeCursor *self = ts_malloc(sizeof(TSTreeCursor));
  ts_tree_cursor_init((TreeCursor *)self, node);
  return self;
}
