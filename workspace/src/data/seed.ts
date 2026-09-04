import type { Category, Channel, ResourceNode, Snapshot, Task } from "./types";
import { nstr, todayNum } from "@/lib/dates";

export const TEAM = [
  "Jaycie",
  "Abby",
  "Caroline",
  "Whitney",
  "Ava",
  "Sophia",
  "Erin",
  "Anna",
];

export const CATEGORIES: Category[] = [
  { id: "product", name: "Product", color: "#3E6B57" },
  { id: "brand", name: "Brand", color: "#9A7B4C" },
  { id: "content", name: "Content", color: "#C56B85" },
  { id: "events", name: "IRL Events", color: "#C67A54" },
  { id: "growth", name: "Growth", color: "#5B7C9E" },
  { id: "revenue", name: "Revenue", color: "#C0982F" },
  { id: "ops", name: "Ops", color: "#6E8790" },
  { id: "fundraising", name: "Fundraising", color: "#7B6CA8" },
];

function d(offsetDays: number): string {
  return nstr(todayNum() + offsetDays);
}

const SAMPLE_TASKS: Task[] = [
  {
    id: "seed-mvp",
    name: "Ship the Ralley MVP (pickup games + join)",
    owners: ["Jaycie"],
    categoryId: "product",
    start: d(0),
    end: d(35),
    progress: 20,
    milestone: false,
    notes: "Core loop: create a game, discover nearby, tap to join.",
    todos: [
      { id: "t1", text: "Auth + profile", done: true, tag: [] },
      { id: "t2", text: "Create-a-game flow", done: false, tag: ["Jaycie"] },
      { id: "t3", text: "Join + roster view", done: false, tag: [] },
    ],
    order: 0,
  },
  {
    id: "seed-style",
    name: "Brand style guide v1",
    owners: ["Caroline"],
    categoryId: "brand",
    start: d(-3),
    end: d(12),
    progress: 55,
    milestone: false,
    notes: "Logo lockups, colour, type (Chillax / DM Sans), voice.",
    todos: [],
    order: 1,
  },
  {
    id: "seed-launch",
    name: "Dallas launch event",
    owners: ["Abby", "Whitney"],
    categoryId: "events",
    start: d(40),
    end: d(40),
    progress: 0,
    milestone: true,
    notes: "Second IRL event — venue + run of show.",
    todos: [],
    order: 2,
  },
  {
    id: "seed-content",
    name: '"Why I Came Back" video series',
    owners: ["Sophia", "Erin"],
    categoryId: "content",
    start: d(5),
    end: d(26),
    progress: 10,
    milestone: false,
    notes: "3–4 posts/week cadence; pillar content.",
    todos: [],
    order: 3,
  },
  {
    id: "seed-grant",
    name: "Bucknell PGCEI application ($2K)",
    owners: ["Jaycie"],
    categoryId: "fundraising",
    start: d(2),
    end: d(9),
    progress: 0,
    milestone: false,
    notes: "",
    todos: [],
    order: 4,
  },
];

function starterPages(): ResourceNode[] {
  const pages: ResourceNode[] = [
    {
      id: "start-here",
      parentId: null,
      categoryId: "",
      title: "Start here",
      pinned: true,
      order: 0,
      body: [
        "# Club Ralley — start here",
        "",
        "**Ralley** is a mobile app + IRL movement for athletes to find pickup games,",
        "teammates and community in a new city. _The game's not over. Your story isn't done._",
        "",
        "## How this workspace is organised",
        "- **Roadmap** — every project we're running, on a timeline + calendar.",
        "- **Resources** — this wiki. Top level mirrors the roadmap categories.",
        "- **Chat** — channels, threads, DMs. Tag a task or page into any message.",
        "",
        "## Founders",
        "Jaycie · Abby · Caroline · Whitney",
      ].join("\n"),
    },
    {
      id: "team-notes",
      parentId: null,
      categoryId: "",
      title: "Team notes",
      pinned: true,
      order: 1,
      body: "Shared scratchpad — decisions, standing info, links to move somewhere better later.",
    },
  ];

  const perCategory: Record<string, string> = {
    product: "Roadmap link, tech stack, TestFlight builds, bug list, feature specs.",
    brand: "Logo files · colours (#2C4F40, #E2E4D6) · fonts (Chillax, DM Sans) · voice · templates.",
    content:
      "Content pillars: The Comeback / Game Day / The Locker Room / Beyond the Court.\nCadence: 3–4×/week. Content calendar link goes here.",
    events: "Run-of-show template, venue list, vendor contacts, budgets, post-event recap format.",
    growth: "Target cities, referral loops, campus reps, app-store keywords, analytics dashboards.",
    revenue: "Pricing: Player free / Captain $10 / Club $30. Partnerships, sponsorship deck.",
    ops: "Tools & accounts (Supabase, Netlify, Figma, Squarespace, App Store Connect). Who owns what.",
    fundraising:
      "Bucknell PGCEI ($2K) · Bizpitch ($5K) · investor list · data room checklist.",
  };

  CATEGORIES.forEach((c, i) => {
    pages.push({
      id: `page-${c.id}`,
      parentId: null,
      categoryId: c.id,
      title: "Overview",
      order: 0,
      body: `# ${c.name}\n\n${perCategory[c.id] ?? ""}`,
    });
    void i;
  });

  return pages;
}

const CHANNELS: Channel[] = [
  { id: "general", name: "general", kind: "chat", order: 0 },
  { id: "product", name: "product", kind: "chat", order: 1 },
  { id: "brand", name: "brand", kind: "chat", order: 2 },
  { id: "events", name: "events", kind: "chat", order: 3 },
  { id: "activity", name: "activity", kind: "activity", order: 99 },
];

export function makeSeed(): Snapshot {
  return {
    settings: {
      title: "Club Ralley",
      subtitle: "Build the app. Grow the movement. we back.",
      gatehash: btoa("ralley"),
      zoom: "weeks",
    },
    members: [
      { name: "Anna", color: "#C0453B" },
      { name: "Jaycie", color: "#D46A9A" },
      ...TEAM.filter((n) => n !== "Anna" && n !== "Jaycie").map((name) => ({
        name,
        color: "",
      })),
    ],
    categories: CATEGORIES,
    tasks: SAMPLE_TASKS,
    resources: starterPages(),
    channels: CHANNELS,
    messages: [],
    activity: [],
  };
}
