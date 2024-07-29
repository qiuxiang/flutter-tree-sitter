import 'package:flutter/material.dart';
import 'package:flutter_tree_sitter/lib.dart';

void main() {
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    final parser = treeSitter.ts_parser_new();
    print(parser);
    treeSitter.ts_parser_delete(parser);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Native Packages'),
        ),
        body: const SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(children: [
            Text(
              'This calls a native function through FFI that is shipped as source in the package. '
              'The native code is built as part of the Flutter Runner build.',
            ),
          ]),
        ),
      ),
    );
  }
}
