import React, { useEffect, useState } from 'react';
import { ActivityIndicator, StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import type { SavedLocation, WeatherSnapshot } from '../types';
import { describeWeatherCode, fetchWeather } from '../api/weather';

interface Props {
  location: SavedLocation;
  onPress: () => void;
}

export function LocationCard({ location, onPress }: Props) {
  const [weather, setWeather] = useState<WeatherSnapshot | null>(null);
  const [error, setError] = useState(false);

  useEffect(() => {
    let cancelled = false;
    fetchWeather(location.latitude, location.longitude)
      .then((data) => {
        if (!cancelled) setWeather(data);
      })
      .catch(() => {
        if (!cancelled) setError(true);
      });
    return () => {
      cancelled = true;
    };
  }, [location.latitude, location.longitude]);

  const subtitle = [location.admin1, location.country].filter(Boolean).join(', ');

  return (
    <TouchableOpacity style={styles.card} onPress={onPress} activeOpacity={0.7}>
      <View style={styles.left}>
        <Text style={styles.name}>{location.name}</Text>
        {subtitle ? <Text style={styles.subtitle}>{subtitle}</Text> : null}
      </View>
      <View style={styles.right}>
        {error ? (
          <Text style={styles.error}>—</Text>
        ) : weather ? (
          <>
            <Text style={styles.icon}>{describeWeatherCode(weather.current.weatherCode).icon}</Text>
            <Text style={styles.temp}>{Math.round(weather.current.temperature)}°</Text>
          </>
        ) : (
          <ActivityIndicator />
        )}
      </View>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  card: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: '#ffffff',
    borderRadius: 16,
    paddingVertical: 16,
    paddingHorizontal: 18,
    marginHorizontal: 16,
    marginVertical: 6,
    shadowColor: '#000',
    shadowOpacity: 0.05,
    shadowRadius: 6,
    shadowOffset: { width: 0, height: 2 },
    elevation: 2,
  },
  left: { flex: 1 },
  name: { fontSize: 18, fontWeight: '600', color: '#1c1c1e' },
  subtitle: { fontSize: 13, color: '#8e8e93', marginTop: 2 },
  right: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  icon: { fontSize: 24 },
  temp: { fontSize: 22, fontWeight: '600', color: '#1c1c1e', minWidth: 48, textAlign: 'right' },
  error: { color: '#ff3b30' },
});
