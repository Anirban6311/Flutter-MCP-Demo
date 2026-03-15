import 'package:flutter/material.dart';

import 'package:mcp_test_app/core/mcp/mcp_registry.dart';
import 'package:mcp_test_app/core/routing/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _error = '';
  late final McpRegistry _registry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _registry = McpRegistryScope.of(context);
    _registry.registerTextController('email_field', _emailCtrl);
    _registry.registerTextController('password_field', _passwordCtrl);
    _registry.registerTapCallback('login_btn', _login);
    _registry.registerTapCallback('skip_btn', _skip);
  }

  @override
  void dispose() {
    _registry.unregisterTextController('email_field');
    _registry.unregisterTextController('password_field');
    _registry.unregisterTapCallback('login_btn');
    _registry.unregisterTapCallback('skip_btn');
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _login() {
    if (_emailCtrl.text == 'test@mcp.com' && _passwordCtrl.text == '1234') {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      setState(() => _error = 'Invalid credentials. Try test@mcp.com / 1234');
    }
  }

  void _skip() => Navigator.pushReplacementNamed(context, AppRoutes.home);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline,
                    size: 64, color: Colors.deepPurple),
                const SizedBox(height: 16),
                const Text('MCP Test Login',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextField(
                  key: const Key('email_field'),
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('password_field'),
                  controller: _passwordCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                if (_error.isNotEmpty)
                  Text(
                      key: const Key('login_error'),
                      _error,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                      textAlign: TextAlign.center),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const Key('login_btn'),
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child:
                        const Text('Login', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  key: const Key('skip_btn'),
                  onPressed: _skip,
                  child: const Text('Skip (go to Home)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}