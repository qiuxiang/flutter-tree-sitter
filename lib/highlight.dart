import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'bindings.g.dart';
import 'flutter_tree_sitter.dart';

typedef HighlightMap = Map<(int line, int col), String>;

class Highlighter {
  late final Pointer<TSQuery> query;

  Highlighter(Pointer<TSLanguage> language, {required String highlightQuery}) {
    final queryBuf = highlightQuery.toNativeUtf8().cast<Char>();
    final errorOffset = malloc<Uint32>();
    final errorType = malloc<UnsignedInt>();
    query = treeSitter.ts_query_new(
      language,
      queryBuf,
      highlightQuery.length,
      errorOffset,
      errorType,
    );
    final error = TSQueryError.fromValue(errorType.value);
    malloc.free(queryBuf);
    malloc.free(errorOffset);
    malloc.free(errorType);
    if (error != TSQueryError.TSQueryErrorNone) {
      throw error;
    }
  }

  /// Release memory.
  void delete() {
    treeSitter.ts_query_delete(query);
  }

  /// Transform [TSNode] to semantic tokens.
  HighlightMap highlight(TSNode rootNode) {
    final highlightMap = HighlightMap();
    final queryCursor = treeSitter.ts_query_cursor_new();
    treeSitter.ts_query_cursor_exec(queryCursor, query, rootNode);
    final match = malloc<TSQueryMatch>();
    while (treeSitter.ts_query_cursor_next_match(queryCursor, match)) {
      for (var i = 0; i < match.ref.capture_count; i += 1) {
        final capture = match.ref.captures[i];
        final nameLength = malloc<Uint32>();
        final name = treeSitter
            .ts_query_capture_name_for_id(query, capture.index, nameLength)
            .cast<Utf8>()
            .toDartString(length: nameLength.value);
        final position = (
          treeSitter.ts_node_start_byte(capture.node),
          treeSitter.ts_node_end_byte(capture.node)
        );
        if (!highlightMap.containsKey(position)) {
          highlightMap[position] = name;
        }
      }
      treeSitter.ts_query_cursor_remove_match(queryCursor, match.ref.id);
    }
    return highlightMap;
  }

  List<List<HighlightSpan>> render(
    String code,
    HighlightMap highlightMap,
  ) {
    final codeLines = code.split('\n');
    final highlightIter = highlightMap.keys.iterator;
    var hasHighlight = highlightIter.moveNext();
    var lineStart = 0;
    final lines = <List<HighlightSpan>>[];
    for (final codeLine in codeLines) {
      final line = <HighlightSpan>[];
      var text = '';
      for (var i = 0; i < codeLine.length; i += 1) {
        final highlight = hasHighlight ? highlightIter.current : null;
        if (highlight != null && highlight.$1 == lineStart + i) {
          if (text.isNotEmpty) {
            line.add(HighlightSpan('', text));
          }
          line.add(HighlightSpan(
            highlightMap[highlight]!,
            codeLine.substring(i, highlight.$2 - lineStart),
          ));
          i += highlight.$2 - highlight.$1 - 1;
          hasHighlight = highlightIter.moveNext();
          text = '';
        } else {
          text += codeLine[i];
        }
      }
      if (text.isNotEmpty) {
        line.add(HighlightSpan('', text));
      }
      lineStart += codeLine.length + 1;
      lines.add(line);
    }
    return lines;
  }
}

class HighlightSpan {
  final String type;
  final String text;
  HighlightSpan(this.type, this.text);

  @override
  String toString() {
    return '($type, $text)';
  }
}
