# TASK: Home Hotfix V2 (petId vaccine flow)

## Mục tiêu
Sửa dứt điểm luồng vaccine còn sót để không mở màn vaccine khi thiếu `petId`.

## Lỗi cần fix

### 1) Home Weekly Insights: nút Vaccine chưa truyền petId
- File: `lib/screens/home/home_screen.dart`
- Hiện tại: `context.push('/pet-vaccines')`
- Yêu cầu:
  - Nếu `pet != null`: `context.push('/pet-vaccines', extra: pet.id)`
  - Nếu `pet == null`: không push, hiển thị toast cảnh báo ngắn.

### 2) TodayScheduleBox: guard petId trước khi push vaccine
- File: `lib/widgets/today_schedule_box.dart`
- Hiện tại: `context.push('/pet-vaccines', extra: ev['petId']?.toString())`
- Yêu cầu:
  - Chỉ push khi `ev['petId']` hợp lệ (không null/rỗng).
  - Nếu thiếu `petId`, không push; hiển thị thông báo thân thiện.

## Acceptance Criteria
- AC1: Không còn trường hợp mở `'/pet-vaccines'` với `petId` null từ Home.
- AC2: Tap event vaccine thiếu `petId` không crash, không dead navigation.
- AC3: Có thông báo rõ ràng khi user thao tác nhưng thiếu dữ liệu pet.

## Test cases tối thiểu
1. Từ Home (có pet) bấm `Vaccine` -> mở đúng màn vaccine của pet đó.
2. Từ Home (không có pet hợp lệ) bấm `Vaccine` -> không push, hiện toast.
3. Event vaccine có `petId` -> push thành công.
4. Event vaccine thiếu `petId` -> không push, hiện toast.

## Output process
Cập nhật sau khi sửa:
- `./ai_control/WORKLOG.md`
- `./ai_control/CHANGED_FILES.md`
- `./ai_control/TEST_CASES.md`
- `./ai_control/FINAL_REPORT.md`
- `./ai_control/STATUS.md` = `DONE` hoặc `BLOCKED`
