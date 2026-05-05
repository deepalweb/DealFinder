const LOCAL_BACKEND_ORIGIN = 'http://localhost:8080';
const PRODUCTION_BACKEND_ORIGIN =
  'https://dealfinderapp.lk';

function isLocalHostname(hostname: string) {
  return hostname === 'localhost' || hostname === '127.0.0.1';
}

export function getBackendOrigin() {
  if (typeof window !== 'undefined') {
    return isLocalHostname(window.location.hostname)
      ? LOCAL_BACKEND_ORIGIN
      : (process.env.NEXT_PUBLIC_BACKEND_URL || PRODUCTION_BACKEND_ORIGIN);
  }

  return (
    process.env.BACKEND_URL ||
    process.env.NEXT_PUBLIC_BACKEND_URL ||
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
