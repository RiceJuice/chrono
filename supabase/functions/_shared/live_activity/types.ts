import type { LiveActivityFcmEvent } from "../fcm_v1.ts";

export type LiveActivityKind = "event" | "timetable";

export type RequestBody = {
  mode?: string;
  kind?: LiveActivityKind;
  reference_id?: string;
  event_id?: string;
  user_id?: string;
  class_name?: string | null;
  schooltrack?: string | null;
  schedule_id?: string | null;
  action?: LiveActivityFcmEvent;
  job_id?: string;
  op?: string;
  source?: string;
  event_snapshot?: CalendarEventRow;
};

export type AudienceTokens = string | string[] | null | undefined;

export type ScheduleRow = {
  id: string;
  event_id: string;
  title: string;
  location: string | null;
  start_time: string;
  end_time: string | null;
  choir: AudienceTokens;
  voices: AudienceTokens;
};

export type CalendarEventRow = {
  id: string;
  event_name: string | null;
  start_time?: string | null;
  end_time?: string | null;
  location?: string | null;
  choir: AudienceTokens;
  voices: AudienceTokens;
  type: string | null;
  class?: string | null;
  schooltrack?: string | null;
  diet?: string | null;
  image_paths?: string | null;
};

export type ProfileRow = {
  id: string;
  choir: string | null;
  voice: string | null;
  class_name?: string | null;
  schooltrack?: string | null;
};

export type DeviceRow = {
  id: string;
  user_id: string;
  device_id: string;
  fcm_token: string;
  platform: string;
  schedule_filter: string;
  push_to_start_token: string | null;
  live_activity_push_token: string | null;
  profiles?: ProfileRow | ProfileRow[] | null;
};

export type EventSnapshot = {
  currentScheduleId: string;
  currentTitle: string;
  currentSubtitle: string;
  hasNext: boolean;
  nextTitle: string;
  nextSubtitle: string;
  segmentStartMs: number;
  segmentEndMs: number;
};

export type TimetableSegment = {
  id: string;
  type: string;
  title: string;
  shortTitle: string;
  subtitle: string;
  startMs: number;
  endMs: number;
  accentColor: string;
  imageUrl?: string;
};

export type TimetableSnapshot = {
  dayDate: string;
  segments: TimetableSegment[];
  activityStartMs: number;
  dayEndMs: number;
  currentIndex: number;
  currentTitle: string;
  currentSubtitle: string;
  hasNext: boolean;
  nextTitle: string;
  nextSubtitle: string;
  segmentStartMs: number;
  segmentEndMs: number;
  accentColor: string;
  isMeal: boolean;
  imageUrl: string;
  remainingLessons: number;
  isPreStart: boolean;
};

export const SCHEDULE_TIMEZONE = "Europe/Berlin";
export const PRE_START_MINUTES = 15;
export const NIL_UUID = "00000000-0000-0000-0000-000000000000";
