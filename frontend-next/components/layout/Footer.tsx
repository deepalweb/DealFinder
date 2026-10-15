"use client";
import Link from "next/link";
import { useLanguage } from "@/contexts/LanguageContext";
import { marketplaceCopy } from "@/lib/marketplace-copy";
export default function Footer() {
  const { language } = useLanguage();
  const c = marketplaceCopy[language];
  return (
    <footer className="mp-footer">
      <div className="mp-shell">
        <div>
          <Link href="/" className="mp-brand">
            DealFinder
          </Link>
          <p>{c.footer}</p>
        </div>
        <nav aria-label={c.help}>
          <Link href="/about">{c.about}</Link>
          <Link href="/contact">{c.help}</Link>
          <Link href="/privacy">{c.privacy}</Link>
          <Link href="/register">{c.merchants}</Link>
          <a
            href="https://drive.google.com/uc?export=download&id=12xY8BPO4HqN6oH4vj0wcJSwXiDM0tDKu"
            target="_blank"
            rel="noopener noreferrer"
          >
            {c.download}
          </a>
        </nav>
      </div>
    </footer>
  );
}
