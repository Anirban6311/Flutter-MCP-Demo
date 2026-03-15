import 'package:flutter/material.dart';

import 'package:mcp_test_app/core/mcp/mcp_registry.dart';

class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key});
  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  int _count = 0;
  late final McpRegistry _registry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _registry = McpRegistryScope.of(context);
    _registry.registerTapCallback(
        'increment_btn', () => setState(() => _count++));
    _registry.registerTapCallback(
        'decrement_btn', () => setState(() => _count--));
    _registry.registerTapCallback(
        'reset_btn', () => setState(() => _count = 0));
    _registry.registerTextGetter('counter_value', () => '$_count');
    _registry.registerTextGetter(
        'counter_status',
        () => _count == 0
            ? 'At zero'
            : _count > 0
                ? 'Positive: $_count'
                : 'Negative: $_count');
  }

  @override
  void dispose() {
    _registry.unregisterTapCallback('increment_btn');
    _registry.unregisterTapCallback('decrement_btn');
    _registry.unregisterTapCallback('reset_btn');
    _registry.unregisterTextGetter('counter_value');
    _registry.unregisterTextGetter('counter_status');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Counter Value',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 12),
            Text(
              key: const Key('counter_value'),
              '$_count',
              style: TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.bold,
                color: _count < 0 ? Colors.red : Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 36),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  key: const Key('decrement_btn'),
                  heroTag: 'dec',
                  tooltip: 'Decrement',
                  onPressed: () => setState(() => _count--),
                  backgroundColor: Colors.red.shade100,
                  child: const Icon(Icons.remove, color: Colors.red),
                ),
                const SizedBox(width: 24),
                FloatingActionButton(
                  key: const Key('reset_btn'),
                  heroTag: 'reset',
                  tooltip: 'Reset',
                  onPressed: () => setState(() => _count = 0),
                  backgroundColor: Colors.grey.shade200,
                  child: const Icon(Icons.refresh, color: Colors.grey),
                ),
                const SizedBox(width: 24),
                FloatingActionButton(
                  key: const Key('increment_btn'),
                  heroTag: 'inc',
                  tooltip: 'Increment',
                  onPressed: () => setState(() => _count++),
                  backgroundColor: Colors.green.shade100,
                  child: const Icon(Icons.add, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              key: const Key('counter_status'),
              _count == 0
                  ? 'At zero'
                  : _count > 0
                      ? 'Positive: $_count'
                      : 'Negative: $_count',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}