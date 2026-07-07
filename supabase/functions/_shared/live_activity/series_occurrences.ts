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

const WEEKDAY_CODES = ["MO", "TU", "WE", "TH", "FR", "SA", "SU"] as const;

type ParsedWeeklyRule = {
  freq: "WEEKLY";
  interval: number;
  byDay: number[];
};

function parseRruleParams(rrule: string): Record<string, string> {
  const body = rrule.trim().replace(/^RRULE:/i, "");
  const params: Record<string, string> = {};
  for (const part of body.split(";")) {
    const [key, value] = part.split("=");
    if (key && value) params[key.trim().toUpperCase()] = value.trim();
  }
  return params;
}

// Eigene minimalistische RRULE-Auswertung fuer FREQ=WEEKLY;BYDAY=... statt der
// npm:rrule-Bibliothek: dynamische npm-Imports sind im Deno Edge-Runtime nicht
// zuverlaessig verfuegbar und schlugen dort still fehl (try/catch schluckte den
// Fehler), wodurch Serien nie expandiert wurden - obwohl es lokal in Node
// funktionierte. Die hier verwendeten Regeln sind ausschliesslich einfache
// woechentliche Stundenplan-Wiederholungen, daher reicht diese Eigenloesung.
function parseWeeklyRule(normalized: string): ParsedWeeklyRule | null {
  const params = parseRruleParams(normalized);
  if ((params.FREQ ?? "").toUpperCase() !== "WEEKLY") return null;

  const interval = Math.max(1, parseInt(params.INTERVAL ?? "1", 10) || 1);
  const byDayRaw = params.BYDAY ?? "";
  const byDay = byDayRaw
    .split(",")
    .map((code) => WEEKDAY_CODES.indexOf(code.trim().toUpperCase() as typeof WEEKDAY_CODES[number]))
    .filter((idx) => idx >= 0);

  if (byDay.length === 0) return null;
  return { freq: "WEEKLY", interval, byDay };
}

function isoWeekday(date: Date): number {
  // 0=Montag .. 6=Sonntag, passend zu WEEKDAY_CODES
  return (date.getUTCDay() + 6) % 7;
}

function weeksBetween(fromMonday: Date, toMonday: Date): number {
  const msPerWeek = 7 * 24 * 60 * 60 * 1000;
  return Math.round((toMonday.getTime() - fromMonday.getTime()) / msPerWeek);
}

function mondayOfWeek(date: Date): Date {
  const weekday = isoWeekday(date);
  const monday = new Date(date.getTime());
  monday.setUTCDate(monday.getUTCDate() - weekday);
  monday.setUTCHours(0, 0, 0, 0);
  return monday;
}

function occursOnDay(rule: ParsedWeeklyRule, dtstart: Date, targetDayUtcMidnight: Date): boolean {
  const targetWeekday = isoWeekday(targetDayUtcMidnight);
  if (!rule.byDay.includes(targetWeekday)) return false;
  if (rule.interval === 1) return true;

  const dtstartMonday = mondayOfWeek(dtstart);
  const targetMonday = mondayOfWeek(targetDayUtcMidnight);
  const diffWeeks = weeksBetween(dtstartMonday, targetMonday);
  return diffWeeks >= 0 && diffWeeks % rule.interval === 0;
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
  // Wichtig: series_start/series_end sind reine Datums-Strings (YYYY-MM-DD)
  // ohne echten Offset. berlinOffsetSuffix() ist fuer Uhrzeit-Strings mit
  // Offset gedacht - auf ein Datum angewendet, matcht die Regex faelschlich
  // den Tag ("...-15" -> Offset "-15") und liefert ein Invalid Date. Daher
  // hier die DST-sichere Tagesgrenze aus dayBoundsBerlin() nutzen.
  return new Date(dayBoundsBerlin(s).start);
}

function seriesEndExclusive(seriesEnd: string | null | undefined): Date | null {
  const day = seriesEnd?.trim().slice(0, 10);
  if (!day) return null;
  const endLocal = new Date(dayBoundsBerlin(day).end);
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

export async function expandSeriesForDay(
  series: SeriesRow,
  dayKey: string,
): Promise<TimetableCalendarRow[]> {
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

  const rule = parseWeeklyRule(normalized);
  if (!rule) return [];

  const dtstart = berlinInstant(seriesStartDay, series.start_time);
  const targetDayUtcMidnight = new Date(`${dayKey}T00:00:00Z`);
  if (!occursOnDay(rule, dtstart, targetDayUtcMidnight)) return [];

  const templateStart = berlinInstant(dayKey, series.start_time);
  const templateEnd = berlinInstant(
    dayKey,
    series.end_time ?? series.start_time,
  );
  const durationMs = Math.max(
    templateEnd.getTime() - templateStart.getTime(),
    45 * 60_000,
  );

  const start = templateStart;
  const end = new Date(start.getTime() + durationMs);
  return [{
    id: series.id,
    event_name: series.event_name,
    type: series.type,
    start_time: start.toISOString(),
    end_time: end.toISOString(),
    class: series.class,
    schooltrack: series.schooltrack,
    image_paths: series.image_paths ?? null,
    series_id: series.id,
  }];
}

export async function mergeTimetableRowsForDay(
  dayKey: string,
  events: EventRow[],
  seriesRows: SeriesRow[],
  profile: ProfileRow,
): Promise<TimetableCalendarRow[]> {
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
    for (const row of await expandSeriesForDay(series, dayKey)) {
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
