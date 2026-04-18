# PLAN

## Objective
Fix các lỗi frontend còn sót trong `Expense` module để đạt acceptance criteria, bao gồm thêm payload đúng contract, sửa lỗi filter theo petId, update logic swipe delete an toàn có call API await, và thêm retry state trên màn hình detail.

## Scope in / Scope out
- **Scope in**:
  - `lib/screens/expense/expense_capture_screen.dart`: Sửa payload gửi đi (currency=VND, chuyển kiểu petId thành int, xoá note/image rỗng).
  - `lib/screens/expense/expense_list_screen.dart`: Thêm dropdown PetId vào filter sheet. Sửa onDismissed bằng cách handle trong `confirmDismiss` và mutate mảng `_expenses`.
  - `lib/screens/expense/expense_day_detail_screen.dart`: Handle loading, error with Retry và Pull-to-refresh.
- **Scope out**: 
  - Không sửa API backend. 
  - Không refactor structure màn hình.

## Assumptions
- Các fix core hiện tại đã được implement đầy đủ (hoặc người dùng đã sửa trước nhưng thiếu file quy trình).
- `ExpenseApi` methods (create/update, summary, list, delete) đã support các field/filter từ backend đàng hoàng.

## Implementation steps
- [x] Đọc kĩ source và kiểm tra logic payload tại `expense_capture_screen.dart`.
- [x] Đảm bảo logic pull-to-refresh & retry đã có ở `expense_day_detail_screen.dart`.
- [x] Sửa lỗi flutter Dismissible widget state trong quá trình swipe delete: bổ sung `onDismissed` method tại `expense_list_screen.dart`.
- [x] Đảm bảo Filter bao gồm reset cho `petId`, `from`, `to`.
- [x] (Added Request) Fix `today_schedule_box.dart`: parse DateTime để loại sự kiện trong quá khứ, sửa logic string sort, chỉnh múi giờ Local và thêm Error state.
- [ ] Ghi đầy đủ file `WORKLOG`, `CHANGED_FILES`, `TEST_CASES`, `BUGS_AND_RISKS`, `FINAL_REPORT`, `STATUS`.

## Risk list
- Nếu swipe delete trả về thành công nhưng UI rebuild lỗi sẽ làm crash (Flutter unmounted state error). Fix bằng cách gỡ item trong data local via `onDismissed`.

## Test strategy
- Test xem edit/submit chi tiêu có payload `petId` parse chuẩn số int không.
- Gửi lên mà note/ảnh rỗng thì intercept check payload.
- Mở bottom sheet ở List view, thay đổi mốc date, thay đổi pet, ấn tìm, ấn Bỏ lọc.
- Swipe để xoá, xác nhận cancel (UI giữ nguyên), xác nhận xoá (API call -> Thành công -> Item bị remove).
- Tắt mạng vào Day Detail check Thử lại.
