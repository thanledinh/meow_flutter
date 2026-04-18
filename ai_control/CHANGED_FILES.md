# CHANGED FILES

- **path**: `lib/screens/expense/expense_list_screen.dart`
  - **change_type**: update
  - **summary**: Đã bổ sung callback `onDismissed` vào widget `Dismissible` để loại bỏ item local ra khỏi mảng `_expenses` một cách synchronous.
  - **regression_risk**: Low (chủ yếu là state local an toàn hơn, không break API data source since trigger từ UI đã handle server delete từ `confirmDismiss`).
  - **related_tests**: Test số 3, 4 về Swipe Delete.

- **path**: `lib/widgets/today_schedule_box.dart`
  - **change_type**: update
  - **summary**: Áp dụng Local DateTime khi parse sự kiện. Bổ sung error state. Lọc event ở quá khứ dể tránh bị pushed ra khỏi scope `.take(2)`.
  - **regression_risk**: Medium (cải tổ logic parse time từ API cũ. Safe fallback using try/catch to maintain original string).
  - **related_tests**: Chạy app check UI lịch hiển thị (có error/empty state).
