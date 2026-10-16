import 'package:flutter/material.dart';

import 'places_store.dart';
import 'screens/home_screen.dart';
import 'weather_api.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(WeatherApp(store: PlacesStore()..load(), api: WeatherApi()));
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key, required this.store, required this.api});

  final PlacesStore store;
  final WeatherApi api;

  @override
  Widget build(BuildContext context) {
    ThemeData theme(Brightness brightness) => ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0284C7), brightness: brightness),
          useMaterial3: true,
        );

    return MaterialApp(
      title: 'Weather',
      debugShowCheckedModeBanner: false,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      home: HomeScreen(store: store, api: api),
    );
  }
}
