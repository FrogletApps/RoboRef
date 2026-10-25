## 2026-10-25 - Pre-compile RegExp in Sorting Comparators
**Learning:** Instantiating `RegExp` objects inside tight comparator loops like `compareMatchNames` and `compareTeamNumbers` caused over 700,000 regex compilations when sorting standard match and team schedules, taking ~2.4 seconds per 500 sort operations.
**Action:** Always declare `RegExp` patterns as top-level `final` constants or static fields when used inside comparator or utility functions executed repeatedly.
