import React, { useEffect, useLayoutEffect, useState } from 'react';
import { ActivityIndicator, ScrollView, StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { RootStackParamList } from '../../App';
import { describeWeatherCode, fetchWeather } from '../api/weather';
import { useLocations } from '../context/LocationsContext';
import type { WeatherSnapshot } from '../types';

type Props = NativeStackScreenProps<RootStackParamList, 'LocationDetail'>;

export function LocationDetailScreen({ route, navigation }: Props) {
  const { location } = route.params;
  const [weather, setWeather] = useState<WeatherSnapshot | null>(null);
  const [error, setError] = useState<string | null>(null);
  const { removeLocation } = useLocations();

  useLayoutEffect(() => {
    navigation.setOptions({ title: location.name });
  }, [navigation, location.name]);

  useEffect(() => {
    let cancelled = false;
    fetchWeather(location.latitude, location.longitude)
      .then((data) => {
        if (!cancelled) setWeather(data);
      })
      .catch(() => {
        if (!cancelled) setError('Could not load weather for this location.');
      });
    return () => {
      cancelled = true;
    };
  }, [location.latitude, location.longitude]);

  if (error) {
    return (
      <View style={styles.center}>
        <Text style={styles.errorText}>{error}</Text>
      </View>
    );
  }

  if (!weather) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" />
      </View>
    );
  }

  const { current, daily, hourly } = weather;
  const currentInfo = describeWeatherCode(current.weatherCode);

  return (
    <ScrollView style={styles.container} contentContainerStyle={{ paddingBottom: 32 }}>
      <View style={styles.currentBlock}>
        <Text style={styles.currentIcon}>{currentInfo.icon}</Text>
        <Text style={styles.currentTemp}>{Math.round(current.temperature)}°</Text>
        <Text style={styles.currentLabel}>{currentInfo.label}</Text>
        <Text style={styles.currentMeta}>
          Feels like {Math.round(current.apparentTemperature)}° · Humidity {current.humidity}% · Wind{' '}
          {Math.round(current.windSpeed)} km/h
        </Text>
      </View>

      <Text style={styles.sectionTitle}>Next 24 hours</Text>
      <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.hourlyRow}>
        {hourly.map((hour) => {
          const info = describeWeatherCode(hour.weatherCode);
          const hourLabel = new Date(hour.time).toLocaleTimeString([], { hour: 'numeric' });
          return (
            <View key={hour.time} style={styles.hourItem}>
              <Text style={styles.hourLabel}>{hourLabel}</Text>
              <Text style={styles.hourIcon}>{info.icon}</Text>
              <Text style={styles.hourTemp}>{Math.round(hour.temperature)}°</Text>
            </View>
          );
        })}
      </ScrollView>

      <Text style={styles.sectionTitle}>7-day forecast</Text>
      <View style={styles.dailyList}>
        {daily.map((day) => {
          const info = describeWeatherCode(day.weatherCode);
          const dayLabel = new Date(day.date).toLocaleDateString([], { weekday: 'short' });
          return (
            <View key={day.date} style={styles.dailyRow}>
              <Text style={styles.dailyDay}>{dayLabel}</Text>
              <Text style={styles.dailyIcon}>{info.icon}</Text>
              <Text style={styles.dailyTemp}>
                {Math.round(day.tempMin)}° / {Math.round(day.tempMax)}°
              </Text>
            </View>
          );
        })}
      </View>

      <TouchableOpacity
        style={styles.removeButton}
        onPress={() => {
          removeLocation(location.id);
          navigation.goBack();
        }}
      >
        <Text style={styles.removeButtonText}>Remove Location</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#f2f2f7' },
  center: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  errorText: { color: '#ff3b30', fontSize: 16 },
  currentBlock: { alignItems: 'center', paddingVertical: 32 },
  currentIcon: { fontSize: 56 },
  currentTemp: { fontSize: 56, fontWeight: '300', color: '#1c1c1e' },
  currentLabel: { fontSize: 18, color: '#1c1c1e', marginTop: 4 },
  currentMeta: { fontSize: 13, color: '#8e8e93', marginTop: 8, textAlign: 'center', paddingHorizontal: 24 },
  sectionTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#8e8e93',
    textTransform: 'uppercase',
    marginLeft: 16,
    marginTop: 8,
    marginBottom: 8,
  },
  hourlyRow: { paddingHorizontal: 12 },
  hourItem: {
    alignItems: 'center',
    backgroundColor: '#fff',
    borderRadius: 14,
    paddingVertical: 12,
    paddingHorizontal: 14,
    marginHorizontal: 4,
    minWidth: 64,
  },
  hourLabel: { fontSize: 12, color: '#8e8e93' },
  hourIcon: { fontSize: 22, marginVertical: 6 },
  hourTemp: { fontSize: 15, fontWeight: '600', color: '#1c1c1e' },
  dailyList: { backgroundColor: '#fff', marginHorizontal: 16, borderRadius: 14, overflow: 'hidden' },
  dailyRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#f2f2f7',
  },
  dailyDay: { fontSize: 15, fontWeight: '500', color: '#1c1c1e', width: 48 },
  dailyIcon: { fontSize: 20 },
  dailyTemp: { fontSize: 15, color: '#1c1c1e' },
  removeButton: { marginHorizontal: 16, marginTop: 24, paddingVertical: 14, alignItems: 'center' },
  removeButtonText: { color: '#ff3b30', fontSize: 16, fontWeight: '500' },
});
