import React from 'react';
import { FlatList, StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { RootStackParamList } from '../../App';
import { useLocations } from '../context/LocationsContext';
import { LocationCard } from '../components/LocationCard';

type Props = NativeStackScreenProps<RootStackParamList, 'Home'>;

export function HomeScreen({ navigation }: Props) {
  const { locations, isLoading } = useLocations();

  return (
    <View style={styles.container}>
      {!isLoading && locations.length === 0 ? (
        <View style={styles.empty}>
          <Text style={styles.emptyTitle}>No locations yet</Text>
          <Text style={styles.emptySubtitle}>Add a city to see its weather</Text>
        </View>
      ) : (
        <FlatList
          data={locations}
          keyExtractor={(item) => item.id}
          contentContainerStyle={{ paddingVertical: 12 }}
          renderItem={({ item }) => (
            <LocationCard
              location={item}
              onPress={() => navigation.navigate('LocationDetail', { location: item })}
            />
          )}
        />
      )}
      <TouchableOpacity
        style={styles.addButton}
        onPress={() => navigation.navigate('AddLocation')}
        activeOpacity={0.8}
      >
        <Text style={styles.addButtonText}>+ Add Location</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#f2f2f7' },
  empty: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  emptyTitle: { fontSize: 20, fontWeight: '600', color: '#1c1c1e' },
  emptySubtitle: { fontSize: 15, color: '#8e8e93', marginTop: 6 },
  addButton: {
    backgroundColor: '#007aff',
    marginHorizontal: 16,
    marginBottom: 16,
    marginTop: 8,
    paddingVertical: 14,
    borderRadius: 14,
    alignItems: 'center',
  },
  addButtonText: { color: '#fff', fontSize: 16, fontWeight: '600' },
});
