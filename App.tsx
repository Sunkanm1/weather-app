import React from 'react';
import { StatusBar } from 'expo-status-bar';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { LocationsProvider } from './src/context/LocationsContext';
import { HomeScreen } from './src/screens/HomeScreen';
import { AddLocationScreen } from './src/screens/AddLocationScreen';
import { LocationDetailScreen } from './src/screens/LocationDetailScreen';
import type { SavedLocation } from './src/types';

export type RootStackParamList = {
  Home: undefined;
  AddLocation: undefined;
  LocationDetail: { location: SavedLocation };
};

const Stack = createNativeStackNavigator<RootStackParamList>();

export default function App() {
  return (
    <LocationsProvider>
      <NavigationContainer>
        <Stack.Navigator>
          <Stack.Screen name="Home" component={HomeScreen} options={{ title: 'Weather' }} />
          <Stack.Screen
            name="AddLocation"
            component={AddLocationScreen}
            options={{ title: 'Add Location', presentation: 'modal' }}
          />
          <Stack.Screen name="LocationDetail" component={LocationDetailScreen} options={{ title: '' }} />
        </Stack.Navigator>
      </NavigationContainer>
      <StatusBar style="auto" />
    </LocationsProvider>
  );
}
