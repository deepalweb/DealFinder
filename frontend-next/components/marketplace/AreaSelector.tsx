"use client";
import { useRef, useState } from "react";
import { MapPin, LocateFixed, X } from "lucide-react";
import MapPicker from "@/components/ui/MapPicker";
import { useArea } from "@/contexts/AreaContext";
import { useLanguage } from "@/contexts/LanguageContext";
import { marketplaceCopy } from "@/lib/marketplace-copy";
import type { Area } from "@/lib/offer-display";
const presets: Area[] = [
  { label: "Colombo 03", latitude: 6.911, longitude: 79.854, radiusKm: 5 },
  { label: "Nugegoda", latitude: 6.865, longitude: 79.899, radiusKm: 5 },
  { label: "Rajagiriya", latitude: 6.91, longitude: 79.894, radiusKm: 5 },
  { label: "Dehiwala", latitude: 6.852, longitude: 79.865, radiusKm: 5 },
  { label: "Kandy", latitude: 7.29, longitude: 80.63, radiusKm: 5 },
];
export default function AreaSelector() {
  const { area, setArea } = useArea();
  const { language } = useLanguage();
  const c = marketplaceCopy[language];
  const dialog = useRef<HTMLDialogElement>(null);
  const [draft, setDraft] = useState<Area | null>(null);
  const [open, setOpen] = useState(false);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  function close() {
    dialog.current?.close();
    setOpen(false);
  }
  function locate() {
    if (!navigator.geolocation) {
      setError(c.locationDenied);
      return;
    }
    setBusy(true);
    navigator.geolocation.getCurrentPosition(
      ({ coords }) => {
        setDraft({
          label: c.useLocation,
          latitude: coords.latitude,
          longitude: coords.longitude,
          radiusKm: 5,
        });
        setBusy(false);
        setError("");
      },
      () => {
        setBusy(false);
        setError(c.locationDenied);
      },
      { timeout: 10000, enableHighAccuracy: false },
    );
  }
  return (
    <>
      <button
        className="mp-area"
        onClick={() => {
          setDraft(area);
          setError("");
          setOpen(true);
          dialog.current?.showModal();
        }}
      >
        <MapPin size={18} />
        <span>{area ? `${c.around} ${area.label}` : c.area}</span>
      </button>
      <dialog
        className="mp-dialog"
        ref={dialog}
        onCancel={() => setOpen(false)}
        onClose={() => setOpen(false)}
        aria-labelledby="area-title"
      >
        <div className="mp-dialog-heading">
          <h2 id="area-title">{c.changeArea}</h2>
          <button className="mp-icon" aria-label={c.close} onClick={close}>
            <X />
          </button>
        </div>
        <p className="mp-muted">{c.areaHint}</p>
        <div className="mp-chips">
          {presets.map((p) => (
            <button
              key={p.label}
              className="mp-chip"
              aria-pressed={draft?.label === p.label}
              onClick={() => setDraft(p)}
            >
              {p.label}
            </button>
          ))}
        </div>
        <button className="mp-button" disabled={busy} onClick={locate}>
          <LocateFixed size={18} />
          {c.useLocation}
        </button>
        {error && <p role="alert">{error}</p>}
        {open && (
          <MapPicker
            lat={draft?.latitude ?? null}
            lng={draft?.longitude ?? null}
            onChange={(latitude, longitude) =>
              setDraft({
                label: c.selectedPoint,
                latitude,
                longitude,
                radiusKm: draft?.radiusKm || 5,
              })
            }
            height="240px"
          />
        )}
        <label className="mp-field">
          {c.radius}
          <select
            value={draft?.radiusKm || 5}
            onChange={(e) => {
              if (draft)
                setDraft({ ...draft, radiusKm: Number(e.target.value) });
            }}
          >
            {[3, 5, 10, 20].map((n) => (
              <option value={n} key={n}>
                {n} km
              </option>
            ))}
          </select>
        </label>
        <div className="mp-chips">
          <button
            className="mp-button"
            onClick={() => {
              setArea(null);
              close();
            }}
          >
            {c.clear}
          </button>
          <button className="mp-button" onClick={close}>
            {c.cancel}
          </button>
          <button
            className="mp-button mp-primary"
            disabled={!draft}
            onClick={() => {
              setArea(draft);
              close();
            }}
          >
            {c.apply}
          </button>
        </div>
      </dialog>
    </>
  );
}
