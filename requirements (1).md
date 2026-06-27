# Flatmate Expense Tracker — Requirements Document

## 1. Overview

A mobile app for a group of flatmates (currently 5, but should support any group size) to:
- Track **personal expenses** by category.
- Track **shared/group expenses** inside a "Room" (the flat), split only among the members who actually participated in that expense.
- See a running **net balance ("Due")** per person — not a raw list of every transaction, but a simplified "you owe X / X owes you" number.
- See **category-wise spending** breakdowns, both personal and per-room.

Tech stack: **Flutter** (mobile, Android/iOS) + **Firebase** (Auth, Firestore, Cloud Functions, FCM for notifications).

---

## 2. Goals / Non-Goals

**Goals**
- Make it effortless to log an expense and select exactly who shares it.
- Always show an up-to-date, simplified "who owes whom how much" view.
- Give visibility into spending patterns (by category, by room, personally).

**Non-Goals (v1)**
- Multi-currency support.
- Real payment/settlement processing (UPI/bank integration) — v1 only *tracks* dues; settling is marked manually as "paid".
- Splitting expenses unequally by custom percentage (can be a v2 feature — see Suggestions).

---

## 3. User Roles

Single role type: **App User**. Inside a Room, all members have equal rights (add/edit/delete their own expenses, leave room). The Room **creator** additionally can:
- Invite/remove members.
- Rename/delete the room.

---

## 4. Functional Requirements

### 4.1 Authentication
- Sign up / log in via Firebase Auth (Email+Password and Google Sign-In recommended; Phone OTP optional).
- Basic profile: name, photo, phone (used so flatmates can identify each other easily).

### 4.2 Categories
- App ships with default categories: Food, Travel, Groceries, Clothes, Utilities, Rent, Entertainment, Other.
- User can add **custom categories** (name + icon/color), scoped to that user (or shared at room level — see 4.4).
- Categories are reused both for personal expenses and room expenses.

### 4.3 Personal Expense Tracking
- Add an expense: amount, category, date, note, optional photo of receipt.
- Edit/delete own personal expense.
- List view filterable by date range and category.
- Personal analytics: total spend this month, category-wise pie/bar chart, trend over months.

### 4.4 Rooms (Shared Groups)
- Create a Room (e.g., "Our Flat"), becomes the creator.
- Invite members via:
  - Shareable invite link/code, **or**
  - Searching by email/phone (if already a registered user), **or**
  - Direct invite if contact is in the user's phone (optional, later).
- A user can be part of **multiple rooms** simultaneously (e.g., flat room + trip room).
- Room has its own category list (can reuse global defaults + room-specific custom categories).

### 4.5 Adding a Room Expense (core feature)
When adding an expense inside a Room:
1. Enter amount, category, date, note, optional receipt photo.
2. **Paid by**: defaults to the current user, but should support "someone else paid" (in case you're logging on their behalf) — optional for v1, default current user only is fine for MVP.
3. **Split among**: a checklist of all room members, **all selected by default**, but the payer can **deselect** anyone who shouldn't be included (e.g., the vegetarian flatmate on a chicken-purchase expense).
4. Split type for v1: **Equal split** among selected members only.
   - Example: ₹150 grocery bill, payer = You, selected members = You + Sagar + Karan (3 people) → each of Sagar and Karan owes you ₹50.
5. On save, the expense is stored with: amount, payer, category, the list of participant user-ids, and the per-person share.

### 4.6 Dues / Balance Calculation (the important part)

**Requirement, restated precisely:** Don't show every individual transaction as a separate due — show a **running net balance per person**, updated every time a new expense is added, so debts automatically offset each other.

**How it works:**
- For every room expense, for each participant other than the payer:
  - `balance[payer][participant] += share`
  - `balance[participant][payer] -= share`
- The "Due" screen for a user shows, per other member, the **net** of all such entries:
  - Positive → "X owes you ₹N"
  - Negative → "You owe X ₹N"
  - Zero → settled, hidden from the list.

**Worked example (matches your scenario):**
1. You pay ₹150 for groceries, split equally among You, Sagar, Karan (3 people → ₹50 each).
   - Sagar owes you ₹50, Karan owes you ₹50.
2. Earlier (or later) Sagar had paid for something where you owed him, say ₹120, and Karan where you owed him ₹100 (these are pre-existing dues before the grocery expense).
   - Net with Sagar: you owed ₹120, now Sagar owes you ₹50 → net = you owe Sagar `120 - 50 = ₹70`.
   - Net with Karan: you owed ₹100, now Karan owes you ₹50 → net = you owe Karan `100 - 50 = ₹50`.
   - This is exactly the "my due reduced from 120/100 to 70/50" behavior you described.
3. So the Due screen is always a **net, not a transaction ledger** — every new expense recalculates (or incrementally updates) the net balance between each pair of members.

**Implementation note:** maintain balances as a denormalized map per room (`balances: { roomId: { userA_userB: netAmount } }`) updated transactionally (Cloud Function or Firestore transaction) whenever an expense is added/edited/deleted, rather than recomputing from scratch on every screen load. This keeps the Due screen fast even with hundreds of expenses.

**Settle Up (confirmation-based, no real payment processing):**
- Payment itself always happens outside the app (cash/UPI/whatever). The app only *records* that it happened.
- Flow: the person who **owes** money taps "I paid Sagar ₹70" → this creates a settlement request in `pending` state, visible to Sagar.
- The **receiver** (Sagar) must confirm it ("Mark as received") before the balance actually updates. This avoids someone falsely marking a due as settled without the other party agreeing.
- Until confirmed, the original due still shows as outstanding (optionally with a small "settlement requested, awaiting confirmation" badge).
- Once confirmed, a `settlement` record is logged (who paid, who confirmed, amount, date) and the net balance updates accordingly.
- Receiver can also reject a settlement request (e.g., wrong amount), which just discards it and the due stays as-is.

**Room-wide transparency (important):** Dues are not private between two people — **every member of the room can see the full balance matrix for the room**: who owes whom, and how much, for *all* pairs, not just their own. This avoids disputes and keeps things fair since everyone bought groceries on different days. A "Room Balances" view shows this as either a simple table (rows = members, columns = members, cell = net amount) or a list of "A owes B ₹N" lines for every non-zero pair in the room.

**Breakdown / audit trail of how a due was formed (transparency requirement):** Every due between two people must be traceable back to the actual expenses and settlements that produced it — not just a final number. Tapping on any balance (e.g., "You owe Sagar ₹70") opens a **breakdown screen** showing, in chronological order, every contributing event between that pair:
- Each room expense where one of them paid and the other was a participant — showing date, category, total expense amount, who paid, and this person's share (e.g., "Jun 12 · Groceries · Sagar paid ₹150, your share ₹50").
- Each settlement (paid/confirmed) between them — showing date and amount (e.g., "Jun 15 · You paid Sagar ₹50 · confirmed").
- A running subtotal so it's visible how the net number was arrived at, ending in the current balance.
This list should be derived from the same `expenses` and `settlements` records already stored (see Data Model) — no separate ledger needed, just a query filtered to "expenses where {A,B} ⊆ participants/payer" plus "settlements between A and B", merged and sorted by date.

### 4.7 Category-wise Analytics
- **Personal**: total spend per category (this month / custom range), as a chart + list.
- **Per Room**: total spend per category for the whole room (sum of all members' contributions), plus "my share" per category. Should also show "total room spend this month" and per-member contribution totals (who paid how much overall).

### 4.8 Notifications (recommended)
- Push notification (FCM) when:
  - Someone adds an expense in a room you're part of.
  - Someone settles a due with you.
  - Optional weekly summary / reminder of pending dues.

---

## 5. Non-Functional Requirements
- Offline-friendly: Firestore's offline persistence should be enabled so expenses can be added without network and sync later.
- Security: Firestore rules so a user can only read/write rooms they belong to, and only edit/delete their own expenses. **Note:** within a room, `expenses`, `balances`, and `settlements` should be **readable by all members** of that room (not restricted to the two parties involved) to satisfy the transparency requirement — only personal expenses stay private to the individual user.
- Performance: balance computation should not require scanning all historical expenses on every app open (see denormalization note above).
- Data integrity: expense edits/deletes must correctly reverse and reapply balance changes (use Firestore transactions or a Cloud Function trigger on expense write/delete).

---

## 6. Data Model (Firestore)

```
users/{userId}
  name, email, phone, photoUrl, createdAt

categories/{categoryId}            // global defaults, read-only seed data
  name, icon, color

users/{userId}/personalCategories/{categoryId}   // user's custom categories
  name, icon, color

users/{userId}/personalExpenses/{expenseId}
  amount, categoryId, note, date, receiptUrl, createdAt

rooms/{roomId}
  name, createdBy, createdAt, memberIds: [uid1, uid2, ...]

rooms/{roomId}/members/{userId}
  joinedAt, role: "owner" | "member"

rooms/{roomId}/categories/{categoryId}   // room-specific custom categories
  name, icon, color

rooms/{roomId}/expenses/{expenseId}
  amount, categoryId, paidBy: uid, participantIds: [uid...], 
  splitShare: { uid: amount, ... },   // precomputed per-person share
  note, date, receiptUrl, createdAt, createdBy

rooms/{roomId}/balances/{pairKey}        // pairKey = sorted "uidA_uidB"
  uidA, uidB, netAmount   // positive => uidB owes uidA, by convention
  // readable by ALL room members (not just the two involved) — enables room-wide transparency

rooms/{roomId}/settlements/{settlementId}
  fromUid (who paid), toUid (who received), amount, date, note,
  status: "pending" | "confirmed" | "rejected",
  createdAt, confirmedAt

invites/{inviteCode}
  roomId, createdBy, expiresAt
```

---

## 7. Tech Stack

- **Flutter** (state management: Riverpod or Bloc recommended over plain Provider for this complexity level).
- **Firebase Auth** — Email/Password + Google Sign-In.
- **Cloud Firestore** — primary database, with offline persistence enabled.
- **Cloud Functions** (Node/TypeScript) — recommended for: recalculating `balances` atomically when an expense is added/edited/deleted, sending FCM notifications, generating invite codes.
- **Firebase Cloud Messaging** — notifications.
- **Firebase Storage** — receipt photos.
- Charts: `fl_chart` or `syncfusion_flutter_charts` package for category breakdown visuals.

---

## 8. Suggestions / Things to Consider

1. **Debt simplification ("settle up" optimization):** With 5 people, balances can get tangled (A owes B, B owes C, C owes A). Consider a "minimize transactions" settle-up suggestion screen — a known technique (similar to Splitwise) that suggests the minimum number of payments to settle the whole room, not just pairwise. This is a nice v2 feature once basic netting works.
2. **Unequal splits:** You mentioned excluding people (e.g., vegetarian flatmate), which the design supports. Consider also allowing **custom amounts/percentages per person** later (e.g., someone had 2 plates vs 1) instead of only equal split.
3. **Edit/delete history:** Since deleting/editing an expense changes balances retroactively, log a small audit trail so people don't get confused by sudden balance changes.
4. **Recurring expenses:** Rent/Wi-Fi/electricity often repeat monthly with the same split — a "recurring expense" template would save effort.
5. **Receipt photo + OCR (later):** Optional auto-fill of amount from a photographed receipt — nice-to-have, not v1.
6. **Multiple rooms:** Even though you're one flat now, building rooms as a generic concept (rather than hardcoding "the flat") lets you reuse the app for trips, events, etc. Already reflected in the data model above.
7. **Soft delete for leaving a room:** If someone moves out, don't hard-delete their history — keep past expenses/balances intact, just remove them from "active members" so future expenses don't include them by default.
8. **Currency/locale:** confirm if all 5 of you only use INR — if yes, hardcode ₹ formatting; otherwise add a currency field early since it's painful to retrofit.

---

## 9. Screens (for reference, expanded on in the UI agent prompt)

1. Splash / Auth (Login, Signup)
2. Home (tab navigation: Personal | Rooms | Dues | Profile)
3. Personal Expenses list + Add/Edit Expense
4. Personal Analytics (category breakdown)
5. Rooms list, Create Room, Join Room (via invite code)
6. Room detail (tabs: Expenses | Dues | Analytics | Members)
7. Add Room Expense (with member-select split chooser)
8. Dues screen (per room) — shows full room balance matrix (everyone's dues with everyone, not just yours), each row tappable
9. Due Breakdown screen — chronological list of expenses + settlements that make up a balance between two people
10. Settle Up — "I paid ₹N" request screen (sender side) and "Confirm / Reject incoming settlement" screen (receiver side)
11. Category management (add/edit custom categories)
12. Profile / Settings
