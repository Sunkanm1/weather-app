export interface SavedLocation {
  id: string;
  name: string;
  admin1?: string;
  country: string;
  latitude: number;
  longitude: number;
}

export interface CurrentWeather {
  temperature: number;
  apparentTemperature: number;
  weatherCode: number;
  isDay: boolean;
  windSpeed: number;
  humidity: number;
}

export interface DailyForecastDay {
  date: string;
  weatherCode: number;
  tempMax: number;
  tempMin: number;
}

export interface HourlyForecastEntry {
  time: string;
  temperature: number;
  weatherCode: number;
}

export interface WeatherSnapshot {
  current: CurrentWeather;
  daily: DailyForecastDay[];
  hourly: HourlyForecastEntry[];
}

export interface GeocodingResult {
  id: number;
  name: string;
  admin1?: string;
  country: string;
  latitude: number;
  longitude: number;
}
