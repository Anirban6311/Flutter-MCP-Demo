import 'package:flutter/material.dart';

import 'package:mcp_test_app/core/mcp/mcp_registry.dart';
import 'package:mcp_test_app/shared/widgets/section_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false, _notifications = true, _analytics = false;
  String _language = 'English';
  late final McpRegistry _registry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _registry = McpRegistryScope.of(context);
    _registry.registerTapCallback(
        'dark_mode_switch', () => setState(() => _darkMode = !_darkMode));
    _registry.registerTapCallback('notifications_switch',
        () => setState(() => _notifications = !_notifications));
    _registry.registerTapCallback(
        'analytics_switch', () => setState(() => _analytics = !_analytics));
    _registry.registerTapCallback(
        'lang_english', () => setState(() => _language = 'English'));
    _registry.registerTapCallback(
        'lang_hindi', () => setState(() => _language = 'Hindi'));
    _registry.registerTapCallback(
        'lang_spanish', () => setState(() => _language = 'Spanish'));
    _registry.registerTapCallback(
        'lang_french', () => setState(() => _language = 'French'));
    _registry.registerTapCallback('save_settings_btn', _save);
    _registry.registerTextGetter(
        'settings_summary',
        () =>
            'Dark: $_darkMode | Notifications: $_notifications | Analytics: $_analytics | Language: $_language');
    _registry.registerTextGetter(
        'dark_mode_value', () => _darkMode ? 'Enabled' : 'Disabled');
    _registry.registerTextGetter(
        'notifications_value', () => _notifications ? 'Enabled' : 'Disabled');
  }

  @override
  void dispose() {
    for (final k in [
      'dark_mode_switch',
      'notifications_switch',
      'analytics_switch',
      'lang_english',
      'lang_hindi',
      'lang_spanish',
      'lang_french',
      'save_settings_btn',
    ]) {
      _registry.unregisterTapCallback(k);
    }
    for (final k in [
      'settings_summary',
      'dark_mode_value',
      'notifications_value',
    ]) {
      _registry.unregisterTextGetter(k);
    }
    super.dispose();
  }

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content:
              Text(key: Key('settings_saved_msg'), 'Settings saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const SectionHeader('Appearance'),
          SwitchListTile(
            key: const Key('dark_mode_switch'),
            title: const Text('Dark Mode'),
            subtitle: Text(
                key: const Key('dark_mode_value'),
                _darkMode ? 'Enabled' : 'Disabled'),
            value: _darkMode,
            onChanged: (v) => setState(() => _darkMode = v),
            secondary: const Icon(Icons.dark_mode),
          ),
          const SectionHeader('Notifications'),
          SwitchListTile(
            key: const Key('notifications_switch'),
            title: const Text('Push Notifications'),
            subtitle: Text(
                key: const Key('notifications_value'),
                _notifications ? 'Enabled' : 'Disabled'),
            value: _notifications,
            onChanged: (v) => setState(() => _notifications = v),
            secondary: const Icon(Icons.notifications),
          ),
          SwitchListTile(
            key: const Key('analytics_switch'),
            title: const Text('Send Analytics'),
            subtitle: Text(
                key: const Key('analytics_value'),
                _analytics ? 'On' : 'Off'),
            value: _analytics,
            onChanged: (v) => setState(() => _analytics = v),
            secondary: const Icon(Icons.bar_chart),
          ),
          const SectionHeader('Language'),
          ...['English', 'Hindi', 'Spanish', 'French'].map(
              (lang) => RadioListTile<String>(
                    key: Key('lang_${lang.toLowerCase()}'),
                    title: Text(lang),
                    value: lang,
                    groupValue: _language,
                    onChanged: (v) => setState(() => _language = v!),
                  )),
          const SectionHeader('Current Config'),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              key: const Key('settings_summary'),
              'Dark: $_darkMode | Notifications: $_notifications | Analytics: $_analytics | Language: $_language',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              key: const Key('save_settings_btn'),
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}