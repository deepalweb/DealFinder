"use client";
import { createContext, useContext, useEffect, useState, useRef } from "react";
import { useAuth } from "./AuthContext";
import { UserAPI } from "@/lib/api";
import toast from "react-hot-toast";
import { useLanguage } from "./LanguageContext";
import { marketplaceCopy } from "@/lib/marketplace-copy";
type Saved = {
  ids: Set<string>;
  ready: boolean;
  setSaved: (id: string, value: boolean) => Promise<void>;
};
const Context = createContext<Saved>({
  ids: new Set(),
  ready: false,
  setSaved: async () => {},
});
export function SavedOffersProvider({
  children,
}: {
  children: React.ReactNode;
}) {
  const { user } = useAuth();
  const { language } = useLanguage();
  const copy = marketplaceCopy[language];
  const userId = user?._id;
  const [ids, setIds] = useState<Set<string>>(new Set());
  const [ready, setReady] = useState(false);
  const generation = useRef(0);
  const [statusError, setStatusError] = useState(false);
  const [retry, setRetry] = useState(0);
  useEffect(() => {
    generation.current++;
    setIds(new Set());
    setReady(false);
    setStatusError(false);
    if (!userId) {
      setReady(true);
      return;
    }
    let cancelled = false;
    UserAPI.getFavorites(userId)
      .then(async (rows) => {
        if (cancelled) return;
        const values = new Set<string>(rows.map((p) => String(p._id || p.id)));
        setIds(values);
        try {
          const pending = JSON.parse(
            sessionStorage.getItem("df-pending-save") || "null",
          );
          if (pending?.id && pending.userId === null) {
            sessionStorage.removeItem("df-pending-save");
            if (!values.has(pending.id)) {
              await UserAPI.addFavorite(userId, pending.id);
              if (!cancelled) {
                setIds((prev) => new Set([...prev, pending.id]));
                toast.success(copy.savedSuccess);
              }
            }
          }
        } catch {
          toast.error(copy.saveFailed);
        }
        if (!cancelled) setReady(true);
      })
      .catch(() => {
        if (!cancelled) {
          setStatusError(true);
        }
      });
    return () => {
      cancelled = true;
    };
  }, [userId, retry, copy.saveFailed, copy.savedSuccess]);
  async function setSaved(id: string, value: boolean) {
    if (!user) throw new Error("Sign in required");
    const current = generation.current;
    if (value) await UserAPI.addFavorite(user._id, id);
    else await UserAPI.removeFavorite(user._id, id);
    if (current === generation.current)
      setIds((prev) => {
        const next = new Set(prev);
        if (value) next.add(id);
        else next.delete(id);
        return next;
      });
  }
  return (
    <Context.Provider value={{ ids, ready, setSaved }}>
      {statusError && (
        <div role="alert" className="mp-state">
          <p>{copy.savedStatus}</p>
          <button className="mp-button" onClick={() => setRetry(retry + 1)}>
            {copy.retry}
          </button>
        </div>
      )}
      {children}
    </Context.Provider>
  );
}
export const useSavedOffers = () => useContext(Context);
