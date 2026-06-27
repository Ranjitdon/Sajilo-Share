String formatMoney(num amount) {
  // If it's a whole number, show it without decimals (e.g., 50)
  // If it has decimals, show up to 2 decimal places (e.g., 50.50)
  if (amount == amount.truncateToDouble()) {
    return amount.toStringAsFixed(0);
  } else {
    return amount.toStringAsFixed(2);
  }
}
