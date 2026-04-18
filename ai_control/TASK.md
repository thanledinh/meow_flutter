# TASK: Fix Home Schedule khong hien lich kham hom nay

## Bug report
User co lich kham hom nay luc 11:30 nhung trong block "Khung lich trinh" khong hien thi.

## Nguyen nhan kha nang cao (tu code hien tai)
File: `lib/widgets/today_schedule_box.dart`
1. Dang loc booking theo status qua cung:
   - Chi giu `pending` hoac `confirmed`.
   - Neu backend tra status khac (vd: `booked`, `scheduled`, `upcoming`) thi bi loai bo.
2. Parse datetime booking chua robust:
   - Dang dung chu yeu `b['date']`.
   - Neu backend tach `date` va `time` (11:30) thi khong ket hop, de sai thu tu/hien thi.
3. Gioi han `merged.take(2)` co the day mat booking hom nay neu 2 event khac dung truoc.

## Muc tieu fix
Dam bao lich kham hom nay (vd 11:30) hien thi dung trong Home schedule.

## Scope file bat buoc
- `lib/widgets/today_schedule_box.dart`
- `lib/api/clinic_api.dart` (chi sua neu can truyen query/filter ro hon)

## Yeu cau implement

### 1) Bo status filter cung
- Khong hardcode chi `pending/confirmed`.
- Chap nhan tat ca booking chua ket thuc (theo danh sach status hop le backend).
- Neu khong co danh sach status chuan, tam thoi KHONG loc theo status o client.

### 2) Parse datetime booking dung cach
- Tao helper parse booking datetime:
  - uu tien truong datetime day du neu co,
  - neu backend tach `date` + `time`, phai combine thanh DateTime local,
  - fallback an toan neu format la.
- Hien thi title dung gio thuc te (11:30), khong mac dinh 00:00.

### 3) Loc/sap xep event dung uu tien
- Chi giu event tu hom nay tro di.
- Sap xep tang dan theo datetime that.
- Dam bao event "hom nay" duoc uu tien hien thi truoc event xa hon.

### 4) Rule hien thi top N
- Neu van gioi han so event (top 2), phai uu tien:
  1. booking hom nay gan nhat,
  2. sau do moi den event khac.
- Khong de vaccine/day khac day mat booking hom nay.

### 5) Error/empty state
- Giu loading/error/empty state hien co.
- Khong lam vo behavior dang co.

## Acceptance Criteria
- AC1: Booking hom nay 11:30 hien thi trong schedule box.
- AC2: Gio hien thi dung theo local time.
- AC3: Booking khong bi mat do status mismatch.
- AC4: Khi co nhieu event, booking hom nay van duoc uu tien trong top hien thi.

## Test cases toi thieu
1. Booking status = `pending` -> hien thi.
2. Booking status = `booked`/`scheduled` -> van hien thi.
3. Backend tra `date` + `time` tach rieng (11:30) -> hien thi dung 11:30.
4. Co 3+ event cung luc, trong do co booking hom nay -> booking hom nay nam trong top card.

## Rang buoc
- Frontend-only, khong doi backend contract.
- Khong hardcode mock data trong production.

## Output process
Cap nhat sau khi xong:
- `./ai_control/PLAN.md`
- `./ai_control/WORKLOG.md`
- `./ai_control/CHANGED_FILES.md`
- `./ai_control/TEST_CASES.md`
- `./ai_control/BUGS_AND_RISKS.md`
- `./ai_control/FINAL_REPORT.md`
- `./ai_control/STATUS.md` = `DONE` hoac `BLOCKED`
