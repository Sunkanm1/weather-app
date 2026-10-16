import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// The user's saved places, persisted on the device.
class PlacesStore extends ChangeNotifier {
  static const _storageKey = 'weather-app:locations';

  List<Place> _places = [];
  bool _loaded = false;

  List<Place> get places => List.unmodifiable(_places);
  bool get loaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    try {
      _places = raw == null
          ? []
          : [for (final p in jsonDecode(raw) as List) Place.fromJson(p as Map<String, dynamic>)];
    } on FormatException {
      _places = [];
    }
    _loaded = true;
    notifyListeners();
  }

  bool contains(Place place) => _places.any((p) => p.id == place.id);

  /// Adds [place] unless it is already saved. Returns whether it was added.
  Future<bool> add(Place place) async {
    if (contains(place)) return false;
    _places = [..._places, place];
    notifyListeners();
    await _save();
    return true;
  }

  Future<void> remove(Place place) async {
    _places = _places.where((p) => p.id != place.id).toList();
    notifyListeners();
    await _save();
  }

  /// Puts [place] back at [index], e.g. after an undo.
  Future<void> insert(int index, Place place) async {
    if (contains(place)) return;
    _places = [..._places]..insert(index.clamp(0, _places.length), place);
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode([for (final p in _places) p.toJson()]));
  }
}
