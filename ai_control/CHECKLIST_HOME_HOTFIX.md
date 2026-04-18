# CHECKLIST: Home Hotfix

## Scope files
- [ ] `lib/widgets/today_schedule_box.dart`
- [ ] `lib/screens/home/home_screen.dart`
- [ ] `lib/widgets/weight_chart.dart`

## Route fix
- [ ] Thay route vaccine từ `'/medical-records'` sang route hợp lệ hiện có.
- [ ] Verify tap event vaccine không vào 404.

## Null-safety petId
- [ ] Đảm bảo `_selectedPetIdx` luôn hợp lệ khi danh sách pet thay đổi.
- [ ] Guard trước khi mở `'/pet-weight'` và `'/medical'` (không push khi `pet == null`).
- [ ] Hiện toast cảnh báo ngắn khi chưa chọn pet.

## WeightChart crash guard
- [ ] Parse `weight` an toàn (`num/string/null`), bỏ qua điểm lỗi.
- [ ] Guard label date, không `substring` khi chuỗi quá ngắn.
- [ ] Widget không throw exception với data bẩn.

## Production cleanup
- [ ] Xóa text debug `'Debug: FeedingTimeline Empty=...'`.
- [ ] Thay bằng empty state user-friendly.

## Verify nhanh
- [ ] Tap vaccine event -> mở đúng màn hợp lệ.
- [ ] Trường hợp pet list thay đổi -> không push màn cần `petId` null.
- [ ] Chart data bẩn vẫn render ổn định.
- [ ] Không còn debug text trên UI.

## Handover docs
- [ ] Cập nhật `ai_control/WORKLOG.md`
- [ ] Cập nhật `ai_control/CHANGED_FILES.md`
- [ ] Cập nhật `ai_control/TEST_CASES.md`
- [ ] Cập nhật `ai_control/BUGS_AND_RISKS.md`
- [ ] Cập nhật `ai_control/FINAL_REPORT.md`
- [ ] Cập nhật `ai_control/STATUS.md` = `DONE` hoặc `BLOCKED`
