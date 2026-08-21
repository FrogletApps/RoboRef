export function timeAgo(input: Date, locales: Intl.LocalesArgument = "en") {
  const date = new Date(input);
  const formatter = new Intl.RelativeTimeFormat(locales);
  const ranges = {
    years: 3600 * 24 * 365,
    months: 3600 * 24 * 30,
    weeks: 3600 * 24 * 7,
    days: 3600 * 24,
    hours: 3600,
    minutes: 60,
    seconds: 1,
  };
  const secondsElapsed = (date.getTime() - Date.now()) / 1000;
  for (const [key, value] of Object.entries(ranges)) {
    if (value < Math.abs(secondsElapsed)) {
      const delta = secondsElapsed / value;
      return formatter.format(
        Math.round(delta),
        key as Intl.RelativeTimeFormatUnit
      );
    }
  }
  return formatter.format(-1, "seconds");
}

export function formatEventDate(
  start?: string,
  end?: string,
  locales?: Intl.LocalesArgument
): string | undefined {
  if (!start) return undefined;

  const startDate = new Date(start);
  if (isNaN(startDate.getTime())) return undefined;

  const endDate = end ? new Date(end) : undefined;
  const isValidEnd = endDate && !isNaN(endDate.getTime());

  const formatter = new Intl.DateTimeFormat(locales, {
    month: "short",
    day: "numeric",
    year: "numeric",
  });

  if (!isValidEnd) {
    return formatter.format(startDate);
  }

  const isSameDay =
    startDate.getFullYear() === endDate.getFullYear() &&
    startDate.getMonth() === endDate.getMonth() &&
    startDate.getDate() === endDate.getDate();

  if (isSameDay) {
    return formatter.format(startDate);
  }

  try {
    return formatter.formatRange(startDate, endDate);
  } catch {
    return formatter.format(startDate);
  }
}

