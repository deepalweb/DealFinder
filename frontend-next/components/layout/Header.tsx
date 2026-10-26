"use client";
import { useEffect, useState } from "react";
import Link from "next/link";
import { Search, Bookmark, User, Sun, Moon, X } from "lucide-react";
import { useAuth } from "@/contexts/AuthContext";
import { LANGUAGE_OPTIONS, useLanguage } from "@/contexts/LanguageContext";
import { DEALFINDER_CATEGORIES } from "@/lib/categories";
import { marketplaceCopy, categoryName } from "@/lib/marketplace-copy";
import AreaSelector from "@/components/marketplace/AreaSelector";
import NotificationBell from "@/components/ui/NotificationBell";
const categoryOrder = [
  "all",
  "food_dining",
  "daily_essentials",
  "shopping_retail",
  "electronics",
  "beauty_salon",
  "health_wellness",
  "entertainment_activities",
  "bank_cards",
];
const navigationCategories = categoryOrder.flatMap((id) =>
  DEALFINDER_CATEGORIES.filter((category) => category.id === id),
);
export default function Header() {
  const { user, logout } = useAuth();
  const { language, setLanguage } = useLanguage();
  const c = marketplaceCopy[language];
  const [query, setQuery] = useState("");
  const [dark, setDark] = useState(false);
  useEffect(() => {
    const value = localStorage.getItem("df-theme") === "dark";
    setDark(value);
    document.documentElement.dataset.theme = value ? "dark" : "light";
  }, []);
  function theme() {
    const value = !dark;
    setDark(value);
    localStorage.setItem("df-theme", value ? "dark" : "light");
    document.documentElement.dataset.theme = value ? "dark" : "light";
  }
  return (
    <>
      <div className="mp-utility">
        <div className="mp-shell">
          <Link href="/merchants">{c.stores}</Link>
          <Link href="/register">{c.merchants}</Link>
          <a
            href="https://drive.google.com/uc?export=download&id=12xY8BPO4HqN6oH4vj0wcJSwXiDM0tDKu"
            target="_blank"
            rel="noopener noreferrer"
          >
            {c.download}
          </a>
        </div>
      </div>
      <header className="mp-header">
        <div className="mp-shell mp-header-row">
          <Link className="mp-brand" href="/" aria-label="DealFinder">
            <span aria-hidden="true">%</span>DealFinder
          </Link>
          <form action="/categories/all" className="mp-search" role="search">
            <label className="sr-only" htmlFor="marketplace-search">
              {c.search}
            </label>
            <Search size={20} aria-hidden="true" />
            <input
              id="marketplace-search"
              name="q"
              placeholder={c.search}
              value={query}
              onChange={(e) => setQuery(e.target.value)}
            />
            {query && (
              <button
                type="button"
                className="mp-icon"
                aria-label={c.clear}
                onClick={() => setQuery("")}
              >
                <X size={18} />
              </button>
            )}
            <button
              className="mp-search-submit"
              type="submit"
              aria-label={c.searchAction}
            >
              <Search size={20} />
            </button>
          </form>
          <AreaSelector />
          <div className="mp-header-actions">
            <Link className="mp-icon" href="/favorites" aria-label={c.saved}>
              <Bookmark size={22} />
            </Link>
            {user && <NotificationBell />}
            <details className="mp-account">
              <summary className="mp-icon" aria-label={c.account}>
                <User size={22} />
              </summary>
              <div className="mp-menu">
                {user ? (
                  <>
                    <Link href="/profile">{c.account}</Link>
                    {user.role === "merchant" && (
                      <Link href="/merchant/dashboard">{c.workspace}</Link>
                    )}
                    {user.role === "admin" && (
                      <Link href="/admin/dashboard">{c.admin}</Link>
                    )}
                    <button onClick={() => logout()}>{c.signOut}</button>
                  </>
                ) : (
                  <Link href="/login">{c.signIn}</Link>
                )}
                <label>
                  {c.language}
                  <select
                    aria-label={c.language}
                    value={language}
                    onChange={(e) =>
                      setLanguage(e.target.value as "en" | "si" | "ta")
                    }
                  >
                    {LANGUAGE_OPTIONS.map((l) => (
                      <option value={l.code} key={l.code}>
                        {l.label}
                      </option>
                    ))}
                  </select>
                </label>
                <button onClick={theme}>
                  {dark ? <Sun size={18} /> : <Moon size={18} />} {c.theme}
                </button>
              </div>
            </details>
          </div>
        </div>
        <nav className="mp-category-nav mp-shell" aria-label={c.category}>
          {navigationCategories.map((cat) => (
            <Link href={`/categories/${cat.id}`} key={cat.id}>
              {cat.id === "all"
                ? c.all
                : categoryName(cat.id, language, cat.name)}
            </Link>
          ))}
          <Link href="/categories/all">{c.moreCategories}</Link>
        </nav>
      </header>
    </>
  );
}
