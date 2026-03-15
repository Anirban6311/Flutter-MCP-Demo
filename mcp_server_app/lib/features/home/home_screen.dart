import 'package:flutter/material.dart';

import 'package:mcp_test_app/core/mcp/mcp_registry.dart';
import 'package:mcp_test_app/core/routing/app_routes.dart';
import 'package:mcp_test_app/shared/widgets/nav_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final McpRegistry _registry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _registry = McpRegistryScope.of(context);
    _registry.registerTapCallback(
        'counter_card', () => Navigator.pushNamed(context, AppRoutes.counter));
    _registry.registerTapCallback(
        'settings_card', () => Navigator.pushNamed(context, AppRoutes.settings));
    _registry.registerTapCallback(
        'profile_card', () => Navigator.pushNamed(context, AppRoutes.profile));
    _registry.registerTapCallback('settings_icon_btn',
        () => Navigator.pushNamed(context, AppRoutes.settings));
    _registry.registerTapCallback(
        'profile_icon_btn', () => Navigator.pushNamed(context, AppRoutes.profile));
    _registry.registerTapCallback('fab_snackbar', () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hello from MCP!')),
      );
    });
  }

  @override
  void dispose() {
    for (final key in [
      'counter_card',
      'settings_card',
      'profile_card',
      'settings_icon_btn',
      'profile_icon_btn',
      'fab_snackbar',
    ]) {
      _registry.unregisterTapCallback(key);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MCP Test App — Home'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            key: const Key('profile_icon_btn'),
            tooltip: 'Profile',
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
          IconButton(
            key: const Key('settings_icon_btn'),
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                key: const Key('greeting_text'),
                'Welcome to the MCP Test App!',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
                key: const Key('subtitle_text'),
                'Use Claude to navigate and interact with this app.',
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 28),
            NavCard(
              key: const Key('counter_card'),
              icon: Icons.add_circle_outline,
              title: 'Counter',
              subtitle: 'Tap a button, increment/decrement a counter',
              color: Colors.orange,
              onTap: () => Navigator.pushNamed(context, AppRoutes.counter),
            ),
            const SizedBox(height: 12),
            NavCard(
              key: const Key('settings_card'),
              icon: Icons.settings_outlined,
              title: 'Settings',
              subtitle: 'Toggle switches, choose options',
              color: Colors.teal,
              onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
            ),
            const SizedBox(height: 12),
            NavCard(
              key: const Key('profile_card'),
              icon: Icons.person_outline,
              title: 'Profile',
              subtitle: 'Edit name and bio, save changes',
              color: Colors.indigo,
              onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('fab_snackbar'),
        tooltip: 'Show Snackbar',
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hello from MCP!')),
          );
        },
        icon: const Icon(Icons.notifications_active),
        label: const Text('Ping'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
    );
  }
}