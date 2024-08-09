import 'dart:ffi';
import 'dart:io';

import 'bindings.g.dart';

const _libName = 'flutter_tree_sitter';
final _lib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

/// Tree-Sitter bindings.
final treeSitter = TreeSitter(_lib);
