// Adds `n` months to `date`, clamped to the last day of the target month
// (e.g. Jan 31 + 1 month -> Feb 28/29, not an overflowed Mar 3).
function addMonthsClamped(date, n) {
  const day = date.getDate();
  const result = new Date(date.getFullYear(), date.getMonth() + n, 1);
  const daysInMonth = new Date(result.getFullYear(), result.getMonth() + 1, 0).getDate();
  result.setDate(Math.min(day, daysInMonth));
  return result;
}

// Every monthly cycle anchored on the tenant's move-in day (move-in + 1
// month, +2 months, ...) that has come due as of today, minus whichever
// ones already have a paid RentPayment record. A tenant owes nothing until
// a full month of tenancy has passed - this is the single source of truth
// for "pending rent" / "due date tracking" - there's no separate generation
// step, a cycle is simply due until paid.
function dueMonths(moveInDate, paidPairs) {
  const paid = new Set(paidPairs.map(({ month, year }) => `${year}-${month}`));
  const months = [];

  const now = new Date();
  let cycle = 1;
  let dueDate = addMonthsClamped(moveInDate, cycle);

  while (dueDate <= now) {
    const month = dueDate.getMonth() + 1;
    const year = dueDate.getFullYear();
    if (!paid.has(`${year}-${month}`)) {
      months.push({ month, year });
    }
    cycle += 1;
    dueDate = addMonthsClamped(moveInDate, cycle);
  }
  return months;
}

function isCurrentMonth(month, year) {
  const now = new Date();
  return month === now.getMonth() + 1 && year === now.getFullYear();
}

module.exports = { dueMonths, isCurrentMonth };
