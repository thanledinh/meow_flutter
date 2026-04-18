# TASK: Home Hotfix sau review (route + null-safety + crash guard)

## Mục tiêu
Sửa các lỗi P1/P2 còn lại trên Home Dashboard để tránh dead-route, tránh lỗi `petId` null, và tăng ổn định khi dữ liệu API không chuẩn.

## Severity
- [P1] Dead route khi bấm event vaccine trong lịch.
- [P1] Có thể điều hướng sang màn yêu cầu `petId` với `petId = null`.
- [P2] `WeightChartBox` có thể crash với dữ liệu `weight/date` không hợp lệ.
- [P2] Còn debug UI lộ ra production.

## File phạm vi bắt buộc
- `lib/widgets/today_schedule_box.dart`
- `lib/screens/home/home_screen.dart`
- `lib/widgets/weight_chart.dart`

## Yêu cầu implement chi tiết

### 1) Fix dead route ở TodayScheduleBox
- Trong `today_schedule_box.dart`, thay điều hướng vaccine:
  - từ: `context.push('/medical-records', extra: {'petId': ev['petId']})`
  - sang route hợp lệ đang có trong router.
- Ưu tiên: `'/pet-vaccines'` (truyền `extra: ev['petId']`) hoặc route phù hợp nhất theo kiến trúc hiện tại.

### 2) Chặn điều hướng khi chưa có pet hợp lệ
- Trong `home_screen.dart`, đảm bảo khi `pets` thay đổi (xóa pet/chuyển account) thì `_selectedPetIdx` luôn hợp lệ.
- Trước khi `push('/pet-weight')` hoặc `push('/medical')`, nếu `pet == null` thì:
  - không push route,
  - hiện toast cảnh báo ngắn gọn (ví dụ: "Vui lòng chọn thú cưng").

### 3) Tăng an toàn cho WeightChartBox
- Trong `weight_chart.dart`:
  - Không cast cứng `(c['weight'] as num)`.
  - Parse an toàn `num.tryParse(...)` cho mọi kiểu (`num/string/null`).
  - Bỏ qua điểm dữ liệu không hợp lệ.
  - Bảo vệ `substring(5, 10)` bằng check độ dài; nếu không đủ thì hiển thị fallback rỗng.
- Không để widget throw exception khi API trả dữ liệu bẩn.

### 4) Bỏ debug text production
- Trong `today_schedule_box.dart`, bỏ block debug đỏ:
  - `'Debug: FeedingTimeline Empty=...'`
- Thay bằng empty state trung tính, thân thiện user (không lộ nội dung debug nội bộ).

## Acceptance Criteria
- AC1: Tap event vaccine không còn vào 404/not-found.
- AC2: Không có trường hợp mở `PetWeightScreen`/`MedicalScreen` với `petId` null từ Home.
- AC3: `WeightChartBox` không crash nếu `weight` null/string hoặc `date` thiếu ký tự.
- AC4: Không còn text debug nội bộ hiển thị trên UI production.

## Test cases tối thiểu
1. Home có event vaccine -> tap event -> vào đúng màn hợp lệ.
2. Trường hợp selected index lệch (mảng pets đổi) -> không crash, action cần petId không bị push sai.
3. Feed chart data mẫu bẩn:
   - `[{weight: null, date: "2026-01"}, {weight: "3.2", date: ""}]`
   - UI vẫn render ổn định, không exception.
4. Khi không có timeline/event -> hiển thị empty state sạch, không có "Debug:".

## Ràng buộc kỹ thuật
- Không đổi API contract backend.
- Không thêm dependency mới.
- Không sửa ngoài phạm vi 3 file bắt buộc trừ khi thật sự cần để build.

## Output process (bắt buộc)
Sau khi implement, cập nhật:
- `./ai_control/WORKLOG.md`
- `./ai_control/CHANGED_FILES.md`
- `./ai_control/TEST_CASES.md`
- `./ai_control/BUGS_AND_RISKS.md`
- `./ai_control/FINAL_REPORT.md`
- `./ai_control/STATUS.md` (ghi `DONE` hoặc `BLOCKED`)
