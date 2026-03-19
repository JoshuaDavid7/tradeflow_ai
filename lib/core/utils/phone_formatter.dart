/// Lightweight US phone number formatter.
///
/// Takes a raw phone string (e.g. "5551234567", "+15551234567",
/// "(555) 123-4567") and returns a consistently formatted string.
/// Non-US numbers or unrecognised formats are returned as-is.
String formatPhoneNumber(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '';
  final digits = raw.replaceAll(RegExp(r'[^\d]'), '');

  // 10-digit US number
  if (digits.length == 10) {
    return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
  }
  // 11-digit with leading 1
  if (digits.length == 11 && digits.startsWith('1')) {
    return '(${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7)}';
  }
  // Already formatted or international — return original trimmed
  return raw.trim();
}
