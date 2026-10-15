"use client";
import { createContext, useContext, useEffect, useState } from "react";
import type { Area } from "@/lib/offer-display";
const Context = createContext<{
  area: Area | null;
  setArea: (area: Area | null) => void;
}>({ area: null, setArea: () => {} });
export function AreaProvider({ children }: { children: React.ReactNode }) {
  const [area, setValue] = useState<Area | null>(null);
  useEffect(() => {
    try {
      const stored = JSON.parse(
        localStorage.getItem("df-browsing-area") || "null",
      );
      if (
        stored &&
        typeof stored.label === "string" &&
        Number.isFinite(stored.latitude) &&
        Number.isFinite(stored.longitude) &&
        Math.abs(stored.latitude) <= 90 &&
        Math.abs(stored.longitude) <= 180 &&
        Number.isFinite(stored.radiusKm) &&
        stored.radiusKm > 0
      )
        setValue(stored);
    } catch {}
  }, []);
  function setArea(value: Area | null) {
    setValue(value);
    try {
      localStorage.setItem("df-browsing-area", JSON.stringify(value));
    } catch {}
  }
  return (
    <Context.Provider value={{ area, setArea }}>{children}</Context.Provider>
  );
}
export const useArea = () => useContext(Context);
