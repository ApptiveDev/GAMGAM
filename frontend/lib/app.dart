import 'package:flutter/material.dart';

import 'views/home/home_page.dart';

class GamgamApp extends StatelessWidget {
  const GamgamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GAMGAM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
