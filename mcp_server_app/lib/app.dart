import 'package:flutter/material.dart';

import 'package:mcp_test_app/core/mcp/mcp_registry.dart';
import 'package:mcp_test_app/core/routing/app_routes.dart';
import 'package:mcp_test_app/core/theme/app_theme.dart';

class McpTestApp extends StatelessWidget {
  final McpRegistry registry;

  const McpTestApp({super.key, required this.registry});

  @override
  Widget build(BuildContext context) {
    return McpRegistryScope(
      registry: registry,
      child: MaterialApp(
        title: 'MCP Test App',
        navigatorKey: registry.navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        initialRoute: AppRoutes.initial,
        routes: AppRoutes.buildRoutes(),
      ),
    );
  }
}