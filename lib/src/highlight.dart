import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'bindings.g.dart';
import 'node.dart';
import 'query.dart';

typedef Position = (int, int);
typedef HighlightMap = Map<Position, String>;

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
      highlightMap[position] = capture.name;
    }
    return highlightMap;
  }

  List<HighlightSpan> render(
    Uint8List codeBytes,
    HighlightMap highlightMap,
  ) {
    final highlightIter = highlightMap.keys.iterator;
    var hasHighlight = highlightIter.moveNext();
    final lines = <HighlightSpan>[];
    var textBytes = <int>[];
    for (var i = 0; i < codeBytes.length; i += 1) {
      final highlight = hasHighlight ? highlightIter.current : null;
      if (highlight != null && highlight.$1 == i) {
        if (textBytes.isNotEmpty) {
          lines.add(HighlightSpan('', utf8.decode(textBytes)));
        }
        lines.add(HighlightSpan(
          highlightMap[highlight]!,
          utf8.decode(codeBytes.sublist(i, highlight.$2)),
        ));
        i += highlight.$2 - highlight.$1 - 1;
        hasHighlight = highlightIter.moveNext();
        textBytes.clear();
      } else {
        textBytes.add(codeBytes[i]);
      }
    }
    if (textBytes.isNotEmpty) {
      lines.add(HighlightSpan('', utf8.decode(textBytes)));
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
