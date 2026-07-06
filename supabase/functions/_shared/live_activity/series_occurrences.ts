import { rrulestr } from "npm:rrule@2.8.1";
import { dayBoundsBerlin, filterTimetableRows } from "./timetable_snapshot.ts";
import type { ProfileRow } from "./types.ts";

export type TimetableCalendarRow = {
  id: string;
  event_name: string | null;
  type: string | null;
  start_time: string;
  end_time: string | null;
  class: string | null;
  schooltrack: string | null;
  image_paths: string | null;
  series_id?: string | null;
};

type SeriesRow = {
  id: string;
  event_name: string | null;
  type: string | null;
  rrule: string | null;
  series_start: string;
  series_end: string | null;
  start_time: string;
  end_time: string | null;
  class: string | null;
  schooltrack: string | null;
  image_paths?: string | null;
};

type EventRow = TimetableCalendarRow & {
  series_id: string | null;
  recurrence_id: string | null;
};

function normalizeRrule(raw: string | null | undefined): string | null {
  const text = raw?.trim();
  if (!text) return null;
  const upper = text.toUpperCase();
  if (upper.startsWith("RRULE:")) return text;
  if (upper.includes("FREQ=")) return `RRULE:${text}`;
  return null;
}

function extractWallHms(wallIso: string): string {
  const part = wallIso.includes("T") ? wallIso.split("T")[1]! : wallIso;
  return part.replace(/([+-]\d{2}(?::?\d{2})?|Z)$/i, "");
}

function berlinOffsetSuffix(wallIso: string): string {
  const match = wallIso.match(/([+-]\d{2}(?::?\d{2})?|Z)$/i);
  return match?.[1] === "Z" ? "+00:00" : (match?.[1] ?? "+02:00");
}

function berlinInstant(dayKey: string, wallIso: string): Date {
  const hms = extractWallHms(wallIso);
  const offset = berlinOffsetSuffix(wallIso);
  const normalizedOffset = offset.length === 3 ? `${offset}:00` : offset;
  return new Date(`${dayKey}T${hms}${normalizedOffset}`);
}

function parseSeriesDate(value: string | null | undefined): Date | null {
  const s = value?.trim().slice(0, 10);
  if (!s) return null;
  return new Date(`${s}T00:00:00${berlinOffsetSuffix(value ?? "")}`);
}

function seriesEndExclusive(seriesEnd: string | null | undefined): Date | null {
  const day = seriesEnd?.trim().slice(0, 10);
  if (!day) return null;
  const endLocal = berlinInstant(day, "23:59:59+02:00");
  return new Date(endLocal.getTime() + 1000);
}

function formatRecurrenceId(instant: Date): string {
  const utc = new Date(Date.UTC(
    instant.getUTCFullYear(),
    instant.getUTCMonth(),
    instant.getUTCDate(),
    instant.getUTCHours(),
    instant.getUTCMinutes(),
    instant.getUTCSeconds(),
  ));
  return utc.toISOString().replace(/\.\d{3}Z$/, "Z");
}

function overrideKey(seriesId: string, recurrenceId: string): string {
  return `${seriesId}|${recurrenceId.trim()}`;
}

function isCancellation(event: EventRow): boolean {
  if (!event.series_id || !event.recurrence_id?.trim()) return false;
  const start = new Date(event.start_time).getTime();
  const end = new Date(event.end_time ?? event.start_time).getTime();
  return end <= start;
}

export function expandSeriesForDay(
  series: SeriesRow,
  dayKey: string,
): TimetableCalendarRow[] {
  const normalized = normalizeRrule(series.rrule);
  if (!normalized) return [];

  const bounds = dayBoundsBerlin(dayKey);
  const dayStart = new Date(bounds.start);
  const dayEnd = new Date(bounds.end);
  const seriesStartDay = series.series_start.trim().slice(0, 10);
  const seriesStart = parseSeriesDate(series.series_start);
  const seriesEnd = seriesEndExclusive(series.series_end);
  if (seriesStart && dayEnd < seriesStart) return [];
  if (seriesEnd && dayStart >= seriesEnd) return [];

  const dtstart = berlinInstant(seriesStartDay, series.start_time);
  const templateStart = berlinInstant(dayKey, series.start_time);
  const templateEnd = berlinInstant(
    dayKey,
    series.end_time ?? series.start_time,
  );
  const durationMs = Math.max(
    templateEnd.getTime() - templateStart.getTime(),
    45 * 60_000,
  );

  let rule;
  try {
    rule = rrulestr(normalized, { dtstart });
  } catch {
    return [];
  }

  const instances = rule.between(
    new Date(dayStart.getTime() - 1),
    new Date(dayEnd.getTime() + 1),
    true,
  );

  return instances.map((instance) => {
    const day = new Intl.DateTimeFormat("en-CA", {
      timeZone: "Europe/Berlin",
    }).format(instance);
    const start = berlinInstant(day, series.start_time);
    const end = new Date(start.getTime() + durationMs);
    return {
      id: series.id,
      event_name: series.event_name,
      type: series.type,
      start_time: start.toISOString(),
      end_time: end.toISOString(),
      class: series.class,
      schooltrack: series.schooltrack,
      image_paths: series.image_paths ?? null,
      series_id: series.id,
    };
  });
}

export function mergeTimetableRowsForDay(
  dayKey: string,
  events: EventRow[],
  seriesRows: SeriesRow[],
  profile: ProfileRow,
): TimetableCalendarRow[] {
  const bounds = dayBoundsBerlin(dayKey);
  const overrides = new Set<string>();
  const visibleEvents: TimetableCalendarRow[] = [];

  for (const event of events) {
    const seriesId = event.series_id?.trim();
    const recurrenceId = event.recurrence_id?.trim();
    if (seriesId && recurrenceId) {
      overrides.add(overrideKey(seriesId, recurrenceId));
      if (!isCancellation(event)) {
        visibleEvents.push(event);
      }
      continue;
    }
    visibleEvents.push(event);
  }

  const expandedSeries: TimetableCalendarRow[] = [];
  for (const series of seriesRows) {
    for (const row of expandSeriesForDay(series, dayKey)) {
      const recurrenceId = formatRecurrenceId(new Date(row.start_time));
      if (overrides.has(overrideKey(series.id, recurrenceId))) continue;
      expandedSeries.push(row);
    }
  }

  const merged = [...visibleEvents, ...expandedSeries].filter((row) => {
    const start = new Date(row.start_time).getTime();
    return start >= new Date(bounds.start).getTime() &&
      start <= new Date(bounds.end).getTime();
  });

  return filterTimetableRows(merged, profile);
}
