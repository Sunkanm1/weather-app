import 'dart:async';

import 'package:flutter/material.dart';

import '../models.dart';
import '../places_store.dart';
import '../weather_api.dart';

class AddPlaceScreen extends StatefulWidget {
  const AddPlaceScreen({super.key, required this.store, required this.api});

  final PlacesStore store;
  final WeatherApi api;

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  Timer? _debounce;
  String _query = '';
  bool _loading = false;
  String? _error;
  List<Place> _results = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value));
  }

  Future<void> _search(String query) async {
    _query = query;
    if (query.trim().length < 2) {
      setState(() {
        _results = const [];
        _error = null;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await widget.api.searchPlaces(query);
      if (!mounted || query != _query) return; // a newer search is running
      setState(() => _results = results);
    } catch (_) {
      if (!mounted || query != _query) return;
      setState(() => _error = 'Search failed. Check your connection and try again.');
    } finally {
      if (mounted && query == _query) setState(() => _loading = false);
    }
  }

  Future<void> _add(Place place) async {
    await widget.store.add(place);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Add a city')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              autofocus: true,
              onChanged: _onChanged,
              onSubmitted: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search for a city, e.g. Lagos',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _loading
                    ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ),
          if (!_loading && _error == null && _query.trim().length >= 2 && _results.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Text('No cities found.')),
          Expanded(
            child: ListenableBuilder(
              listenable: widget.store,
              builder: (context, _) => ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, i) {
                  final place = _results[i];
                  final saved = widget.store.contains(place);
                  return ListTile(
                    leading: const Icon(Icons.location_city_outlined),
                    title: Text(place.name),
                    subtitle: Text(place.subtitle),
                    trailing: saved ? const Icon(Icons.check) : const Icon(Icons.add),
                    enabled: !saved,
                    onTap: saved ? null : () => _add(place),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
