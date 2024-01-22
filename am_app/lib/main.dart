import 'package:flutter/material.dart';
import 'screen/map/map_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moses\' Miracle',
      initialRoute: '/',
      routes: {
        '/': (context) => const MapPage(),
      },
    );
  }
}
