/* Epoch-day helpers, ported from the original app. A "dnum" is the integer
   number of days since the Unix epoch (UTC), which makes all timeline math
   plain integer arithmetic. */

export const DAY = 86_400_000;

export function dnum(iso: string): number {
  const p = String(iso).split("-");
  return Math.floor(Date.UTC(+p[0], +p[1] - 1, +p[2]) / DAY);
}

export function nstr(n: number): string {
  return new Date(n * DAY).toISOString().slice(0, 10);
}

export function weekday(n: number): number {
  // 0 = Monday
  return (new Date(n * DAY).getUTCDay() + 6) % 7;
}

export function mondayOnOrBefore(n: number): number {
  return n - weekday(n);
}

export function todayNum(): number {
  const d = new Date();
  return Math.floor(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()) / DAY);
}

export function firstOfMonth(n: number): number {
  const d = new Date(n * DAY);
  return Math.floor(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), 1) / DAY);
}

export function addMonths(n: number, k: number): number {
  const d = new Date(n * DAY);
  return Math.floor(Date.UTC(d.getUTCFullYear(), d.getUTCMonth() + k, 1) / DAY);
}

export function monthLabel(n: number): string {
  return new Date(n * DAY).toLocaleDateString(undefined, {
    month: "long",
    year: "numeric",
    timeZone: "UTC",
  });
}

export function clampProgress(p: number): number {
  const v = Math.round((Number(p) || 0) / 5) * 5;
  return v < 0 ? 0 : v > 100 ? 100 : v;
}

export function relTime(ms: number): string {
  if (!ms) return "";
  const diff = Date.now() - ms;
  const m = Math.round(diff / 60000);
  if (m < 1) return "just now";
  if (m < 60) return `${m}m ago`;
  const h = Math.round(m / 60);
  if (h < 24) return `${h}h ago`;
  const days = Math.round(h / 24);
  if (days < 7) return `${days}d ago`;
  return new Date(ms).toLocaleDateString(undefined, {
    month: "short",
    day: "numeric",
  });
}
