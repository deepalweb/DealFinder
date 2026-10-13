'use client';
import GoogleMapView from './GoogleMapView';
interface Props {
 lat: number | null; lng: number | null;
 onChange: (lat: number, lng: number) => void; height?: string;
}
export default function MapPicker(props: Props) { return <GoogleMapView {...props} />; }
