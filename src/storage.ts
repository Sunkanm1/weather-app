import AsyncStorage from '@react-native-async-storage/async-storage';
import type { SavedLocation } from './types';

const STORAGE_KEY = 'weather-app:locations';

export async function loadLocations(): Promise<SavedLocation[]> {
  const raw = await AsyncStorage.getItem(STORAGE_KEY);
  if (!raw) return [];
  try {
    return JSON.parse(raw) as SavedLocation[];
  } catch {
    return [];
  }
}

export async function saveLocations(locations: SavedLocation[]): Promise<void> {
  await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(locations));
}
