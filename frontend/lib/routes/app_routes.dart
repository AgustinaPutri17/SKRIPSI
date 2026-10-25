import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/siswa/siswa_main_screen.dart';
import '../screens/guru/guru_main_screen.dart';
import '../screens/dudi/dudi_main_screen.dart';
import '../screens/admin/admin_main_screen.dart';
import '../screens/common/ganti_password_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String siswa = '/siswa';
  static const String guru = '/guru';
  static const String dudi = '/dudi';
  static const String admin = '/admin';
  static const String gantiPassword = '/ganti-password';

  static Map<String, WidgetBuilder> get routes => {
        login: (context) => const LoginScreen(),
        siswa: (context) => const SiswaMainScreen(),
        guru: (context) => const GuruMainScreen(),
        dudi: (context) => const DudiMainScreen(),
        admin: (context) => const AdminMainScreen(),
        gantiPassword: (context) => const GantiPasswordScreen(),
      };
}
