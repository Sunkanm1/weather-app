import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

/// Client for the free Open-Meteo geocoding and forecast APIs (no key needed).
class WeatherApi {
  WeatherApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<Place>> searchPlaces(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];

    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': trimmed,
      'count': '10',
      'language': 'en',
      'format': 'json',
    });
    final response = await _client.get(uri);
    if (response.statusCode != 200) throw WeatherApiException('Could not search locations');
    return parsePlaces(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<WeatherSnapshot> fetchWeather(Place place) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '${place.latitude}',
      'longitude': '${place.longitude}',
      'current': 'temperature_2m,apparent_temperature,weather_code,is_day,wind_speed_10m,relative_humidity_2m',
      'hourly': 'temperature_2m,weather_code',
      'daily': 'weather_code,temperature_2m_max,temperature_2m_min',
      'timezone': 'auto',
      'forecast_days': '7',
    });
    final response = await _client.get(uri);
    if (response.statusCode != 200) throw WeatherApiException('Could not load the weather');
    return parseForecast(jsonDecode(response.body) as Map<String, dynamic>);
  }
}

class WeatherApiException implements Exception {
  WeatherApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

List<Place> parsePlaces(Map<String, dynamic> json) => [
      for (final r in (json['results'] as List?) ?? const [])
        Place.fromJson(r as Map<String, dynamic>),
    ];

/// Turns an Open-Meteo forecast response into a [WeatherSnapshot].
/// Times are the location's local time (the request uses `timezone=auto`).
WeatherSnapshot parseForecast(Map<String, dynamic> json) {
  final c = json['current'] as Map<String, dynamic>;
  final current = CurrentWeather(
    temperature: (c['temperature_2m'] as num).toDouble(),
    apparentTemperature: (c['apparent_temperature'] as num).toDouble(),
    weatherCode: c['weather_code'] as int,
    isDay: c['is_day'] == 1,
    windSpeed: (c['wind_speed_10m'] as num).toDouble(),
    humidity: (c['relative_humidity_2m'] as num).round(),
  );

  // The current reading can be at :15 or :45; start the hourly strip at the
  // hour it falls in.
  final now = DateTime.parse(c['time'] as String);
  final thisHour = DateTime(now.year, now.month, now.day, now.hour);

  final h = json['hourly'] as Map<String, dynamic>;
  final hourTimes = [for (final t in h['time'] as List) DateTime.parse(t as String)];
  var start = hourTimes.indexWhere((t) => !t.isBefore(thisHour));
  if (start < 0) start = 0;
  final hourly = [
    for (var i = start; i < hourTimes.length && i < start + 24; i++)
      HourlyForecast(
        time: hourTimes[i],
        temperature: ((h['temperature_2m'] as List)[i] as num).toDouble(),
        weatherCode: (h['weather_code'] as List)[i] as int,
      ),
  ];

  final d = json['daily'] as Map<String, dynamic>;
  final dates = d['time'] as List;
  final daily = [
    for (var i = 0; i < dates.length; i++)
      DailyForecast(
        date: DateTime.parse(dates[i] as String),
        weatherCode: (d['weather_code'] as List)[i] as int,
        tempMax: ((d['temperature_2m_max'] as List)[i] as num).toDouble(),
        tempMin: ((d['temperature_2m_min'] as List)[i] as num).toDouble(),
      ),
  ];

  return WeatherSnapshot(current: current, hourly: hourly, daily: daily);
}
