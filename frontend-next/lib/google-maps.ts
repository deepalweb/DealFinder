/// <reference types="@types/google.maps" />
import { importLibrary, setOptions } from '@googlemaps/js-api-loader';

let loaded: Promise<google.maps.MapsLibrary> | undefined;
export function loadGoogleMaps() {
  if (!loaded) {
    const key = process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY;
    if (!key) return Promise.reject(new Error('Google Maps is not configured.'));
    const mapsWindow = window as typeof window & { gm_authFailure?: () => void };
    mapsWindow.gm_authFailure = () => window.dispatchEvent(new Event('google-maps-auth-failure'));
    setOptions({ key, v: 'weekly' });
    loaded = importLibrary('maps');
  }
  return loaded;
}
