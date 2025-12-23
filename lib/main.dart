import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pillura_med/presentation/pages/profile_page.dart';
import 'package:pillura_med/router/app_router.dart';

import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'presentation/pages/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      routerConfig: router,
      title: 'E-Agriculture',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Fonts Example', style: GoogleFonts.lato()),
      ),
      body: Center(
        child: DropdownMenu(
          dropdownMenuEntries: [
            DropdownMenuEntry(value: Colors.red, label: 'Красный'),
            DropdownMenuEntry(value: Colors.green, label: 'Зелёный'),
            DropdownMenuEntry(value: Colors.blue, label: 'Синий'),
          ],
        ),
      ),
    );
  }
}
