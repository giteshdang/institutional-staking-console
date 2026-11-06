const API_BASE = import.meta.env.VITE_API_BASE ?? "";
const API_KEY = import.meta.env.VITE_API_KEY ?? "demo-key";

type ApiErrorBody = {
  error?: string;
  details?: string | string[];
};

async function responseError(res: Response, method: string, path: string) {
  const body = (await res.json().catch(() => ({}))) as ApiErrorBody;
  const details = Array.isArray(body.details) ? body.details.join(", ") : body.details;
  const message = [body.error, details].filter(Boolean).join(": ");
  return new Error(message || `${method} ${path} failed: ${res.status}`);
}

export async function apiGet<T>(path: string): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, {
    headers: {
      "X-Api-Key": API_KEY,
      Accept: "application/json"
    }
  });
  if (!res.ok) {
    throw await responseError(res, "GET", path);
  }
  return res.json() as Promise<T>;
}

export async function apiPost<T>(path: string, body: unknown): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, {
    method: "POST",
    headers: {
      "X-Api-Key": API_KEY,
      Accept: "application/json",
      "Content-Type": "application/json"
    },
    body: JSON.stringify(body)
  });
  if (!res.ok) {
    throw await responseError(res, "POST", path);
  }
  return res.json() as Promise<T>;
}
