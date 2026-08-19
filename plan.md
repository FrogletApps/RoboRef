1. The goal is to update the sorting approximation in `lib/pdf/index.ts` to fetch actual match info.
2. In `generateIncidentReportPDF`, after we fetch the `event`, we can fetch all the matches for the event. Note: a VEX event can have multiple divisions. We can loop over the event divisions (from `event.data.divisions`), and call `event.data.matches(division.id)`. Wait, it returns a promise of a paginated list of matches, or the `matches()` method on `Event` wrapper class returns it.
3. In `Event` class, `matches(division: number)` returns `Promise<TransformedFetchResponse<..., Match[]>>`. We can fetch all matches for all divisions present in the event.
4. Actually, `Match` object has `id`, `event`, `division`, `round`, `instance`, `matchnum`, etc.
5. In `matchComparison`, we are passed two `IncidentMatch` objects, but they don't have enough data to easily fetch from the API inside the sort callback, so we should fetch the `Match[]` beforehand, then create a sorting function `makeMatchComparison(matches: Match[])` which returns `(a, b) => number`.
6. Inside the comparison function, we can look up the `Match` object for `a` and `b` by finding a match in the `matches` array with the matching `id`. `IncidentMatchHeadToHead` has an `id` field.
7. If we find the real `Match` objects, we can compare them based on `division` (which could be the `division.id`), `round`, `instance`, and `matchnum`.
8. Fallback to the current logic if the `id` is not found or it's a `IncidentMatchSkills`.
9. The `incidentComparison` function will also need to be a higher-order function, e.g., `makeIncidentComparison(matches: Match[])`.
10. Pass `matches` down from `generateIncidentReportPDF` where we can fetch all divisions. Wait, `event.data.divisions` contains `[{id: number, name: string}]`. We can fetch matches for all divisions using `Promise.all(event.data.divisions.map(d => event.data!.matches(d.id!)))`.
