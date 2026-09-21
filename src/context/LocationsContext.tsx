import React, { createContext, useContext, useEffect, useMemo, useState } from 'react';
import type { SavedLocation } from '../types';
import { loadLocations, saveLocations } from '../storage';

interface LocationsContextValue {
  locations: SavedLocation[];
  isLoading: boolean;
  addLocation: (location: SavedLocation) => void;
  removeLocation: (id: string) => void;
}

const LocationsContext = createContext<LocationsContextValue | undefined>(undefined);

export function LocationsProvider({ children }: { children: React.ReactNode }) {
  const [locations, setLocations] = useState<SavedLocation[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    loadLocations().then((stored) => {
      setLocations(stored);
      setIsLoading(false);
    });
  }, []);

  useEffect(() => {
    if (!isLoading) {
      saveLocations(locations);
    }
  }, [locations, isLoading]);

  const addLocation = (location: SavedLocation) => {
    setLocations((prev) => {
      if (prev.some((l) => l.id === location.id)) return prev;
      return [...prev, location];
    });
  };

  const removeLocation = (id: string) => {
    setLocations((prev) => prev.filter((l) => l.id !== id));
  };

  const value = useMemo(
    () => ({ locations, isLoading, addLocation, removeLocation }),
    [locations, isLoading]
  );

  return <LocationsContext.Provider value={value}>{children}</LocationsContext.Provider>;
}

export function useLocations(): LocationsContextValue {
  const ctx = useContext(LocationsContext);
  if (!ctx) throw new Error('useLocations must be used within a LocationsProvider');
  return ctx;
}
