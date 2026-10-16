import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/main.dart';
import 'package:weather_app/models.dart';
import 'package:weather_app/places_store.dart';
import 'package:weather_app/weather_api.dart';

const lagos = Place(id: 2332459, name: 'Lagos', admin1: 'Lagos', country: 'Nigeria', latitude: 6.45, longitude: 3.39);

Map<String, dynamic> forecastJson() => {
      'current': {
        'time': '2026-10-16T09:45',
        'temperature_2m': 27.4,
        'apparent_temperature': 31.2,
        'weather_code': 2,
        'is_day': 1,
        'wind_speed_10m': 11.6,
        'relative_humidity_2m': 84,
      },
      'hourly': {
        'time': [for (var h = 0; h < 48; h++) DateTime(2026, 10, 16, h).toIso8601String().substring(0, 16)],
        'temperature_2m': [for (var h = 0; h < 48; h++) 20.0 + h % 24 / 2],
        'weather_code': [for (var h = 0; h < 48; h++) h.isEven ? 1 : 3],
      },
      'daily': {
        'time': [for (var d = 16; d < 23; d++) '2026-10-$d'],
        'weather_code': [2, 61, 3, 0, 95, 1, 2],
        'temperature_2m_max': [30.1, 29.0, 31.4, 32.0, 28.2, 30.0, 30.5],
        'temperature_2m_min': [23.0, 22.4, 23.9, 24.1, 22.0, 23.3, 23.5],
      },
    };

http.Client fakeClient() => MockClient((request) async {
      if (request.url.host.startsWith('geocoding')) {
        return http.Response(jsonEncode({'results': [lagos.toJson()]}), 200);
      }
      return http.Response(jsonEncode(forecastJson()), 200);
    });

void main() {
  test('parseForecast reads current conditions and starts the hourly strip at the current hour', () {
    final w = parseForecast(forecastJson());
    expect(w.current.temperature, 27.4);
    expect(w.current.humidity, 84);
    expect(w.current.isDay, isTrue);
    expect(w.hourly, hasLength(24));
    expect(w.hourly.first.time, DateTime(2026, 10, 16, 9));
    expect(w.daily, hasLength(7));
    expect(w.daily[1].weatherCode, 61);
  });

  test('parsePlaces handles a response with no results', () {
    expect(parsePlaces({}), isEmpty);
    expect(parsePlaces({'results': [lagos.toJson()]}).single.subtitle, 'Nigeria');
  });

  test('unknown weather codes fall back to a label', () {
    expect(describeWeatherCode(0).label, 'Clear sky');
    expect(describeWeatherCode(12345).label, 'Unknown');
  });

  test('saved places persist, ignore duplicates and can be restored after removal', () async {
    SharedPreferences.setMockInitialValues({});
    final store = PlacesStore();
    await store.load();
    expect(await store.add(lagos), isTrue);
    expect(await store.add(lagos), isFalse);

    final reloaded = PlacesStore();
    await reloaded.load();
    expect(reloaded.places.single.name, 'Lagos');

    await reloaded.remove(lagos);
    expect(reloaded.places, isEmpty);
    await reloaded.insert(0, lagos);
    expect(reloaded.places.single.id, lagos.id);
  });

  testWidgets('search for a city, add it, and open its forecast', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = PlacesStore();
    await tester.runAsync(store.load);
    await tester.pumpWidget(WeatherApp(store: store, api: WeatherApi(client: fakeClient())));
    expect(find.text('No cities yet'), findsOneWidget);

    await tester.tap(find.text('Add city'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Lag');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lagos'));
    await tester.pumpAndSettle();
    expect(find.text('Partly cloudy'), findsOneWidget);
    expect(find.text('27°'), findsOneWidget);

    await tester.tap(find.text('Lagos'));
    await tester.pumpAndSettle();
    expect(find.text('Next 24 hours'), findsOneWidget);
    expect(find.text('Feels like'), findsOneWidget);
  });
}
