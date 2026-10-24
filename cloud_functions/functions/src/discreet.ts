// Mirrors DiscreetSchedule.contains
function isInsideSchedule(schedule: any, now: Date): boolean {
  if (!schedule || schedule.enabled !== true) return false;
  const { from, to, offset } = schedule;
  if (![from, to, offset].every((v) => Number.isFinite(v))) return false;

  const utcMinute = now.getUTCHours() * 60 + now.getUTCMinutes();
  const minute = (((utcMinute + offset) % 1440) + 1440) % 1440;
  return from <= to ? minute >= from && minute < to : minute >= from || minute < to;
}

export function isDiscreetNow(user: any, now: Date = new Date()): boolean {
  return !!user.discrete || isInsideSchedule(user.discreetSchedule, now);
}
