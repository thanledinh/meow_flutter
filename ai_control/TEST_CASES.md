## Test Case: TC-1 Create Expense with Currency and PetId
- Priority: P1
- Type: Integration
- Requirement link: Expense Module Fixes (Payload Issue)

### Objective
Verify that `petId`, `currency` are correctly structured, and empty `note`/`imageUrl` fields are handled smoothly without crash.

### Preconditions
- User is on Expense Capture mode.
- Authenticated state.

### Test Data
- Valid input: Amount 100000, Select a Pet.
- Invalid input: No Amount.
- Edge input: No note, no image.

### Steps
1. Tap create expense.
2. Choose Pet.
3. Skip note and image.
4. Input amount and send.

### Expected Result
- Success message shown.
- Payload doesn't contain `note` or `imageUrl`, contains `currency: VND`, and `petId` is format integer.

### Negative/Edge Checks
- Test no amount -> throws validation error.
- Test note typed with 100 characters max limit.
- Test pet selection set to "Tất cả" (null) sends no petId in payload.

### Post-conditions
- List UI is refreshed to show the new item.

---

## Test Case: TC-2 Filter list by PetId
- Priority: P2
- Type: Integration

### Objective
Ensure Pet filtering limits the expense items logic.

### Preconditions
- User is on Expense List View.

### Expected Result
- Selecting a specific pet updates the Expense ListView and Summary values accordingly.
- Tap "Bỏ lọc" resets the state parameters `from`, `to`, `petId`.

---

## Test Case: TC-3 Swipe Dismiss Sync safety
- Priority: P2
- Type: E2E

### Objective
Ensure Swipe Delete correctly fires API block and syncs UI local element count without Flutter tree errors.

### Steps
1. Swipe a single list item from end to start.
2. Cancel in modal dialog (Should restore).
3. Swipe again and click Confirm.

### Expected Result
- The confirm dialog disappears, item vanishes via `onDismissed`, backend removes the dataset via async call. List UI doesn't crash on fast redraw.

---

## Test Case: TC-4 Home Schedule Timeline Parse Logic
- Priority: P2
- Type: Integration

### Objective
Ensure Timeline box correctly filters out past days and displays Local Time properly.

### Steps
1. Insert mock data of a Clinic booking that is pending but its Date was 2 days ago `2026-04-10T12:00:00Z`.
2. Insert a valid Clinic booking for today `2026-04-15` at 11am (`04:00Z`).
3. Reload HomeScreen.

### Expected Result
- The old booking `2026-04-10` is NOT listed on the UI.
- The 11am booking appears at the top.
- Time is displayed exactly as `11:00 ngày 15/04` instead of `04:00`.
- In case of API Error, timeline box renders `Lỗi tải lịch trình hệ thống` with try again button.