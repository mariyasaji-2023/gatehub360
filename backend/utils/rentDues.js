// Every calendar month from a tenant's move-in month through the current
// month, minus whichever ones already have a paid RentPayment record. This
// is the single source of truth for "pending rent" / "due date tracking" -
// there's no separate generation step, a month is simply due until paid.
function dueMonths(moveInDate, paidPairs) {
  const paid = new Set(paidPairs.map(({ month, year }) => `${year}-${month}`));
  const months = [];

  const cursor = new Date(moveInDate.getFullYear(), moveInDate.getMonth(), 1);
  const now = new Date();
  const end = new Date(now.getFullYear(), now.getMonth(), 1);

  while (cursor <= end) {
    const month = cursor.getMonth() + 1;
    const year = cursor.getFullYear();
    if (!paid.has(`${year}-${month}`)) {
      months.push({ month, year });
    }
    cursor.setMonth(cursor.getMonth() + 1);
  }
  return months;
}

function isCurrentMonth(month, year) {
  const now = new Date();
  return month === now.getMonth() + 1 && year === now.getFullYear();
}

module.exports = { dueMonths, isCurrentMonth };
