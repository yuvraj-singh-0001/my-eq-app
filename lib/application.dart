import 'package:flutter/material.dart';

import 'core/theme/application_theme.dart';
import 'features/home/presentation/pages/home_page.dart';

class Application extends StatelessWidget {
  const Application({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyEQ App',
      theme: ApplicationTheme.light,
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}