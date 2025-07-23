import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tree_sitter/flutter_tree_sitter.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Tree-sitter Integration Tests', () {
    late TreeSitterParser parser;

    setUp(() {
      parser = TreeSitterParser();
    });

    tearDown(() {
      parser.delete();
    });

    testWidgets('Basic parser functionality', (tester) async {
      // Test basic parser creation and deletion
      expect(parser.self, isNot(equals(nullptr)));
    });

    testWidgets('Parser parseString functionality', (tester) async {
      // Test basic string parsing (without language - will create a tree with basic structure)
      final tree = parser.parseString('hello world');
      expect(tree.self, isNot(equals(nullptr)));
      
      final rootNode = tree.rootNode;
      expect(rootNode._isNull, isFalse);
      
      tree.delete();
    });

    testWidgets('Parser parseStringEncoding functionality', (tester) async {
      // Test parseStringEncoding with UTF8
      final tree = parser.parseStringEncoding('hello world', TSInputEncoding.TSInputEncodingUTF8);
      expect(tree.self, isNot(equals(nullptr)));
      tree.delete();
    });

    testWidgets('Parser included ranges functionality', (tester) async {
      // Test setIncludedRanges and getIncludedRanges with empty ranges first
      var success = parser.setIncludedRanges([]);
      expect(success, isTrue);

      var retrievedRanges = parser.getIncludedRanges();
      expect(retrievedRanges.length, equals(0));
      
      // Test with actual ranges
      final rangePtr1 = malloc<TSRange>();
      final rangePtr2 = malloc<TSRange>();
      
      // Setup first range
      rangePtr1.ref.start_point.row = 0;
      rangePtr1.ref.start_point.column = 0;
      rangePtr1.ref.end_point.row = 0;
      rangePtr1.ref.end_point.column = 5;
      rangePtr1.ref.start_byte = 0;
      rangePtr1.ref.end_byte = 5;
      
      // Setup second range
      rangePtr2.ref.start_point.row = 0;
      rangePtr2.ref.start_point.column = 6;
      rangePtr2.ref.end_point.row = 0;
      rangePtr2.ref.end_point.column = 11;
      rangePtr2.ref.start_byte = 6;
      rangePtr2.ref.end_byte = 11;

      final ranges = [rangePtr1.ref, rangePtr2.ref];

      success = parser.setIncludedRanges(ranges);
      expect(success, isTrue);

      retrievedRanges = parser.getIncludedRanges();
      expect(retrievedRanges.length, equals(2));
      expect(retrievedRanges[0].start_byte, equals(0));
      expect(retrievedRanges[0].end_byte, equals(5));
      expect(retrievedRanges[1].start_byte, equals(6));
      expect(retrievedRanges[1].end_byte, equals(11));
      
      malloc.free(rangePtr1);
      malloc.free(rangePtr2);
    });

    testWidgets('Parser timeout functionality', (tester) async {
      // Test timeout settings
      parser.setTimeout(1000000); // 1 second in microseconds
      final timeout = parser.getTimeout();
      expect(timeout, equals(1000000));
    });

    testWidgets('Tree copy functionality', (tester) async {
      final originalTree = parser.parseString('test code');
      
      // Test tree copy
      final copiedTree = originalTree.copy();
      expect(copiedTree.self, isNot(equals(nullptr)));
      expect(copiedTree.self, isNot(equals(originalTree.self)));
      
      originalTree.delete();
      copiedTree.delete();
    });

    testWidgets('Tree rootNodeWithOffset functionality', (tester) async {
      final tree = parser.parseString('hello world');
      
      // Test rootNodeWithOffset
      final offsetPointPtr = malloc<TSPoint>();
      offsetPointPtr.ref.row = 0;
      offsetPointPtr.ref.column = 5;
      
      final rootNodeWithOffset = tree.rootNodeWithOffset(5, offsetPointPtr.ref);
      expect(rootNodeWithOffset._isNull, isFalse);
      
      malloc.free(offsetPointPtr);
      tree.delete();
    });

    testWidgets('Tree edit functionality', (tester) async {
      final tree = parser.parseString('hello world');
      
      // Test tree edit
      final editPtr = malloc<TSInputEdit>();
      editPtr.ref.start_byte = 6;
      editPtr.ref.old_end_byte = 11;
      editPtr.ref.new_end_byte = 12;
      editPtr.ref.start_point.row = 0;
      editPtr.ref.start_point.column = 6;
      editPtr.ref.old_end_point.row = 0;
      editPtr.ref.old_end_point.column = 11;
      editPtr.ref.new_end_point.row = 0;
      editPtr.ref.new_end_point.column = 12;
      
      tree.edit(editPtr.ref);
      // Tree should still be valid after edit
      expect(tree.self, isNot(equals(nullptr)));
      
      malloc.free(editPtr);
      tree.delete();
    });

    testWidgets('Tree getChangedRanges functionality', (tester) async {
      final oldTree = parser.parseString('hello');
      final newTree = parser.parseString('hello world');
      
      // Test getChangedRanges
      final changedRanges = oldTree.getChangedRanges(newTree);
      expect(changedRanges, isA<List<TSRange>>());
      
      oldTree.delete();
      newTree.delete();
    });

    testWidgets('Tree includedRanges getter functionality', (tester) async {
      final tree = parser.parseString('test');
      
      // Test includedRanges getter
      final ranges = tree.includedRanges;
      expect(ranges, isA<List<TSRange>>());
      
      tree.delete();
    });

    testWidgets('Node properties functionality', (tester) async {
      final tree = parser.parseString('test');
      final rootNode = tree.rootNode;
      
      // Test node symbol
      final symbol = rootNode.symbol;
      expect(symbol, isA<int>());
      
      // Test node string representation (S-expression)
      final nodeString = rootNode.string;
      expect(nodeString, isA<String>());
      expect(nodeString.isNotEmpty, isTrue);
      
      // Test grammar symbol
      final grammarSymbol = rootNode.grammarSymbol;
      expect(grammarSymbol, isA<int>());
      
      // Test node type
      expect(rootNode.type, isA<String>());
      
      // Test node byte positions
      expect(rootNode.startByte, isA<int>());
      expect(rootNode.endByte, isA<int>());
      expect(rootNode.endByte, greaterThanOrEqualTo(rootNode.startByte));
      
      tree.delete();
    });

    testWidgets('Node navigation functionality', (tester) async {
      final tree = parser.parseString('hello world');
      final rootNode = tree.rootNode;
      
      // Test child count
      final childCount = rootNode.childCount;
      expect(childCount, isA<int>());
      expect(childCount, greaterThanOrEqualTo(0));
      
      // Test named child count
      final namedChildCount = rootNode.namedChildCount;
      expect(namedChildCount, isA<int>());
      expect(namedChildCount, greaterThanOrEqualTo(0));
      
      // If there are children, test navigation
      if (childCount > 0) {
        final firstChild = rootNode.child(0);
        expect(firstChild, isNotNull);
        expect(firstChild!._isNull, isFalse);
        
        // Test firstChildForByte
        final childForByte = rootNode.firstChildForByte(0);
        expect(childForByte, isNotNull);
      }
      
      tree.delete();
    });

    testWidgets('Node equality functionality', (tester) async {
      final tree = parser.parseString('test');
      final rootNode1 = tree.rootNode;
      final rootNode2 = tree.rootNode;
      
      // Test node equality
      final isEqual = rootNode1.isEqual(rootNode2);
      expect(isEqual, isTrue);
      
      tree.delete();
    });

    testWidgets('Node edit functionality', (tester) async {
      final tree = parser.parseString('hello');
      final rootNode = tree.rootNode;
      
      // Test node edit
      final editPtr = malloc<TSInputEdit>();
      editPtr.ref.start_byte = 0;
      editPtr.ref.old_end_byte = 5;
      editPtr.ref.new_end_byte = 11;
      editPtr.ref.start_point.row = 0;
      editPtr.ref.start_point.column = 0;
      editPtr.ref.old_end_point.row = 0;
      editPtr.ref.old_end_point.column = 5;
      editPtr.ref.new_end_point.row = 0;
      editPtr.ref.new_end_point.column = 11;
      
      final editedNode = rootNode.edit(editPtr.ref);
      expect(editedNode._isNull, isFalse);
      
      malloc.free(editPtr);
      tree.delete();
    });

    testWidgets('Parser reset functionality', (tester) async {
      // Parse something first
      final tree1 = parser.parseString('hello');
      tree1.delete();
      
      // Reset parser
      parser.reset();
      
      // Parse again after reset
      final tree2 = parser.parseString('world');
      expect(tree2.self, isNot(equals(nullptr)));
      tree2.delete();
    });

    testWidgets('Parser language functionality', (tester) async {
      // Test getting language (should be null initially)
      final language = parser.getLanguage();
      expect(language, equals(nullptr));
    });

    testWidgets('Parser logger functionality', (tester) async {
      // Test getting logger (should return valid logger initially)
      final logger = parser.getLogger();
      expect(logger, isNotNull);
      
      // Test setting a logger (using null logger for simplicity)
      final nullLoggerPtr = malloc<TSLogger>();
      nullLoggerPtr.ref.payload = nullptr;
      nullLoggerPtr.ref.log = nullptr;
      
      parser.setLogger(nullLoggerPtr.ref);
      
      // Should not throw an exception
      expect(() => parser.reset(), returnsNormally);
      
      malloc.free(nullLoggerPtr);
    });

    testWidgets('Memory management', (tester) async {
      // Test that we can create and delete multiple trees without issues
      for (int i = 0; i < 5; i++) {
        final tree = parser.parseString('test $i');
        expect(tree.self, isNot(equals(nullptr)));
        tree.delete();
      }
    });

    // Test cancellation flag functionality
    testWidgets('Parser cancellation flag functionality', (tester) async {
      final flagPtr = malloc<Size>();
      flagPtr.value = 0;
      
      parser.setCancelationFlag(flagPtr);
      final retrievedFlag = parser.getCancelationFlag();
      expect(retrievedFlag, equals(flagPtr));
      
      malloc.free(flagPtr);
    });

    testWidgets('Node fieldNameForNamedChild functionality', (tester) async {
      final tree = parser.parseString('test');
      final rootNode = tree.rootNode;
      
      // Test fieldNameForNamedChild with valid index
      if (rootNode.namedChildCount > 0) {
        final fieldName = rootNode.fieldNameForNamedChild(0);
        expect(fieldName, isA<String?>());
      }
      
      tree.delete();
    });

    testWidgets('Node firstNamedChildForByte functionality', (tester) async {
      final tree = parser.parseString('hello world');
      final rootNode = tree.rootNode;
      
      // Test firstNamedChildForByte
      final namedChild = rootNode.firstNamedChildForByte(0);
      // May be null if no named children at that byte position
      if (namedChild != null) {
        expect(namedChild._isNull, isFalse);
      }
      
      tree.delete();
    });
  });
}
