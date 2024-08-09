import 'dart:ffi';

import 'bindings.g.dart';
import 'lib.dart';

class TreeSitterTree {
  final Pointer<TSTree> self;

  TreeSitterTree(this.self);

  /// Get the root node of the syntax tree.
  TSNode get rootNode {
    return treeSitter.ts_tree_root_node(self);
  }

  /// Release memory.
  void delete() {
    treeSitter.ts_tree_delete(self);
  }
}
