import 'package:flutter/material.dart';

import 'package:mcp_test_app/core/mcp/mcp_registry.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController(text: 'Claude User');
  final _bioCtrl =
      TextEditingController(text: 'I am a Flutter app being tested by AI.');
  bool _saved = false;
  late final McpRegistry _registry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _registry = McpRegistryScope.of(context);
    _registry.registerTextController('name_field', _nameCtrl);
    _registry.registerTextController('bio_field', _bioCtrl);
    _registry.registerTapCallback('save_profile_btn', _save);
    _registry.registerTextGetter('profile_display_name', () => _nameCtrl.text);
  }

  @override
  void dispose() {
    _registry.unregisterTextController('name_field');
    _registry.unregisterTextController('bio_field');
    _registry.unregisterTapCallback('save_profile_btn');
    _registry.unregisterTextGetter('profile_display_name');
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _save() {
    setState(() => _saved = true);
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile updated: ${_nameCtrl.text}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: Colors.indigo.shade100,
              child:
                  const Icon(Icons.person, size: 56, color: Colors.indigo),
            ),
            const SizedBox(height: 8),
            Text(
                key: const Key('profile_display_name'),
                _nameCtrl.text,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              key: const Key('name_field'),
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                prefixIcon: Icon(Icons.badge),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('bio_field'),
              controller: _bioCtrl,
              decoration: const InputDecoration(
                labelText: 'Bio',
                prefixIcon: Icon(Icons.edit_note),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: const Key('save_profile_btn'),
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (_saved) ...[
              const SizedBox(height: 16),
              const Text(
                  key: Key('profile_save_status'),
                  'Profile saved successfully!',
                  style: TextStyle(color: Colors.green, fontSize: 15)),
            ],
          ],
        ),
      ),
    );
  }
}