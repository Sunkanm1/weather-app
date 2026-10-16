import 'package:flutter/material.dart';

import '../models.dart';
import '../weather_api.dart';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class PlaceDetailScreen extends StatefulWidget {
  const PlaceDetailScreen({super.key, required this.place, required this.api});

  final Place place;
  final WeatherApi api;

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  late Future<WeatherSnapshot> _weather = widget.api.fetchWeather(widget.place);

  void _retry() => setState(() => _weather = widget.api.fetchWeather(widget.place));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.place.name)),
      body: FutureBuilder<WeatherSnapshot>(
        future: _weather,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not load the weather.'),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _retry, child: const Text('Try again')),
                ],
              ),
            );
          }
          final w = snapshot.data;
          if (w == null) return const Center(child: CircularProgressIndicator());

          return RefreshIndicator(
            onRefresh: () async {
              _retry();
              await _weather;
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _CurrentPanel(place: widget.place, current: w.current),
                const SizedBox(height: 20),
                _SectionTitle('Next 24 hours'),
                SizedBox(
                  height: 104,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: w.hourly.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => _HourTile(hour: w.hourly[i], isNow: i == 0),
                  ),
                ),
                const SizedBox(height: 20),
                _SectionTitle('7-day forecast'),
                Card(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < w.daily.length; i++)
                        _DayRow(
                          day: w.daily[i],
                          label: i == 0 ? 'Today' : _weekdays[w.daily[i].date.weekday - 1],
                          weekMin: w.daily.map((d) => d.tempMin).reduce((a, b) => a < b ? a : b),
                          weekMax: w.daily.map((d) => d.tempMax).reduce((a, b) => a > b ? a : b),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      );
}

class _CurrentPanel extends StatelessWidget {
  const _CurrentPanel({required this.place, required this.current});

  final Place place;
  final CurrentWeather current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final condition = describeWeatherCode(current.weatherCode);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: current.isDay
              ? [scheme.primaryContainer, scheme.secondaryContainer]
              : [scheme.surfaceContainerHighest, scheme.tertiaryContainer],
        ),
      ),
      child: Column(
        children: [
          Text(place.subtitle, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(condition.icon, style: const TextStyle(fontSize: 64)),
          Text('${current.temperature.round()}°', style: theme.textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w300)),
          Text(condition.label, style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Stat(icon: Icons.thermostat, label: 'Feels like', value: '${current.apparentTemperature.round()}°'),
              _Stat(icon: Icons.water_drop_outlined, label: 'Humidity', value: '${current.humidity}%'),
              _Stat(icon: Icons.air, label: 'Wind', value: '${current.windSpeed.round()} km/h'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 20),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

class _HourTile extends StatelessWidget {
  const _HourTile({required this.hour, required this.isNow});

  final HourlyForecast hour;
  final bool isNow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isNow ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(isNow ? 'Now' : '${hour.time.hour.toString().padLeft(2, '0')}:00', style: theme.textTheme.labelMedium),
          Text(describeWeatherCode(hour.weatherCode).icon, style: const TextStyle(fontSize: 22)),
          Text('${hour.temperature.round()}°', style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day, required this.label, required this.weekMin, required this.weekMax});

  final DailyForecast day;
  final String label;
  final double weekMin;
  final double weekMax;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final span = (weekMax - weekMin).abs() < 0.1 ? 1.0 : weekMax - weekMin;
    final start = (day.tempMin - weekMin) / span;
    final end = (day.tempMax - weekMin) / span;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 56, child: Text(label, style: theme.textTheme.bodyLarge)),
          Text(describeWeatherCode(day.weatherCode).icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          SizedBox(width: 36, child: Text('${day.tempMin.round()}°', textAlign: TextAlign.right, style: TextStyle(color: theme.colorScheme.onSurfaceVariant))),
          const SizedBox(width: 10),
          // Bar showing where this day's range sits within the week's range.
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => Container(
                height: 6,
                decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(3)),
                child: Stack(
                  children: [
                    Positioned(
                      left: constraints.maxWidth * start,
                      width: (constraints.maxWidth * (end - start)).clamp(6, constraints.maxWidth),
                      top: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF38BDF8), Color(0xFFF59E0B)]),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(width: 36, child: Text('${day.tempMax.round()}°', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
