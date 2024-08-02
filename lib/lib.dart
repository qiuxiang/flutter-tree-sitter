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
final treeSitter = NativeLibrary(_lib);

final _free =
    treeSitter.ts_current_free.asFunction<void Function(Pointer<Void>)>();
void free(Pointer ptr) {
  _free(ptr.cast());
}
