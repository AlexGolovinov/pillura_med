import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/theme/app_theme.dart';
import 'presentation/pages/add_medication.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pillura-Med',
      theme: AppTheme.light,
      home: AddMedicationPage(), //AddMedicationPage(),
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
