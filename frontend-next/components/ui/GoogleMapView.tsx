/// <reference types="@types/google.maps" />
'use client';
import { useEffect, useRef, useState } from 'react';
import { loadGoogleMaps } from '@/lib/google-maps';

interface MapPoint {
  id: string; lat: number; lng: number; title: string; label?: string; href?: string;
}
interface Props {
  lat: number | null; lng: number | null;
  onChange?: (lat: number, lng: number) => void;
  points?: MapPoint[]; radiusKm?: number; height?: string;
}

export default function GoogleMapView({ lat, lng, onChange, points, radiusKm, height = '320px' }: Props) {
  const container = useRef<HTMLDivElement>(null);
  const map = useRef<google.maps.Map | null>(null);
  const change = useRef(onChange);
  useEffect(() => { change.current = onChange; }, [onChange]);
  const [ready, setReady] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    let disposed = false;
    let click: google.maps.MapsEventListener | undefined;
    const authFailure = () => setError('Google Maps authorization failed. Check the enabled API and website restrictions.');
    window.addEventListener('google-maps-auth-failure', authFailure);
    loadGoogleMaps().then(({ Map }) => {
      if (disposed || !container.current) return;
      map.current = new Map(container.current, {
        center: { lat: 6.9271, lng: 79.8612 }, zoom: 12,
        streetViewControl: false, mapTypeControl: false,
        fullscreenControl: true, gestureHandling: 'cooperative',
      });
      click = map.current.addListener('click', (event: google.maps.MapMouseEvent) => {
        if (event.latLng) change.current?.(event.latLng.lat(), event.latLng.lng());
      });
      setReady(true);
    }).catch(() => {
      if (!disposed) setError('Map unavailable. Check the map configuration or your connection.');
    });
    return () => {
      disposed = true;
      window.removeEventListener('google-maps-auth-failure', authFailure);
      click?.remove();
      if (map.current) google.maps.event.clearInstanceListeners(map.current);
      map.current = null;
    };
  }, []);

  useEffect(() => {
    if (!ready || !map.current) return;
    let disposed = false;
    const markers: google.maps.Marker[] = [];
    const listeners: google.maps.MapsEventListener[] = [];
    const info = new google.maps.InfoWindow();
    let circle: google.maps.Circle | undefined;
    const currentMap = map.current;
    loadGoogleMaps().then(async () => {
      const { Marker } = await google.maps.importLibrary('marker') as google.maps.MarkerLibrary;
      if (disposed) return;
      const bounds = new google.maps.LatLngBounds();
      if (lat !== null && lng !== null) {
        const position = { lat, lng };
        currentMap.setCenter(position);
        currentMap.setZoom(change.current ? 15 : 13);
        bounds.extend(position);
        const marker = new Marker({ map: currentMap, position,
          draggable: !!change.current, title: change.current ? 'Store location' : 'Selected location' });
        markers.push(marker);
        listeners.push(marker.addListener('dragend', (event: google.maps.MapMouseEvent) => {
          if (event.latLng) change.current?.(event.latLng.lat(), event.latLng.lng());
        }));
        if (radiusKm) circle = new google.maps.Circle({ map: currentMap, center: position,
          radius: radiusKm * 1000, strokeColor: '#2457E8', strokeWeight: 1,
          fillColor: '#2457E8', fillOpacity: 0.08 });
      }
      for (const point of points ?? []) {
        if (!Number.isFinite(point.lat) || !Number.isFinite(point.lng)) continue;
        const marker = new Marker({ map: currentMap, position: point, title: point.title,
          label: point.label ? { text: point.label, color: '#2457E8', fontWeight: '700' } : undefined });
        markers.push(marker);
        bounds.extend(point);
        listeners.push(marker.addListener('click', () => {
          const content = document.createElement('div');
          const title = document.createElement('strong');
          title.textContent = point.title;
          content.appendChild(title);
          if (point.href) {
            const link = document.createElement('a');
            link.textContent = 'View offer'; link.href = point.href;
            link.style.cssText = 'display:block;padding-top:8px;color:#2457E8';
            content.appendChild(link);
          }
          info.setContent(content);
          info.open({ map: currentMap, anchor: marker });
        }));
      }
      if ((points?.length ?? 0) > 0 && !bounds.isEmpty()) currentMap.fitBounds(bounds, 40);
    }).catch(() => { if (!disposed) setError('Map unavailable. Please try again later.'); });
    return () => {
      disposed = true;
      listeners.forEach(listener => listener.remove());
      markers.forEach(marker => marker.setMap(null));
      circle?.setMap(null); info.close();
    };
  }, [ready, lat, lng, points, radiusKm]);

  return <div style={{ position: 'relative', height, width: '100%', borderRadius: '0.75rem', overflow: 'hidden', border: '1.5px solid var(--border-color)' }}>
    <div ref={container} style={{ height: '100%', width: '100%' }} aria-label="Google map" />
    {!ready && !error && <p role="status" style={{ position: 'absolute', top: 16, left: 16 }}>Loading map…</p>}
    {error && <p role="alert" style={{ position: 'absolute', top: 16, left: 16, right: 16 }}>{error}</p>}
  </div>;
}
