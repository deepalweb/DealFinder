/// <reference types="@types/google.maps" />
import { importLibrary, setOptions } from '@googlemaps/js-api-loader';
import { buildApiUrl } from '@/lib/config/api';

let loaded: Promise<google.maps.MapsLibrary> | undefined;

async function load() {
  const res = await fetch(buildApiUrl('config'));
  if (!res.ok) throw new Error('Could not load the Google Maps configuration.');
  const { GOOGLE_MAPS_API_KEY: key } = await res.json();
  if (!key) throw new Error('Google Maps is not configured.');
  const mapsWindow = window as typeof window & { gm_authFailure?: () => void };
  mapsWindow.gm_authFailure = () => window.dispatchEvent(new Event('google-maps-auth-failure'));
  setOptions({ key, v: 'weekly' });
  return importLibrary('maps');
}

export function loadGoogleMaps() {
  // Clear a failed attempt so the next map can retry after a network error.
  loaded ??= load().catch((error) => {
    loaded = undefined;
    throw error;
  });
  return loaded;
}
