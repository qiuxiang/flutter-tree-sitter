import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'bindings.g.dart';
import 'lib.dart';

class TreeSitterTree {
  final Pointer<TSTree> self;

  TreeSitterTree(this.self);

  /// Create a shallow copy of the syntax tree. This is very fast.
  ///
  /// You need to copy a syntax tree in order to use it on more than one thread at
  /// a time, as syntax trees are not thread safe.
  TreeSitterTree copy() {
    return TreeSitterTree(treeSitter.ts_tree_copy(self));
  }

  /// Get the root node of the syntax tree.
  TSNode get rootNode {
    return treeSitter.ts_tree_root_node(self);
  }

  /// Get the root node of the syntax tree, but with its position
  /// shifted forward by the given offset.
  TSNode rootNodeWithOffset(int offsetBytes, TSPoint offsetExtent) {
    return treeSitter.ts_tree_root_node_with_offset(self, offsetBytes, offsetExtent);
  }

  /// Get the language that was used to parse the syntax tree.
  Pointer<TSLanguage> get language {
    return treeSitter.ts_tree_language(self);
  }

  /// Get the array of included ranges that was used to parse the syntax tree.
  ///
  /// The returned pointer must be freed by the caller.
  List<TSRange> get includedRanges {
    final lengthPtr = malloc<Uint32>();
    final rangesPtr = treeSitter.ts_tree_included_ranges(self, lengthPtr);
    final length = lengthPtr.value;
    malloc.free(lengthPtr);
    
    if (rangesPtr == nullptr || length == 0) {
      return [];
    }
    
    final ranges = List.generate(length, (i) => rangesPtr[i]);
    malloc.free(rangesPtr);
    return ranges;
  }

  /// Edit the syntax tree to keep it in sync with source code that has been
  /// edited.
  ///
  /// You must describe the edit both in terms of byte offsets and in terms of
  /// (row, column) coordinates.
  void edit(TSInputEdit edit) {
    final editPtr = malloc<TSInputEdit>();
    editPtr.ref = edit;
    treeSitter.ts_tree_edit(self, editPtr);
    malloc.free(editPtr);
  }

  /// Compare an old edited syntax tree to a new syntax tree representing the same
  /// document, returning an array of ranges whose syntactic structure has changed.
  ///
  /// For this to work correctly, the old syntax tree must have been edited such
  /// that its ranges match up to the new tree. Generally, you'll want to call
  /// this function right after calling one of the [TreeSitterParser.parse] functions.
  /// You need to pass the old tree that was passed to parse, as well as the new
  /// tree that was returned from that function.
  ///
  /// The returned ranges indicate areas where the hierarchical structure of syntax
  /// nodes (from root to leaf) has changed between the old and new trees. Characters
  /// outside these ranges have identical ancestor nodes in both trees.
  ///
  /// Note that the returned ranges may be slightly larger than the exact changed areas,
  /// but Tree-sitter attempts to make them as small as possible.
  ///
  /// The returned array is allocated using `malloc` and the caller is responsible
  /// for freeing it using `free`. The length of the array will be written to the
  /// given `length` pointer.
  List<TSRange> getChangedRanges(TreeSitterTree newTree) {
    final lengthPtr = malloc<Uint32>();
    final rangesPtr = treeSitter.ts_tree_get_changed_ranges(self, newTree.self, lengthPtr);
    final length = lengthPtr.value;
    malloc.free(lengthPtr);
    
    if (rangesPtr == nullptr || length == 0) {
      return [];
    }
    
    final ranges = List.generate(length, (i) => rangesPtr[i]);
    malloc.free(rangesPtr);
    return ranges;
  }

  /// Write a DOT graph describing the syntax tree to the given file.
  void printDotGraph(int fileDescriptor) {
    treeSitter.ts_tree_print_dot_graph(self, fileDescriptor);
  }

  /// Delete the syntax tree, freeing all of the memory that it used.
  void delete() {
    treeSitter.ts_tree_delete(self);
  }
}
