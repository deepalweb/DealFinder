const LOCAL_BACKEND_ORIGIN = 'http://localhost:8080';
const PRODUCTION_BACKEND_ORIGIN =
  'https://dealfinderlk-eafsbyd7ghaph0az.southindia-01.azurewebsites.net';

function normalizeOrigin(value?: string | null) {
  return value?.trim().replace(/\/+$/, '') || null;
}

function isLocalHostname(hostname: string) {
  return hostname === 'localhost' || hostname === '127.0.0.1';
}

export function getBackendOrigin() {
  const publicBackendOrigin =
    normalizeOrigin(process.env.NEXT_PUBLIC_API_BASE) ||
    normalizeOrigin(process.env.NEXT_PUBLIC_BACKEND_URL);

  if (typeof window !== 'undefined') {
    return isLocalHostname(window.location.hostname)
      ? LOCAL_BACKEND_ORIGIN
      : (publicBackendOrigin || PRODUCTION_BACKEND_ORIGIN);
  }

  return (
    normalizeOrigin(process.env.BACKEND_URL) ||
    publicBackendOrigin ||
    (process.env.NODE_ENV === 'development'
      ? LOCAL_BACKEND_ORIGIN
      : PRODUCTION_BACKEND_ORIGIN)
  );
}

export function getApiBase() {
  return `${getBackendOrigin()}/api`;
}

export function buildApiUrl(path: string) {
  return `${getApiBase()}/${path.replace(/^\/+/, '')}`;
}
