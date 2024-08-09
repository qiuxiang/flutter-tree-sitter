import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'bindings.g.dart';
import 'lib.dart';
import 'utils.dart';

class TreeSitterQuery {
  late final Pointer<TSQuery> self;
  late final Pointer<TSQueryCursor> cursor;

  /// Create a new query from a string containing one or more S-expression
  /// patterns. The query is associated with a particular language, and can
  /// only be run on syntax nodes parsed with that language.
  ///
  /// If all of the given patterns are valid, this returns a [TreeSitterQuery].
  /// If a pattern is invalid, throw an exception, and provides two pieces
  /// of information about the problem:
  /// 1. The byte offset of the error is written to the `error_offset` parameter.
  /// 2. The type of error is written to the `error_type` parameter.
  TreeSitterQuery(Pointer<TSLanguage> language, String query) {
    final queryBuf = query.toNativeUtf8();
    final errorOffset = malloc<Uint32>();
    final errorType = malloc<UnsignedInt>();
    self = treeSitter.ts_query_new(
      language,
      queryBuf.cast(),
      query.length,
      errorOffset,
      errorType,
    );
    final error = TSQueryError.fromValue(errorType.value);
    final offset = errorOffset.value;
    malloc.free(queryBuf);
    malloc.free(errorOffset);
    malloc.free(errorType);
    if (error != TSQueryError.TSQueryErrorNone) {
      treeSitter.ts_query_delete(self);
      throw (error, offset);
    }

    cursor = treeSitter.ts_query_cursor_new();
  }

  Iterable<TreeSitterQueryMatch> matches(TSNode node) sync* {
    treeSitter.ts_query_cursor_set_byte_range(cursor, 0, 0);
    treeSitter.ts_query_cursor_exec(cursor, self, node);
    final match = malloc<TSQueryMatch>();
    while (treeSitter.ts_query_cursor_next_match(cursor, match)) {
      final captures = <TreeSitterQueryCapture>[];
      for (var i = 0; i < match.ref.capture_count; i += 1) {
        final capture = match.ref.captures[i];
        final nameLength = malloc<Uint32>();
        final name = treeSitter
            .ts_query_capture_name_for_id(self, capture.index, nameLength)
            .toDartString(length: nameLength.value);
        captures.add(TreeSitterQueryCapture(name, capture.node));
      }
      yield TreeSitterQueryMatch(match.ref.pattern_index, captures);
      treeSitter.ts_query_cursor_remove_match(cursor, match.ref.id);
    }
    malloc.free(match);
  }

  Iterable<TreeSitterQueryCapture> captures(TSNode node) sync* {
    treeSitter.ts_query_cursor_set_byte_range(cursor, 0, 0);
    treeSitter.ts_query_cursor_exec(cursor, self, node);
    final match = malloc<TSQueryMatch>();
    final index = malloc<Uint32>();
    while (treeSitter.ts_query_cursor_next_capture(cursor, match, index)) {
      for (var i = 0; i < match.ref.capture_count; i += 1) {
        final capture = match.ref.captures[i];
        final nameLength = malloc<Uint32>();
        final name = treeSitter
            .ts_query_capture_name_for_id(self, capture.index, nameLength)
            .toDartString(length: nameLength.value);
        yield TreeSitterQueryCapture(name, capture.node);
      }
      treeSitter.ts_query_cursor_remove_match(cursor, match.ref.id);
    }
    malloc.free(match);
    malloc.free(index);
  }

  /// Release memory.
  void delete() {
    treeSitter.ts_query_delete(self);
    treeSitter.ts_query_cursor_delete(cursor);
  }
}

class TreeSitterQueryMatch {
  final int pattern;
  final List<TreeSitterQueryCapture> captures;

  const TreeSitterQueryMatch(this.pattern, this.captures);
}

class TreeSitterQueryCapture {
  final String name;
  final TSNode node;

  const TreeSitterQueryCapture(this.name, this.node);
}
