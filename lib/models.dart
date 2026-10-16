/// A place the user has saved (or a search result they can save).
class Place {
  const Place({
    required this.id,
    required this.name,
    this.admin1,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  final int id;
  final String name;
  final String? admin1;
  final String country;
  final double latitude;
  final double longitude;

  /// "Region, Country", skipping the region when it repeats the name.
  String get subtitle => [
        if (admin1 != null && admin1 != name) admin1,
        country,
      ].join(', ');

  factory Place.fromJson(Map<String, dynamic> json) => Place(
        id: json['id'] as int,
        name: json['name'] as String,
        admin1: json['admin1'] as String?,
        country: (json['country'] as String?) ?? '',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (admin1 != null) 'admin1': admin1,
        'country': country,
        'latitude': latitude,
        'longitude': longitude,
      };
}

class CurrentWeather {
  const CurrentWeather({
    required this.temperature,
    required this.apparentTemperature,
    required this.weatherCode,
    required this.isDay,
    required this.windSpeed,
    required this.humidity,
  });

  final double temperature;
  final double apparentTemperature;
  final int weatherCode;
  final bool isDay;
  final double windSpeed;
  final int humidity;
}

class HourlyForecast {
  const HourlyForecast({required this.time, required this.temperature, required this.weatherCode});

  final DateTime time;
  final double temperature;
  final int weatherCode;
}

class DailyForecast {
  const DailyForecast({required this.date, required this.weatherCode, required this.tempMax, required this.tempMin});

  final DateTime date;
  final int weatherCode;
  final double tempMax;
  final double tempMin;
}

class WeatherSnapshot {
  const WeatherSnapshot({required this.current, required this.hourly, required this.daily});

  final CurrentWeather current;
  final List<HourlyForecast> hourly;
  final List<DailyForecast> daily;
}

class WeatherCondition {
  const WeatherCondition(this.label, this.icon);

  final String label;
  final String icon;
}

const _conditions = <int, WeatherCondition>{
  0: WeatherCondition('Clear sky', '☀️'),
  1: WeatherCondition('Mainly clear', '🌤️'),
  2: WeatherCondition('Partly cloudy', '⛅'),
  3: WeatherCondition('Overcast', '☁️'),
  45: WeatherCondition('Fog', '🌫️'),
  48: WeatherCondition('Depositing rime fog', '🌫️'),
  51: WeatherCondition('Light drizzle', '🌦️'),
  53: WeatherCondition('Moderate drizzle', '🌦️'),
  55: WeatherCondition('Dense drizzle', '🌧️'),
  56: WeatherCondition('Light freezing drizzle', '🌧️'),
  57: WeatherCondition('Dense freezing drizzle', '🌧️'),
  61: WeatherCondition('Slight rain', '🌦️'),
  63: WeatherCondition('Moderate rain', '🌧️'),
  65: WeatherCondition('Heavy rain', '🌧️'),
  66: WeatherCondition('Light freezing rain', '🌧️'),
  67: WeatherCondition('Heavy freezing rain', '🌧️'),
  71: WeatherCondition('Slight snow fall', '🌨️'),
  73: WeatherCondition('Moderate snow fall', '🌨️'),
  75: WeatherCondition('Heavy snow fall', '❄️'),
  77: WeatherCondition('Snow grains', '❄️'),
  80: WeatherCondition('Slight rain showers', '🌦️'),
  81: WeatherCondition('Moderate rain showers', '🌧️'),
  82: WeatherCondition('Violent rain showers', '⛈️'),
  85: WeatherCondition('Slight snow showers', '🌨️'),
  86: WeatherCondition('Heavy snow showers', '❄️'),
  95: WeatherCondition('Thunderstorm', '⛈️'),
  96: WeatherCondition('Thunderstorm with slight hail', '⛈️'),
  99: WeatherCondition('Thunderstorm with heavy hail', '⛈️'),
};

/// Human-readable label and icon for an Open-Meteo (WMO) weather code.
WeatherCondition describeWeatherCode(int code) =>
    _conditions[code] ?? const WeatherCondition('Unknown', '❓');
