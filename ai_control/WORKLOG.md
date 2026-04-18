# WORKLOG

- **Timestamp**: 2026-04-15 08:52:00
  - **Action**: Đọc TASK.md để nắm yêu cầu sửa code.
  - **Reason**: Xác nhận các scope fix P1, P2, P3.
  - **Result**: Nắm rõ 4 lỗi: create/update payload, filter thiều petId, swipe delete lỗi UI, day detail thiếu retry. Thấy code hiện tại đã hoàn thiện lớn nhưng thiếu safe state UI ở dismissible và thiếu control files.

- **Timestamp**: 2026-04-15 08:53:00
  - **Action**: Check `expense_capture_screen.dart` method `_save`.
  - **Reason**: Đảm bảo đúng payload contract (có VND, petId int.parse, loại bỏ note/imageUrl rỗng).
  - **Result**: Code logic check rỗng và string parser đều đã tuân thủ. Không có rủi ro Exception nếu dropdown null.

- **Timestamp**: 2026-04-15 08:53:30
  - **Action**: Check `expense_day_detail_screen.dart` loading state.
  - **Reason**: Đảm bảo Pull-to-refresh và Retry actions có tồn tại.
  - **Result**: Đã có widget `RefreshIndicator` và ElevatedButton `Thử lại` chạy `_fetch()`.

- **Timestamp**: 2026-04-15 08:54:00
  - **Action**: Sửa `expense_list_screen.dart` bổ sung callback `onDismissed` cho widget `Dismissible`.
  - **Reason**: Khắc phục lỗi Flutter "A dismissed widget is still part of the tree". Nếu request quá lâu hoặc delay async `_fetchData(refresh: true)`, UI cần loại item bằng code synchronize state trước, phòng Crash UI.
  - **Result**: Đã thêm `onDismissed` method xoá ID ứng với element ra khỏi `_expenses`.

- **Timestamp**: 2026-04-15 09:16:00
  - **Action**: Fix logic lọc sự kiện và sort ngày giờ trong `today_schedule_box.dart`.
  - **Reason**: Người dùng báo rủi ro (lịch khám chưa đến giờ bị ẩn). Nhận diện nguyên nhân do String sort + múi giờ UTC + thiếu bộ lọc mốc `DateTime.now()`.
  - **Result**: Đổi logic map sang `DateTime.toLocal()`, áp dụng lọc quá khứ và bắt buộc UI có State Error/Retry.
