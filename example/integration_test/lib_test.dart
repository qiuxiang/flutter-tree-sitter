import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tree_sitter/flutter_tree_sitter.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app', (tester) async {
    final parser = treeSitter.ts_parser_new();
    print(parser);
    treeSitter.ts_parser_delete(parser);
  });
}
