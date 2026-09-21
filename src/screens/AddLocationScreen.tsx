import React, { useEffect, useState } from 'react';
import {
  ActivityIndicator,
  FlatList,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { RootStackParamList } from '../../App';
import { searchLocations } from '../api/weather';
import { useLocations } from '../context/LocationsContext';
import type { GeocodingResult } from '../types';

type Props = NativeStackScreenProps<RootStackParamList, 'AddLocation'>;

export function AddLocationScreen({ navigation }: Props) {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<GeocodingResult[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const { addLocation } = useLocations();

  useEffect(() => {
    if (query.trim().length < 2) {
      setResults([]);
      return;
    }
    let cancelled = false;
    setIsLoading(true);
    const timeout = setTimeout(() => {
      searchLocations(query)
        .then((data) => {
          if (!cancelled) setResults(data);
        })
        .catch(() => {
          if (!cancelled) setResults([]);
        })
        .finally(() => {
          if (!cancelled) setIsLoading(false);
        });
    }, 350);
    return () => {
      cancelled = true;
      clearTimeout(timeout);
    };
  }, [query]);

  const handleSelect = (item: GeocodingResult) => {
    addLocation({
      id: String(item.id),
      name: item.name,
      admin1: item.admin1,
      country: item.country,
      latitude: item.latitude,
      longitude: item.longitude,
    });
    navigation.goBack();
  };

  return (
    <View style={styles.container}>
      <TextInput
        style={styles.input}
        placeholder="Search for a city…"
        value={query}
        onChangeText={setQuery}
        autoFocus
        autoCorrect={false}
      />
      {isLoading && <ActivityIndicator style={{ marginTop: 12 }} />}
      <FlatList
        data={results}
        keyExtractor={(item) => String(item.id)}
        renderItem={({ item }) => {
          const subtitle = [item.admin1, item.country].filter(Boolean).join(', ');
          return (
            <TouchableOpacity style={styles.result} onPress={() => handleSelect(item)}>
              <Text style={styles.resultName}>{item.name}</Text>
              {subtitle ? <Text style={styles.resultSubtitle}>{subtitle}</Text> : null}
            </TouchableOpacity>
          );
        }}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff', padding: 16 },
  input: {
    backgroundColor: '#f2f2f7',
    borderRadius: 12,
    paddingHorizontal: 14,
    paddingVertical: 12,
    fontSize: 16,
  },
  result: { paddingVertical: 12, borderBottomWidth: 1, borderBottomColor: '#eee' },
  resultName: { fontSize: 16, fontWeight: '500', color: '#1c1c1e' },
  resultSubtitle: { fontSize: 13, color: '#8e8e93', marginTop: 2 },
});
