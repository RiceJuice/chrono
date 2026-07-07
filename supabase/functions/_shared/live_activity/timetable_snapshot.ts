import type { ProfileRow, TimetableSegment, TimetableSnapshot } from "./types.ts";
import { PRE_START_MINUTES, SCHEDULE_TIMEZONE } from "./types.ts";

type CalendarRow = {
  id: string;
  event_name: string | null;
  type: string | null;
  start_time: string;
  end_time: string | null;
  class: string | null;
  schooltrack: string | null;
  image_paths: string | null;
};

function berlinOffsetForDay(dayKey: string): string {
  // Sommer-/Winterzeit (CEST/CET) via echtem TZ-Lookup statt fest verdrahtetem
  // Offset, da ein hartes "+01:00" im Sommer (CEST=+02:00) die Tagesgrenzen um
  // eine Stunde verschiebt.
  const probe = new Date(`${dayKey}T12:00:00Z`);
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone: SCHEDULE_TIMEZONE,
    timeZoneName: "shortOffset",
  }).formatToParts(probe);
  const tzPart = parts.find((p) => p.type === "timeZoneName")?.value ?? "GMT+1";
  const match = tzPart.match(/GMT([+-]\d{1,2})(?::?(\d{2}))?/);
  const rawHours = match?.[1] ?? "+1";
  const minutes = match?.[2] ?? "00";
  const sign = rawHours.startsWith("-") ? "-" : "+";
  const hours = Math.abs(Number(rawHours)).toString().padStart(2, "0");
  return `${sign}${hours}:${minutes}`;
}

export function dayBoundsBerlin(dayKey: string): { start: string; end: string } {
  const offset = berlinOffsetForDay(dayKey);
  return {
    start: `${dayKey}T00:00:00${offset}`,
    end: `${dayKey}T23:59:59${offset}`,
  };
}

function normalize(value: string | null | undefined): string {
  return (value ?? "").trim().toLowerCase();
}

export function lessonMatchesProfile(
  entry: Pick<CalendarRow, "class" | "schooltrack">,
  profile: Pick<ProfileRow, "class_name" | "schooltrack">,
): boolean {
  const entryClass = normalize(entry.class);
  const profileClass = normalize(profile.class_name);
  if (entryClass && (!profileClass || entryClass !== profileClass)) {
    return false;
  }

  const entryTrack = normalize(entry.schooltrack);
  if (entryTrack && entryTrack !== "unknown") {
    const profileTrack = normalize(profile.schooltrack);
    if (!profileTrack || entryTrack !== profileTrack) return false;
  }

  return true;
}

function isLunchMeal(startTime: string): boolean {
  const hour = Number(
    new Intl.DateTimeFormat("en-GB", {
      timeZone: SCHEDULE_TIMEZONE,
      hour: "numeric",
      hour12: false,
    }).format(new Date(startTime)),
  );
  return hour < 15;
}

function shortTitle(type: string, title: string): string {
  if (type === "meal") return "Essen";
  const trimmed = title.trim();
  if (trimmed.length <= 3) return trimmed;
  return trimmed.slice(0, 3);
}

function segmentFromRow(row: CalendarRow): TimetableSegment {
  const startMs = new Date(row.start_time).getTime();
  const endMs = row.end_time
    ? new Date(row.end_time).getTime()
    : startMs + 45 * 60_000;

  return {
    id: row.id,
    type: row.type ?? "lesson",
    title: row.event_name ?? "",
    shortTitle: shortTitle(row.type ?? "lesson", row.event_name ?? ""),
    subtitle: row.type === "lesson" ? "" : "",
    startMs,
    endMs,
    accentColor: "#124E30",
    imageUrl: undefined,
  };
}

function resolveCurrent(
  segments: TimetableSegment[],
  activityStartMs: number,
  nowMs: number,
): {
  index: number;
  segmentStartMs: number;
  segmentEndMs: number;
  isPreStart: boolean;
} | null {
  for (let i = 0; i < segments.length; i++) {
    const segment = segments[i];
    if (nowMs < segment.startMs) {
      const gapStart = i > 0 ? segments[i - 1].endMs : activityStartMs;
      return {
        index: i,
        segmentStartMs: gapStart,
        segmentEndMs: segment.startMs,
        isPreStart: true,
      };
    }
    if (nowMs < segment.endMs) {
      return {
        index: i,
        segmentStartMs: segment.startMs,
        segmentEndMs: segment.endMs,
        isPreStart: false,
      };
    }
  }
  return null;
}

function remainingLessonCount(
  segments: TimetableSegment[],
  fromIndex: number,
  isPreStart: boolean,
): number {
  let count = 0;
  for (let i = fromIndex; i < segments.length; i++) {
    if (segments[i].type !== "lesson") continue;
    if (i === fromIndex && !isPreStart) continue;
    count++;
  }
  return count;
}

export function filterTimetableRows(
  rows: CalendarRow[],
  profile: ProfileRow,
): CalendarRow[] {
  return rows
    .filter((row) => {
      if (row.type !== "lesson" && row.type !== "meal") return false;
      if (row.type === "meal" && !isLunchMeal(row.start_time)) return false;
      return lessonMatchesProfile(row, profile);
    })
    .sort((a, b) =>
      new Date(a.start_time).getTime() - new Date(b.start_time).getTime()
    );
}

export function buildTimetableSnapshot(
  dayDate: string,
  rows: CalendarRow[],
  profile: ProfileRow,
  now: Date,
): TimetableSnapshot | null {
  const filtered = filterTimetableRows(rows, profile);
  const lessons = filtered.filter((r) => r.type === "lesson");
  if (lessons.length === 0) return null;

  const segments = filtered.map(segmentFromRow);
  const firstLessonStart = new Date(lessons[0].start_time).getTime();
  const activityStartMs = firstLessonStart - PRE_START_MINUTES * 60_000;
  const dayEndMs = segments.reduce(
    (max, s) => Math.max(max, s.endMs),
    segments[0].endMs,
  );

  const nowMs = now.getTime();
  if (nowMs >= dayEndMs) return null;
  if (nowMs < activityStartMs) return null;

  const resolved = resolveCurrent(segments, activityStartMs, nowMs);
  if (!resolved) return null;

  const current = segments[resolved.index];
  const next = resolved.index + 1 < segments.length
    ? segments[resolved.index + 1]
    : null;

  return {
    dayDate,
    segments,
    activityStartMs,
    dayEndMs,
    currentIndex: resolved.index,
    currentTitle: current.title,
    currentSubtitle: current.subtitle,
    hasNext: next != null,
    nextTitle: next?.title ?? "",
    nextSubtitle: next?.subtitle ?? "",
    segmentStartMs: resolved.segmentStartMs,
    segmentEndMs: resolved.segmentEndMs,
    accentColor: current.accentColor,
    isMeal: current.type === "meal",
    imageUrl: current.imageUrl ?? "",
    remainingLessons: remainingLessonCount(
      segments,
      resolved.index,
      resolved.isPreStart,
    ),
    isPreStart: resolved.isPreStart,
  };
}

export function timetableSnapshotToContentState(
  snapshot: TimetableSnapshot,
): Record<string, string | number | boolean> {
  return {
    kind: "timetable",
    dayDate: snapshot.dayDate,
    segmentsJson: JSON.stringify(snapshot.segments),
    activityStartMs: snapshot.activityStartMs,
    dayEndMs: snapshot.dayEndMs,
    remainingLessons: snapshot.remainingLessons,
    currentIndex: snapshot.currentIndex,
    currentTitle: snapshot.currentTitle,
    currentSubtitle: snapshot.currentSubtitle,
    hasNext: snapshot.hasNext,
    nextTitle: snapshot.nextTitle,
    nextSubtitle: snapshot.nextSubtitle,
    segmentStartMs: snapshot.segmentStartMs,
    segmentEndMs: snapshot.segmentEndMs,
    accentColor: snapshot.accentColor,
    isMeal: snapshot.isMeal,
    imageUrl: snapshot.imageUrl,
    eventId: snapshot.dayDate,
    isPreStart: snapshot.isPreStart,
  };
}

export function emptyTimetableContentState(
  dayDate: string,
): Record<string, string | number | boolean> {
  return {
    kind: "timetable",
    dayDate,
    segmentsJson: "[]",
    activityStartMs: 0,
    dayEndMs: 0,
    remainingLessons: 0,
    currentIndex: 0,
    currentTitle: "Stundenplan",
    currentSubtitle: "",
    hasNext: false,
    nextTitle: "",
    nextSubtitle: "",
    segmentStartMs: 0,
    segmentEndMs: 0,
    accentColor: "#124E30",
    isMeal: false,
    imageUrl: "",
    eventId: dayDate,
    isPreStart: false,
  };
}
