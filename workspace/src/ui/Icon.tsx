import type { ReactNode } from "react";

/* Inline SVG icon set, ported from the original app's ico() helper.
   Rendered as real JSX (no dangerouslySetInnerHTML anywhere in this app). */

const S = { stroke: "currentColor", fill: "none" } as const;

const PATHS: Record<string, ReactNode> = {
  timeline: (
    <path
      d="M3 6h13M3 12h9M3 18h15"
      {...S}
      strokeWidth={2}
      strokeLinecap="round"
    />
  ),
  calendar: (
    <>
      <rect x="3" y="4.5" width="14" height="13" rx="2" {...S} strokeWidth={1.7} />
      <path d="M3 8.5h14M7 3v3M13 3v3" {...S} strokeWidth={1.7} strokeLinecap="round" />
    </>
  ),
  book: (
    <path
      d="M4 4.5A1.5 1.5 0 0 1 5.5 3H16v12H5.5A1.5 1.5 0 0 0 4 16.5zM16 15v2H5.5A1.5 1.5 0 0 1 4 15.5"
      {...S}
      strokeWidth={1.6}
      strokeLinejoin="round"
    />
  ),
  chat: (
    <path
      d="M3 5.5A1.5 1.5 0 0 1 4.5 4h11A1.5 1.5 0 0 1 17 5.5v7A1.5 1.5 0 0 1 15.5 14H8l-4 3v-3H4.5A1.5 1.5 0 0 1 3 12.5z"
      {...S}
      strokeWidth={1.6}
      strokeLinejoin="round"
    />
  ),
  plus: <path d="M10 4v12M4 10h12" {...S} strokeWidth={2} strokeLinecap="round" />,
  x: <path d="M5 5l10 10M15 5L5 15" {...S} strokeWidth={2} strokeLinecap="round" />,
  check: (
    <path
      d="M4 10.5l4 4 8-9"
      {...S}
      strokeWidth={2}
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  ),
  chevL: (
    <path
      d="M12 4l-5 6 5 6"
      {...S}
      strokeWidth={2}
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  ),
  chevR: (
    <path
      d="M8 4l5 6-5 6"
      {...S}
      strokeWidth={2}
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  ),
  chevDown: (
    <path
      d="M4 8l6 5 6-5"
      {...S}
      strokeWidth={2}
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  ),
  eye: (
    <>
      <path d="M2 10s3-5 8-5 8 5 8 5-3 5-8 5-8-5-8-5z" {...S} strokeWidth={1.6} />
      <circle cx="10" cy="10" r="2.4" {...S} strokeWidth={1.6} />
    </>
  ),
  people: (
    <>
      <circle cx="7.5" cy="7" r="2.6" {...S} strokeWidth={1.6} />
      <path
        d="M3 16c0-2.5 2-4 4.5-4S12 13.5 12 16"
        {...S}
        strokeWidth={1.6}
        strokeLinecap="round"
      />
      <path
        d="M13 6.4a2.4 2.4 0 0 1 0 4.6M14.5 15.6c.3-2.2 1.4-2.9 2.5-3.2"
        {...S}
        strokeWidth={1.6}
        strokeLinecap="round"
      />
    </>
  ),
  note: (
    <>
      <path
        d="M5 3h7l4 4v10a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1z"
        {...S}
        strokeWidth={1.6}
        strokeLinejoin="round"
      />
      <path d="M12 3v4h4M7 11h6M7 14h4" {...S} strokeWidth={1.6} strokeLinecap="round" />
    </>
  ),
  dots: (
    <>
      <circle cx="5" cy="10" r="1.4" fill="currentColor" />
      <circle cx="10" cy="10" r="1.4" fill="currentColor" />
      <circle cx="15" cy="10" r="1.4" fill="currentColor" />
    </>
  ),
  grip: (
    <>
      {[5, 10, 15].flatMap((y) =>
        [7.5, 12.5].map((x) => (
          <circle key={`${x}-${y}`} cx={x} cy={y} r="1.3" fill="currentColor" />
        )),
      )}
    </>
  ),
  lock: (
    <>
      <rect x="4" y="9" width="12" height="9" rx="2" {...S} strokeWidth={1.8} />
      <path d="M7 9V7a3 3 0 0 1 6 0v2" {...S} strokeWidth={1.8} />
    </>
  ),
  hash: (
    <path
      d="M7 3l-1.5 14M14 3l-1.5 14M3.5 7.5h13M3 12.5h13"
      {...S}
      strokeWidth={1.7}
      strokeLinecap="round"
    />
  ),
  reply: (
    <path
      d="M8 5L3 9.5 8 14M3.5 9.5H12a4.5 4.5 0 0 1 4.5 4.5v1.5"
      {...S}
      strokeWidth={1.7}
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  ),
  smile: (
    <>
      <circle cx="10" cy="10" r="7.5" {...S} strokeWidth={1.6} />
      <path
        d="M7 8.5v.5M13 8.5v.5M6.8 12a4 4 0 0 0 6.4 0"
        {...S}
        strokeWidth={1.6}
        strokeLinecap="round"
      />
    </>
  ),
  download: (
    <path
      d="M10 3v10m0 0 4-4m-4 4-4-4M4 16h12"
      {...S}
      strokeWidth={1.8}
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  ),
  alert: (
    <>
      <path d="M8 2 1 15h14L8 2z" {...S} strokeWidth={1.6} strokeLinejoin="round" />
      <path d="M8 7v4M8 12.5v.5" {...S} strokeWidth={1.6} strokeLinecap="round" />
    </>
  ),
  logout: (
    <path
      d="M12 6V4a1 1 0 0 0-1-1H5a1 1 0 0 0-1 1v12a1 1 0 0 0 1 1h6a1 1 0 0 0 1-1v-2M9 10h8m0 0-3-3m3 3-3 3"
      {...S}
      strokeWidth={1.7}
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  ),
  sun: (
    <>
      <circle cx="10" cy="10" r="3.5" {...S} strokeWidth={1.7} />
      <path
        d="M10 2.5v2M10 15.5v2M2.5 10h2M15.5 10h2M4.7 4.7l1.4 1.4M13.9 13.9l1.4 1.4M15.3 4.7l-1.4 1.4M6.1 13.9l-1.4 1.4"
        {...S}
        strokeWidth={1.7}
        strokeLinecap="round"
      />
    </>
  ),
};

export type IconName = keyof typeof PATHS;

export function Icon({ name, size = 16 }: { name: IconName; size?: number }) {
  return (
    <svg
      viewBox={name === "alert" ? "0 0 16 17" : "0 0 20 20"}
      width={size}
      height={size}
      fill="none"
      aria-hidden="true"
    >
      {PATHS[name]}
    </svg>
  );
}
