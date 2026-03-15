import 'package:flutter/material.dart';

import 'package:mcp_test_app/features/login/login_screen.dart';
import 'package:mcp_test_app/features/home/home_screen.dart';
import 'package:mcp_test_app/features/counter/counter_screen.dart';
import 'package:mcp_test_app/features/settings/settings_screen.dart';
import 'package:mcp_test_app/features/profile/profile_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String counter = '/counter';
  static const String settings = '/settings';
  static const String profile = '/profile';

  static const String initial = login;

  static Map<String, WidgetBuilder> buildRoutes() {
    return {
      login: (_) => const LoginScreen(),
      home: (_) => const HomeScreen(),
      counter: (_) => const CounterScreen(),
      settings: (_) => const SettingsScreen(),
      profile: (_) => const ProfileScreen(),
    };
  }
}