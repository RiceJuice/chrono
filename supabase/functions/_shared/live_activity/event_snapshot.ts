import type { CalendarEventRow, EventSnapshot, ScheduleRow } from "./types.ts";
import { SCHEDULE_TIMEZONE } from "./types.ts";

export function localDateKey(d: Date): string {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: SCHEDULE_TIMEZONE,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(d);
}

export function isSameLocalDay(a: Date, b: Date): boolean {
  return localDateKey(a) === localDateKey(b);
}

export function isEventType(raw: string | null | undefined): boolean {
  return (raw ?? "").trim().toLowerCase() === "event";
}

export function effectiveEnd(
  schedule: Pick<ScheduleRow, "start_time" | "end_time">,
): Date {
  const endRaw = schedule.end_time ?? schedule.start_time;
  const end = new Date(endRaw);
  if (schedule.end_time == null) {
    return new Date(end.getTime() + 45 * 60_000);
  }
  return end;
}

export function scheduleVisibleForProfile(
  schedule: ScheduleRow,
  profile: { choir: string | null; voice: string | null },
  filter: string,
): boolean {
  if (filter !== "mine") return true;

  const profileChoir = (profile.choir ?? "").trim().toLowerCase();
  const profileVoice = (profile.voice ?? "").trim().toLowerCase();
  const scheduleChoirs = parseTokens(schedule.choir);
  const scheduleVoices = parseTokens(schedule.voices);

  if (scheduleChoirs.length === 0 && scheduleVoices.length === 0) {
    return true;
  }

  if (scheduleChoirs.length > 0) {
    if (!profileChoir || !scheduleChoirs.includes(profileChoir)) return false;
  }

  if (scheduleVoices.length > 0) {
    if (!profileVoice || profileVoice === "unknown") return false;
    if (!scheduleVoices.includes(profileVoice)) return false;
  }

  return true;
}

function parseTokens(raw: string | string[] | null | undefined): string[] {
  if (raw == null) return [];
  if (Array.isArray(raw)) {
    return raw.map((v) => String(v).trim().toLowerCase()).filter(Boolean);
  }
  return raw.replace(/[{}"]/g, "").split(",")
    .map((v) => v.trim().toLowerCase())
    .filter(Boolean);
}

export function visibleSchedulesToday(
  schedules: ScheduleRow[],
  profile: { choir: string | null; voice: string | null },
  filter: string,
  now: Date,
): ScheduleRow[] {
  return schedules
    .filter((s) =>
      isSameLocalDay(new Date(s.start_time), now) &&
      scheduleVisibleForProfile(s, profile, filter)
    )
    .sort((a, b) =>
      new Date(a.start_time).getTime() - new Date(b.start_time).getTime()
    );
}

export function buildEventSnapshot(
  schedules: ScheduleRow[],
  now: Date,
): EventSnapshot | null {
  const visibleToday = schedules
    .filter((s) => isSameLocalDay(new Date(s.start_time), now))
    .sort((a, b) =>
      new Date(a.start_time).getTime() - new Date(b.start_time).getTime()
    );

  if (visibleToday.length === 0) return null;

  let currentIndex = -1;
  for (let i = 0; i < visibleToday.length; i++) {
    if (effectiveEnd(visibleToday[i]) > now) {
      currentIndex = i;
      break;
    }
  }
  if (currentIndex < 0) return null;

  const current = visibleToday[currentIndex];
  const next = currentIndex + 1 < visibleToday.length
    ? visibleToday[currentIndex + 1]
    : null;

  return {
    currentScheduleId: current.id,
    currentTitle: current.title,
    currentSubtitle: current.location ?? "",
    hasNext: next != null,
    nextTitle: next?.title ?? "",
    nextSubtitle: next?.location ?? "",
    segmentStartMs: new Date(current.start_time).getTime(),
    segmentEndMs: effectiveEnd(current).getTime(),
  };
}

export function buildEventOnlySnapshot(
  event: CalendarEventRow,
): EventSnapshot | null {
  if (!event.start_time || !event.end_time) return null;
  return {
    currentScheduleId: event.id,
    currentTitle: event.event_name ?? "",
    currentSubtitle: event.location ?? "",
    hasNext: false,
    nextTitle: "",
    nextSubtitle: "",
    segmentStartMs: new Date(event.start_time).getTime(),
    segmentEndMs: new Date(event.end_time).getTime(),
  };
}

export function snapshotToContentState(
  snapshot: EventSnapshot,
  eventId: string,
): Record<string, string | number | boolean> {
  return {
    currentTitle: snapshot.currentTitle,
    currentSubtitle: snapshot.currentSubtitle,
    hasNext: snapshot.hasNext,
    nextTitle: snapshot.nextTitle,
    nextSubtitle: snapshot.nextSubtitle,
    segmentStartMs: snapshot.segmentStartMs,
    segmentEndMs: snapshot.segmentEndMs,
    eventId,
  };
}

export function emptyEventContentState(
  eventId: string,
): Record<string, string | number | boolean> {
  return {
    currentTitle: "",
    currentSubtitle: "",
    hasNext: false,
    nextTitle: "",
    nextSubtitle: "",
    segmentStartMs: 0,
    segmentEndMs: 0,
    eventId,
  };
}

export function isEventActiveToday(
  event: CalendarEventRow,
  now: Date,
): boolean {
  if (!event.start_time || !event.end_time) return false;
  const start = new Date(event.start_time);
  const end = new Date(event.end_time);
  return isSameLocalDay(start, now) && start <= now && end > now;
}

export function isEventRelevantToday(
  event: CalendarEventRow,
  schedules: ScheduleRow[],
  now: Date,
): boolean {
  if (schedules.length > 0) {
    return schedules.some((s) => isSameLocalDay(new Date(s.start_time), now));
  }
  if (!event.start_time || !event.end_time) return false;
  return isSameLocalDay(new Date(event.start_time), now);
}
