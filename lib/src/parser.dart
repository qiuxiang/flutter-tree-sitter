import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'bindings.g.dart';
import 'lib.dart';
import 'tree.dart';

class TreeSitterParser {
  final self = treeSitter.ts_parser_new();

  /// Use the parser to parse some source code stored in one contiguous buffer.
  /// The first two parameters are the same as in the [parse] function
  /// above. The second two parameters indicate the location of the buffer and its
  /// length in bytes.
  TreeSitterTree parseString(String input, {TreeSitterTree? oldTree}) {
    final buffer = input.toNativeUtf8().cast<Char>();
    final tree = treeSitter.ts_parser_parse_string(
        self, oldTree?.self ?? nullptr, buffer, utf8.encode(input).length);
    malloc.free(buffer);
    return TreeSitterTree(tree);
  }

  /// Use the parser to parse some source code stored in one contiguous buffer with
  /// a given encoding. The first four parameters work the same as in the
  /// [parseString] method above. The final parameter indicates whether
  /// the text is encoded as UTF8 or UTF16.
  TreeSitterTree parseStringEncoding(String input, TSInputEncoding encoding, {TreeSitterTree? oldTree}) {
    final buffer = input.toNativeUtf8().cast<Char>();
    final tree = treeSitter.ts_parser_parse_string_encoding(
        self, oldTree?.self ?? nullptr, buffer, utf8.encode(input).length, encoding);
    malloc.free(buffer);
    return TreeSitterTree(tree);
  }

  /// Use the parser to parse some source code and create a syntax tree, with some options.
  ///
  /// See [parse] for more details.
  ///
  /// See [TSParseOptions] for more details on the options.
  TreeSitterTree parseWithOptions(TSInput input, TSParseOptions parseOptions, {TreeSitterTree? oldTree}) {
    return TreeSitterTree(
      treeSitter.ts_parser_parse_with_options(self, oldTree?.self ?? nullptr, input, parseOptions),
    );
  }

  /// Use the parser to parse some source code and create a syntax tree.
  ///
  /// If you are parsing this document for the first time, pass `null` for the
  /// [oldTree] parameter. Otherwise, if you have already parsed an earlier
  /// version of this document and the document has since been edited, pass the
  /// previous syntax tree so that the unchanged parts of it can be reused.
  /// This will save time and memory. For this to work correctly, you must have
  /// already edited the old syntax tree using the [TreeSitterTree.edit] function in a
  /// way that exactly matches the source code changes.
  ///
  /// The [TSInput] parameter lets you specify how to read the text. It has the
  /// following three fields:
  /// 1. `read`: A function to retrieve a chunk of text at a given byte offset
  /// and (row, column) position. The function should return a pointer to the
  /// text and write its length to the `bytes_read` pointer. The parser does
  /// not take ownership of this buffer; it just borrows it until it has
  /// finished reading it. The function should write a zero value to the
  /// `bytes_read` pointer to indicate the end of the document.
  /// 2. `payload`: An arbitrary pointer that will be passed to each invocation
  /// of the `read` function.
  /// 3. `encoding`: An indication of how the text is encoded. Either
  /// `TSInputEncodingUTF8` or `TSInputEncodingUTF16`.
  ///
  /// This function returns a syntax tree on success, and `null` on failure. There
  /// are four possible reasons for failure:
  /// 1. The parser does not have a language assigned. Check for this using the
  /// [getLanguage] function.
  /// 2. Parsing was cancelled due to a timeout that was set by an earlier call to
  /// the [setTimeout] function. You can resume parsing from
  /// where the parser left out by calling [parse] again with the
  /// same arguments. Or you can start parsing from scratch by first calling
  /// [reset].
  /// 3. Parsing was cancelled using a cancellation flag that was set by an
  /// earlier call to [setCancelationFlag]. You can resume parsing
  /// from where the parser left out by calling [parse] again with
  /// the same arguments.
  /// 4. Parsing was cancelled due to the progress callback returning true. This callback
  /// is passed in [parseWithOptions] inside the [TSParseOptions] struct.
  TreeSitterTree parse(TSInput input, {TreeSitterTree? oldTree}) {
    return TreeSitterTree(
      treeSitter.ts_parser_parse(self, oldTree?.self ?? nullptr, input),
    );
  }

  /// Instruct the parser to start the next parse from the beginning.
  ///
  /// If the parser previously failed because of a timeout or a cancellation, then
  /// by default, it will resume where it left off on the next call to
  /// [parse] or other parsing functions. If you don't want to resume,
  /// and instead intend to use this parser to parse some other document, you must
  /// call [reset] first.
  void reset() {
    treeSitter.ts_parser_reset(self);
  }

  /// Set the language that the parser should use for parsing.
  ///
  /// Returns a boolean indicating whether or not the language was successfully
  /// assigned. True means assignment succeeded. False means there was a version
  /// mismatch: the language was generated with an incompatible version of the
  /// Tree-sitter CLI. Check the language's ABI version using [ts_language_abi_version]
  /// and compare it to this library's [TREE_SITTER_LANGUAGE_VERSION] and
  /// [TREE_SITTER_MIN_COMPATIBLE_LANGUAGE_VERSION] constants.
  bool setLanguage(Pointer<TSLanguage> language) {
    return treeSitter.ts_parser_set_language(self, language);
  }

  /// Get the parser's current language.
  Pointer<TSLanguage> getLanguage() {
    return treeSitter.ts_parser_language(self);
  }

  /// Set the ranges of text that the parser should include when parsing.
  ///
  /// By default, the parser will always include entire documents. This function
  /// allows you to parse only a *portion* of a document but still return a syntax
  /// tree whose ranges match up with the document as a whole. You can also pass
  /// multiple disjoint ranges.
  ///
  /// The parser does *not* take ownership of these ranges; it copies
  /// the data, so it doesn't matter how these ranges are allocated.
  ///
  /// If [ranges] is empty, then the entire document will be parsed. Otherwise,
  /// the given ranges must be ordered from earliest to latest in the document,
  /// and they must not overlap. That is, the following must hold for all:
  ///
  /// `i < count - 1`: `ranges[i].end_byte <= ranges[i + 1].start_byte`
  ///
  /// If this requirement is not satisfied, the operation will fail, the ranges
  /// will not be assigned, and this function will return `false`. On success,
  /// this function returns `true`
  bool setIncludedRanges(List<TSRange> ranges) {
    if (ranges.isEmpty) {
      return treeSitter.ts_parser_set_included_ranges(self, nullptr, 0);
    }
    
    final rangesPtr = malloc<TSRange>(ranges.length);
    for (int i = 0; i < ranges.length; i++) {
      rangesPtr[i] = ranges[i];
    }
    
    final result = treeSitter.ts_parser_set_included_ranges(self, rangesPtr, ranges.length);
    malloc.free(rangesPtr);
    return result;
  }

  /// Get the ranges of text that the parser will include when parsing.
  ///
  /// The returned ranges are owned by the parser. The length of the array will be written to the returned list.
  List<TSRange> getIncludedRanges() {
    final countPtr = malloc<ffi.Uint32>();
    final rangesPtr = treeSitter.ts_parser_included_ranges(self, countPtr);
    final count = countPtr.value;
    malloc.free(countPtr);
    
    if (rangesPtr == nullptr || count == 0) {
      return [];
    }
    
    return List.generate(count, (i) => rangesPtr[i]);
  }

  /// Get the parser's current logger.
  TSLogger getLogger() {
    return treeSitter.ts_parser_logger(self);
  }

  /// Set the logger that a parser should use during parsing.
  ///
  /// The parser does not take ownership over the logger payload. If a logger was
  /// previously assigned, the caller is responsible for releasing any memory
  /// owned by the previous logger.
  void setLogger(TSLogger logger) {
    treeSitter.ts_parser_set_logger(self, logger);
  }

  /// Set the file descriptor to which the parser should write debugging graphs
  /// during parsing. The graphs are formatted in the DOT language. You may want
  /// to pipe these graphs directly to a `dot(1)` process in order to generate
  /// SVG output. You can turn off this logging by passing a negative number.
  void printDotGraphs(int fd) {
    treeSitter.ts_parser_print_dot_graphs(self, fd);
  }

  /// @deprecated use [parseWithOptions] and pass in a callback instead, this will be removed in 0.26.
  ///
  /// Set the maximum duration in microseconds that parsing should be allowed to
  /// take before halting.
  ///
  /// If parsing takes longer than this, it will halt early, returning NULL.
  /// See [parse] for more information.
  @Deprecated('Use parseWithOptions and pass in a callback instead, this will be removed in 0.26.')
  void setTimeout(int timeout) {
    treeSitter.ts_parser_set_timeout_micros(self, timeout);
  }

  /// @deprecated use [parseWithOptions] and pass in a callback instead, this will be removed in 0.26.
  ///
  /// Get the duration in microseconds that parsing is allowed to take.
  @Deprecated('Use parseWithOptions and pass in a callback instead, this will be removed in 0.26.')
  int getTimeout() {
    return treeSitter.ts_parser_timeout_micros(self);
  }

  /// @deprecated use [parseWithOptions] and pass in a callback instead, this will be removed in 0.26.
  ///
  /// Set the parser's current cancellation flag pointer.
  ///
  /// If a non-null pointer is assigned, then the parser will periodically read
  /// from this pointer during parsing. If it reads a non-zero value, it will
  /// halt early, returning NULL. See [parse] for more information.
  @Deprecated('Use parseWithOptions and pass in a callback instead, this will be removed in 0.26.')
  void setCancelationFlag(Pointer<ffi.Size> cancellationFlag) {
    treeSitter.ts_parser_set_cancellation_flag(self, cancellationFlag);
  }

  /// @deprecated use [parseWithOptions] and pass in a callback instead, this will be removed in 0.26.
  ///
  /// Get the parser's current cancellation flag pointer.
  @Deprecated('Use parseWithOptions and pass in a callback instead, this will be removed in 0.26.')
  Pointer<ffi.Size> getCancelationFlag() {
    return treeSitter.ts_parser_cancellation_flag(self);
  }

  /// Delete the parser, freeing all of the memory that it used.
  void delete() {
    treeSitter.ts_parser_delete(self);
  }
}
