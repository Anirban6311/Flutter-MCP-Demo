import 'package:flutter_test/flutter_test.dart';

import 'package:mcp_test_app/app.dart';
import 'package:mcp_test_app/core/mcp/mcp_registry.dart';

void main() {
  testWidgets('App starts on login screen', (WidgetTester tester) async {
    final registry = McpRegistry();
    await tester.pumpWidget(McpTestApp(registry: registry));

    expect(find.text('MCP Test Login'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}