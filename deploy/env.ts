/** Non-empty env value, or fallback when unset/blank. */
export function envOrDefault(name: string, fallback: string): string {
  const value = process.env[name]?.trim();
  return value || fallback;
}

/** Parses an integer env var; falls back when unset, blank, or invalid. */
export function envIntOrDefault(
  name: string,
  fallback: number,
  options?: { min?: number; max?: number }
): number {
  const raw = process.env[name]?.trim();
  if (!raw) return fallback;
  const parsed = Number(raw);
  if (!Number.isInteger(parsed)) return fallback;
  if (options?.min !== undefined && parsed < options.min) return fallback;
  if (options?.max !== undefined && parsed > options.max) return fallback;
  return parsed;
}
