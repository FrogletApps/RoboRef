## 2026.10.24 - Tooltips on Actionable Card IconButtons
**Learning:** Icon-only action buttons inside dynamic list cards (such as delete note buttons) lack screen-reader accessible text unless explicitly provided with a `tooltip` parameter. In Flutter, `IconButton` uses `tooltip` for semantic labels (`Semantics(label: tooltip)`), enabling screen readers like TalkBack/VoiceOver to describe the action to visually impaired referees.
**Action:** Always provide a clear, descriptive `tooltip` attribute for icon-only `IconButton` widgets in Flutter list cards and app bars.
