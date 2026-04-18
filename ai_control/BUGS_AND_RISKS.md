# BUGS AND RISKS

- id: BUG-1
- title: Flutter Framework UI crash without `onDismissed` method in Swipe Delete flow.
- severity: P2
- impacted_area: `expense_list_screen.dart` Dismissible interaction.
- evidence: Lack of `onDismissed` hook to mutate the local `_expenses` while `confirmDismiss` fires an async `_fetchData()`. It causes "Dismissed widget is still part of the tree" assertion.
- fix_recommendation: Add `onDismissed` to synchronously detach item by `id` from the array view.
- status: fixed

- id: BUG-2
- title: Scheduled items hidden due to past pending items overflow & String-based date sorting.
- severity: P2
- impacted_area: `today_schedule_box.dart` Data Fetching.
- evidence: Events before today pushed real upcoming events down, then hidden by `.take(2)`. LocalTime vs UTC bug when formatting string `substring()`.
- fix_recommendation: Convert API output to Local `DateTime`, filter out items strictly in the past (unless it is today), and handle explicit error catch states.
- status: fixed