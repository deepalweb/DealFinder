'use client';

import { useEffect, useRef } from 'react';

interface Props {
  lat: number | null;
  lng: number | null;
  onChange: (lat: number, lng: number) => void;
  height?: string;
}

export default function MapPicker({ lat, lng, onChange, height = '320px' }: Props) {
  const mapRef = useRef<any>(null);
  const markerRef = useRef<any>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (typeof window === 'undefined' || !containerRef.current) return;

    import('leaflet').then(L => {
      // Fix default icon paths
      delete (L.Icon.Default.prototype as any)._getIconUrl;
      L.Icon.Default.mergeOptions({
        iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
        iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
        shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
      });

      if (mapRef.current) return; // already initialized

      const defaultLat = lat ?? 6.9271;
      const defaultLng = lng ?? 79.8612;

      const map = L.map(containerRef.current!).setView([defaultLat, defaultLng], lat ? 15 : 12);
      mapRef.current = map;

      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap contributors',
      }).addTo(map);

      if (lat && lng) {
        markerRef.current = L.marker([lat, lng], { draggable: true }).addTo(map);
        markerRef.current.on('dragend', (e: any) => {
          const pos = e.target.getLatLng();
          onChange(pos.lat, pos.lng);
        });
      }

      map.on('click', (e: any) => {
        const { lat: clickLat, lng: clickLng } = e.latlng;
        if (markerRef.current) {
          markerRef.current.setLatLng([clickLat, clickLng]);
        } else {
          markerRef.current = L.marker([clickLat, clickLng], { draggable: true }).addTo(map);
          markerRef.current.on('dragend', (ev: any) => {
            const pos = ev.target.getLatLng();
            onChange(pos.lat, pos.lng);
          });
        }
        onChange(clickLat, clickLng);
      });
    });

    return () => {
      if (mapRef.current) {
        mapRef.current.remove();
        mapRef.current = null;
        markerRef.current = null;
      }
    };
  }, []);

  // Update marker when lat/lng props change externally
  useEffect(() => {
    if (!mapRef.current || lat === null || lng === null) return;
    import('leaflet').then(L => {
      if (markerRef.current) {
        markerRef.current.setLatLng([lat, lng]);
      } else {
        markerRef.current = L.marker([lat, lng], { draggable: true }).addTo(mapRef.current);
        markerRef.current.on('dragend', (e: any) => {
          const pos = e.target.getLatLng();
          onChange(pos.lat, pos.lng);
        });
      }
      mapRef.current.setView([lat, lng], 15);
    });
  }, [lat, lng]);

  return (
    <>
      <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
      <div ref={containerRef} style={{ height, width: '100%', borderRadius: '0.75rem', overflow: 'hidden', border: '1.5px solid var(--border-color)' }} />
    </>
  );
}
