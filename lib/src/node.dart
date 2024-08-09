import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'bindings.g.dart';
import 'lib.dart';
import 'utils.dart';

extension TSNodeExtension on TSNode {
  TSNode? get _nullable => _isNull ? null : this;
  bool get _isNull => treeSitter.ts_node_is_null(this);

  /// Get the node's type as a null-terminated string.
  String get type => treeSitter.ts_node_type(this).toDartString();

  /// Get the node's type as it appears in the grammar ignoring aliases as a
  /// null-terminated string.
  String get grammaryType =>
      treeSitter.ts_node_grammar_type(this).toDartString();

  /// Check if the node is *named*. Named nodes correspond to named rules in the
  /// grammar, whereas *anonymous* nodes correspond to string literals in the
  /// grammar.
  bool get isNamed => treeSitter.ts_node_is_named(this);

  /// Check if the node is *missing*. Missing nodes are inserted by the parser in
  /// order to recover from certain kinds of syntax errors.
  bool get isMissing => treeSitter.ts_node_is_missing(this);

  /// Check if the node is *extra*. Extra nodes represent things like comments,
  /// which are not required the grammar, but can appear anywhere.
  bool get isExtra => treeSitter.ts_node_is_extra(this);

  /// Check if the node has been edited.
  bool get hasChanges => treeSitter.ts_node_has_changes(this);

  /// Check if the node is a syntax error or contains any syntax errors.
  bool get hasError => treeSitter.ts_node_has_error(this);

  /// Check if the node is a syntax error.
  bool get isError => treeSitter.ts_node_is_error(this);

  /// Get this node's parse state.
  int get parseState => treeSitter.ts_node_parse_state(this);

  /// Get the parse state after this node.
  int get nextParseState => treeSitter.ts_node_next_parse_state(this);

  /// Get the node's start byte.
  int get startByte => treeSitter.ts_node_start_byte(this);

  /// Get the node's end byte.
  int get endByte => treeSitter.ts_node_end_byte(this);

  /// Get the node's start position in terms of rows and columns.
  TSPoint get startPoint => treeSitter.ts_node_start_point(this);

  /// Get the node's end position in terms of rows and columns.
  TSPoint get endPoint => treeSitter.ts_node_end_point(this);

  /// Get the node's immediate parent.
  /// Prefer [childContainingDescendant] for
  /// iterating over the node's ancestors.
  TSNode? get parent => treeSitter.ts_node_parent(this)._nullable;

  /// Get the node's child that contains `descendant`.
  TSNode? childContainingDescendant(TSNode descendant) => treeSitter
      .ts_node_child_containing_descendant(this, descendant)
      ._nullable;

  /// Get the node's children
  List<TSNode> get children {
    return List.generate(treeSitter.ts_node_child_count(this), (i) {
      return treeSitter.ts_node_child(this, i);
    });
  }

  /// Get the node's *named* children
  List<TSNode> get namedChildren {
    return List.generate(treeSitter.ts_node_named_child_count(this), (i) {
      return treeSitter.ts_node_named_child(this, i);
    });
  }

  /// Get the node's number of children.
  int get childCount => treeSitter.ts_node_child_count(this);

  /// Get the node's number of *named* children.
  ///
  /// See also [isNamed].
  int get namedChildCount => treeSitter.ts_node_named_child_count(this);

  /// Get the node's next sibling.
  TSNode? get nextSibling => treeSitter.ts_node_next_sibling(this)._nullable;

  /// Get the node's next *named* sibling.
  TSNode? get nextNamedSibling =>
      treeSitter.ts_node_next_named_sibling(this)._nullable;

  /// Get the node's previous sibling.
  TSNode? get previousSibling =>
      treeSitter.ts_node_prev_sibling(this)._nullable;

  /// Get the node's previous *named* sibling.
  TSNode? get previousNamedSibling =>
      treeSitter.ts_node_prev_named_sibling(this)._nullable;

  /// Get the node's number of descendants, including one for the node itself.
  int get descendantCount => treeSitter.ts_node_descendant_count(this);

  /// Get the node's child at the given index, where zero represents the first
  /// child.
  TSNode? child(int index) => treeSitter.ts_node_child(this, index)._nullable;

  /// Get the node's *named* child at the given index.
  ///
  /// See also [isNamed].
  TSNode? namedChild(int index) =>
      treeSitter.ts_node_named_child(this, index)._nullable;

  /// Get the node's child with the given field name.
  TSNode? childForFieldName(String name) {
    final buffer = name.toNativeUtf8();
    final node = treeSitter.ts_node_child_by_field_name(
        this, buffer.cast(), name.length);
    malloc.free(buffer);
    return node._nullable;
  }

  /// Get the node's child with the given numerical field id.
  ///
  /// You can convert a field name to an id using the
  /// [TreeSitter.ts_language_field_id_for_name] function.
  TSNode? childForFieldId(int fieldId) =>
      treeSitter.ts_node_child_by_field_id(this, fieldId)._nullable;

  /// Get the node's field name for node's child at the given index, where
  /// zero represents the first child. Returns NULL, if no field is found.
  String? fieldNameForChild(int index) {
    final pointer = treeSitter.ts_node_field_name_for_child(this, index);
    return pointer == nullptr ? null : pointer.toDartString();
  }

  /// Get the smallest node within this node that spans the given range of bytes
  /// or (row, column) positions.
  TSNode? descendantForRange(int start, int end) {
    return treeSitter
        .ts_node_descendant_for_byte_range(this, start, end)
        ._nullable;
  }

  /// Get the smallest named node within this node that spans the given range of
  /// bytes or (row, column) positions.
  TSNode? namedDescendantForRange(int start, int end) {
    return treeSitter
        .ts_node_named_descendant_for_byte_range(this, start, end)
        ._nullable;
  }

  TSNode? descendantForPointRange(TSPoint start, TSPoint end) {
    return treeSitter
        .ts_node_descendant_for_point_range(this, start, end)
        ._nullable;
  }

  TSNode? namedDescendantForPointRange(TSPoint start, TSPoint end) {
    return treeSitter
        .ts_node_named_descendant_for_point_range(this, start, end)
        ._nullable;
  }

  String toDartString() {
    return treeSitter.ts_node_string(this).toDartString();
  }
}
