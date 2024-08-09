import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'bindings.g.dart';
import 'lib.dart';
import 'utils.dart';

extension TSLanguageExtension on Pointer<TSLanguage> {
  int get version => treeSitter.ts_language_version(this);

  /// Get the field name string for the given numerical id.
  String fieldNameForId(int id) =>
      treeSitter.ts_language_field_name_for_id(this, id).toDartString();

  /// Get the numerical id for the given field name string.
  int fieldIdForName(String name) {
    final buffer = name.toNativeUtf8();
    final id = treeSitter.ts_language_field_id_for_name(
        this, buffer.cast(), name.length);
    malloc.free(buffer);
    return id;
  }

  /// Get the node type string for the given numerical id.
  String symbolName(int id) =>
      treeSitter.ts_language_symbol_name(this, id).toDartString();

  /// Get the numerical id for the given node type string.
  int symbolForName(String name, bool isNamed) {
    final buffer = name.toNativeUtf8();
    final id = treeSitter.ts_language_symbol_for_name(
        this, buffer.cast(), name.length, isNamed);
    malloc.free(buffer);
    return id;
  }

  /// Check whether the given node type id belongs to named nodes, anonymous nodes,
  /// or a hidden nodes.
  ///
  /// See also [TreeSitter.ts_node_is_named]. Hidden nodes are never returned from the API.
  TSSymbolType symbolType(int symbol) {
    return treeSitter.ts_language_symbol_type(this, symbol);
  }
}
