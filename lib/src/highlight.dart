import 'dart:ffi';

import 'bindings.g.dart';
import 'node.dart';
import 'query.dart';

typedef HighlightMap = Map<(int line, int col), String>;

class Highlighter {
  late final TreeSitterQuery query;

  Highlighter(Pointer<TSLanguage> language, {required String highlightQuery}) {
    query = TreeSitterQuery(language, highlightQuery);
  }

  /// Release memory.
  void delete() {
    query.delete();
  }

  /// Transform [TSNode] to semantic tokens.
  HighlightMap highlight(TSNode rootNode) {
    final highlightMap = HighlightMap();
    for (final capture in query.captures(rootNode)) {
      final position = (capture.node.startByte, capture.node.endByte);
      if (!highlightMap.containsKey(position)) {
        highlightMap[position] = capture.name;
      }
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
