import 'package:flutter/material.dart';

import '../models.dart';
import '../places_store.dart';
import '../weather_api.dart';
import 'add_place_screen.dart';
import 'place_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.store, required this.api});

  final PlacesStore store;
  final WeatherApi api;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Current weather per place id, refetched on pull-to-refresh.
  final _weather = <int, Future<WeatherSnapshot>>{};

  Future<WeatherSnapshot> _weatherFor(Place place) =>
      _weather.putIfAbsent(place.id, () => widget.api.fetchWeather(place));

  Future<void> _refresh() async {
    setState(_weather.clear);
    try {
      await Future.wait([for (final p in widget.store.places) _weatherFor(p)]);
    } catch (_) {
      // Each card shows its own error.
    }
  }

  void _openAdd() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AddPlaceScreen(store: widget.store, api: widget.api),
    ));
  }

  void _remove(Place place, int index) {
    widget.store.remove(place);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Removed ${place.name}'),
        action: SnackBarAction(label: 'Undo', onPressed: () => widget.store.insert(index, place)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weather')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Add city'),
      ),
      body: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) {
          final store = widget.store;
          if (!store.loaded) return const Center(child: CircularProgressIndicator());
          if (store.places.isEmpty) return _EmptyState(onAdd: _openAdd);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: store.places.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final place = store.places[i];
                return Dismissible(
                  key: ValueKey(place.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onErrorContainer),
                  ),
                  onDismissed: (_) => _remove(place, i),
                  child: _PlaceCard(
                    place: place,
                    weather: _weatherFor(place),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PlaceDetailScreen(place: place, api: widget.api),
                    )),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.place, required this.weather, required this.onTap});

  final Place place;
  final Future<WeatherSnapshot> weather;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<WeatherSnapshot>(
            future: weather,
            builder: (context, snapshot) {
              final w = snapshot.data?.current;
              final condition = w == null ? null : describeWeatherCode(w.weatherCode);
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(place.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                        Text(place.subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 6),
                        Text(
                          snapshot.hasError ? 'Could not load weather' : condition?.label ?? 'Loading…',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  if (w != null) ...[
                    Text(condition!.icon, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Text('${w.temperature.round()}°', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w300)),
                  ] else if (!snapshot.hasError)
                    const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌤️', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('No cities yet', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Add a city to see its current conditions and 7-day forecast.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.search), label: const Text('Find a city')),
          ],
        ),
      ),
    );
  }
}
