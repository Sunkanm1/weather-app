# Weather App

A Flutter weather app for Android and iOS. Save the cities you care about and see current conditions, the next 24 hours and a 7-day forecast for each one. Weather and city search come from the free [Open-Meteo](https://open-meteo.com) APIs, so no API key is needed.

## Features

- City search with debounced lookups against the Open-Meteo geocoding API
- Saved cities stored on the device (`shared_preferences`), with swipe to remove and undo
- Home list showing each city's current temperature and conditions, with pull to refresh
- Detail screen: temperature, feels like, humidity and wind, an hourly strip for the next 24 hours, and a 7-day forecast with a bar showing each day's range against the week
- Light and dark themes (Material 3)

## Structure

| File | What it does |
|---|---|
| `lib/weather_api.dart` | Open-Meteo client plus pure `parseForecast` / `parsePlaces` functions |
| `lib/places_store.dart` | Saved cities: load, add (no duplicates), remove, undo, persisted on device |
| `lib/models.dart` | Place, current/hourly/daily weather, weather code labels and icons |
| `lib/screens/` | Home list, add city search and city detail screens |

## Run

```bash
flutter pub get
flutter run          # on an Android or iOS device or simulator
flutter test         # parsing, storage and an end-to-end widget test with a fake API
```

An earlier version of this app was built in React Native (Expo); it's in the Git history.
