import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'features/authentication/providers/auth_provider.dart';
import 'features/authentication/providers/auth_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('auth_box');

  runApp(
    const ProviderScope(
      child: ChinramApp(),
    ),
  );
}

class ChinramApp extends ConsumerWidget {
  const ChinramApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Listen to sign out to clear session credentials
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.unauthenticated) {
        final box = Hive.box('auth_box');
        box.put('saved_email', null);
        box.put('saved_password', null);
      }
    });

    return MaterialApp.router(
      title: 'ChinRam',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
