"use client";
import {
  Children,
  cloneElement,
  isValidElement,
  useEffect,
  useId,
  useRef,
  useState,
  type ReactNode,
  type ReactElement,
} from "react";
import Link from "next/link";
import { ArrowLeft, Store, ImagePlus, RotateCcw } from "lucide-react";
import { useLanguage } from "@/contexts/LanguageContext";
import { merchantCopy } from "@/lib/merchant-copy";
import { ImageAPI } from "@/lib/api";
import OfferImage from "@/components/marketplace/OfferImage";
export function MerchantShell({
  title,
  subtitle,
  children,
  actions,
}: {
  title: string;
  subtitle?: string;
  children: ReactNode;
  actions?: ReactNode;
}) {
  const { language } = useLanguage();
  const c = merchantCopy[language];
  return (
    <div className="mw-shell">
      <Link className="mw-back" href="/merchant/dashboard">
        <ArrowLeft size={18} />
        {c.back}
      </Link>
      <header className="mw-heading">
        <div>
          <span className="mw-eyebrow">
            <Store size={16} />
            {c.workspace}
          </span>
          <h1>{title}</h1>
          {subtitle && <p>{subtitle}</p>}
        </div>
        {actions && <div className="mw-actions">{actions}</div>}
      </header>
      {children}
    </div>
  );
}
export function Field({
  label,
  id,
  required,
  hint,
  error,
  children,
}: {
  label: string;
  id: string;
  required?: boolean;
  hint?: string;
  error?: string;
  children: ReactNode;
}) {
  return (
    <div className="mw-field">
      <label htmlFor={id}>
        {label}
        {required && <span aria-hidden="true"> *</span>}
      </label>
      {Children.map(children, (child) =>
        isValidElement(child)
          ? cloneElement(child as ReactElement<Record<string, unknown>>, {
              id,
              "aria-required": required || undefined,
              "aria-invalid": !!error,
              "aria-describedby": error
                ? `${id}-error`
                : hint
                  ? `${id}-hint`
                  : undefined,
            })
          : child,
      )}
      {hint && <p id={`${id}-hint`}>{hint}</p>}
      {error && (
        <p className="mw-error" id={`${id}-error`}>
          {error}
        </p>
      )}
    </div>
  );
}
export function Errors({
  errors,
  labels,
  onFocus,
}: {
  errors: Record<string, string>;
  labels: Record<string, string>;
  onFocus?: (key: string) => void;
}) {
  const { language } = useLanguage();
  const c = merchantCopy[language];
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (Object.keys(errors).length) ref.current?.focus();
  }, [errors]);
  if (!Object.keys(errors).length) return null;
  return (
    <div role="alert" tabIndex={-1} ref={ref} className="mw-error-summary">
      <strong>{c.fix}</strong>
      <ul>
        {Object.entries(errors).map(([key, error]) => (
          <li key={key}>
            <button
              type="button"
              onClick={() => {
                onFocus?.(key);
                setTimeout(() => {
                  const element = document.getElementById(key);
                  const details = element?.closest("details");
                  if (details) details.open = true;
                  element?.focus({ preventScroll: true });
                  element?.scrollIntoView({
                    block: "center",
                    behavior: "instant",
                  });
                }, 0);
              }}
            >
              {labels[key] || key}: {error}
            </button>
          </li>
        ))}
      </ul>
    </div>
  );
}
export function ImageUpload({
  images,
  onChange,
  max = 5,
  onBusy,
}: {
  images: string[];
  onChange: (images: string[]) => void;
  max?: number;
  onBusy?: (busy: boolean) => void;
}) {
  const { language } = useLanguage();
  const c = merchantCopy[language];
  const id = useId();
  const [file, setFile] = useState<File | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  async function upload(f: File) {
    setFile(f);
    setError("");
    if (
      f.size > 20 * 1024 * 1024 ||
      !/\.(jpe?g|png|gif|webp|heic|heif)$/i.test(f.name)
    ) {
      setError(c.imageHint);
      return;
    }
    setBusy(true);
    onBusy?.(true);
    try {
      const url = await ImageAPI.uploadSingle(f, "promotions");
      onChange([...images, url]);
      setFile(null);
    } catch (e) {
      setError(e instanceof Error ? e.message : c.saveError);
    } finally {
      setBusy(false);
      onBusy?.(false);
    }
  }
  return (
    <div className="mw-upload">
      <p className="mw-muted">{max === 1 ? c.singleImageHint : c.imageHint}</p>
      <div className="mw-gallery">
        {images.map((url, i) => (
          <div key={`${url}-${i}`}>
            <div className="mw-image">
              <OfferImage
                src={url}
                alt={`${c.images} ${i + 1}`}
                sizes="160px"
              />
            </div>
            <div className="mw-image-actions">
              <button
                type="button"
                disabled={busy || i === 0}
                onClick={() =>
                  onChange([url, ...images.filter((_, j) => j !== i)])
                }
              >
                {i === 0 ? c.cover : c.cover}
              </button>
              <button
                type="button"
                disabled={busy}
                onClick={() => onChange(images.filter((_, j) => j !== i))}
              >
                {c.remove}
              </button>
            </div>
          </div>
        ))}
      </div>
      {images.length < max && (
        <>
          <label className="mw-button mw-secondary" htmlFor={id}>
            <ImagePlus size={18} />
            {busy ? c.uploading : c.upload}
          </label>
          <input
            className="mw-file"
            id={id}
            type="file"
            disabled={busy}
            accept=".jpg,.jpeg,.png,.gif,.webp,.heic,.heif"
            onChange={(e) => {
              const f = e.target.files?.[0];
              if (f) void upload(f);
              e.target.value = "";
            }}
          />
        </>
      )}
      {busy && <p role="status">{c.uploading}</p>}
      {error && (
        <div role="alert" className="mw-error">
          <p>{error}</p>
          {file && (
            <button
              className="mw-button mw-secondary"
              type="button"
              onClick={() => void upload(file)}
            >
              <RotateCcw size={16} />
              {c.retry}
            </button>
          )}
        </div>
      )}
    </div>
  );
}
export function useUnsaved(dirty: boolean) {
  useEffect(() => {
    const fn = (e: BeforeUnloadEvent) => {
      if (dirty) {
        e.preventDefault();
        e.returnValue = "";
      }
    };
    window.addEventListener("beforeunload", fn);
    return () => window.removeEventListener("beforeunload", fn);
  }, [dirty]);
  useEffect(() => {
    const fn = (e: MouseEvent) => {
      const link = (e.target as HTMLElement)?.closest("a");
      if (
        dirty &&
        link &&
        link.href !== window.location.href &&
        !window.confirm(
          merchantCopy[
            document.documentElement.lang === "si"
              ? "si"
              : document.documentElement.lang === "ta"
                ? "ta"
                : "en"
          ].discard,
        )
      ) {
        e.preventDefault();
        e.stopPropagation();
      }
    };
    document.addEventListener("click", fn, true);
    return () => document.removeEventListener("click", fn, true);
  }, [dirty]);
}
