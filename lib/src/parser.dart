import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'bindings.g.dart';
import 'lib.dart';
import 'tree.dart';

class TreeSitterParser {
  final self = treeSitter.ts_parser_new();

  /// Use the parser to parse some source code stored in one contiguous buffer.
  TreeSitterTree parseString(String input, {Pointer<TSTree>? oldTree}) {
    final buffer = input.toNativeUtf8().cast<Char>();
    final tree = treeSitter.ts_parser_parse_string(
        self, oldTree ?? nullptr, buffer, utf8.encode(input).length);
    malloc.free(buffer);
    return TreeSitterTree(tree);
  }

  /// Use the parser to parse some source code and create a syntax tree.
  ///
  /// If you are parsing this document for the first time, pass [nullptr] for the
  /// [oldTree] parameter. Otherwise, if you have already parsed an earlier
  /// version of this document and the document has since been edited, pass the
  /// previous syntax tree so that the unchanged parts of it can be reused.
  /// This will save time and memory. For this to work correctly, you must have
  /// already edited the old syntax tree using the [TreeSitter.ts_tree_edit] function in a
  /// way that exactly matches the source code changes.
  ///
  /// The [TSInput] parameter lets you specify how to read the text. It has the
  /// following three fields:
  /// 1. [TSInput.read] A function to retrieve a chunk of text at a given byte offset
  /// and (row, column) position. The function should return a pointer to the
  /// text and write its length to the [`bytes_read`] pointer. The parser does
  /// not take ownership of this buffer; it just borrows it until it has
  /// finished reading it. The function should write a zero value to the
  /// [`bytes_read`] pointer to indicate the end of the document.
  /// 2. [TSInput.payload] An arbitrary pointer that will be passed to each invocation
  /// of the [TSInput.read] function.
  /// 3. [TSInput.encoding] An indication of how the text is encoded. Either
  /// [TSInputEncoding.TSInputEncodingUTF8] or [TSInputEncoding.TSInputEncodingUTF16].
  ///
  /// This function returns a syntax tree on success, and `NULL` on failure. There
  /// are three possible reasons for failure:
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
  /// Tree-sitter CLI. Check the language's version using [TSLanguage.version]
  /// and compare it to this library's [TREE_SITTER_LANGUAGE_VERSION] and
  /// [TREE_SITTER_MIN_COMPATIBLE_LANGUAGE_VERSION] constants.
  bool setLanguage(Pointer<TSLanguage> language) {
    return treeSitter.ts_parser_set_language(self, language);
  }

  /// Get the parser's current language.
  Pointer<TSLanguage> getLanguage() {
    return treeSitter.ts_parser_language(self);
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

  /// Set the maximum duration in microseconds that parsing should be allowed to
  /// take before halting.
  ///
  /// If parsing takes longer than this, it will halt early, returning NULL.
  /// See [parse] for more information.
  void setTimeout(int timeout) {
    treeSitter.ts_parser_set_timeout_micros(self, timeout);
  }

  /// Get the duration in microseconds that parsing is allowed to take.
  int getTimeout() {
    return treeSitter.ts_parser_timeout_micros(self);
  }

  /// Set the parser's current cancellation flag pointer.
  ///
  /// If a non-null pointer is assigned, then the parser will periodically read
  /// from this pointer during parsing. If it reads a non-zero value, it will
  /// halt early, returning NULL. See [parse] for more information.
  void setCancelationFlag(Pointer<Size> cancellationFlag) {
    treeSitter.ts_parser_set_cancellation_flag(self, cancellationFlag);
  }

  /// Get the parser's current cancellation flag pointer.
  Pointer<Size> getCancelationFlag() {
    return treeSitter.ts_parser_cancellation_flag(self);
  }

  /// Release memory.
  void delete() {
    treeSitter.ts_parser_delete(self);
  }
}
