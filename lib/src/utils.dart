import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'lib.dart';

final _free =
    treeSitter.ts_current_free.asFunction<void Function(Pointer<Void>)>();

/// Do not use [malloc.free] to free memory allocated by Tree-Sitter.
/// Use this function instead.
/// Because Windows uses a non-POSIX memory allocator.
void free(Pointer ptr) {
  _free(ptr.cast());
}

extension CharPointerExtension on Pointer<Char> {
  String toDartString({int? length}) {
    return cast<Utf8>().toDartString(length: length);
  }
}
