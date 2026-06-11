/// Input validation utilities for forms.
class Validators {
  /// Validate South African phone number.
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    final cleaned = value.replaceAll(RegExp(r'[\s\-()]'), '');
    if (cleaned.startsWith('+27') && cleaned.length == 12) return null;
    if (cleaned.startsWith('0') && cleaned.length == 10) return null;
    return 'Enter a valid SA phone number';
  }

  /// Validate email address.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Optional
    final regex = RegExp(r'^[\w\.\-]+@[\w\.\-]+\.\w{2,}$');
    if (!regex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  /// Validate required field.
  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  /// Validate OTP (6 digits).
  static String? otp(String? value) {
    if (value == null || value.trim().isEmpty) return 'OTP is required';
    if (value.trim().length != 6 || !RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'OTP must be 6 digits';
    }
    return null;
  }

  /// Validate amount (positive number).
  static String? amount(String? value) {
    if (value == null || value.trim().isEmpty) return 'Amount is required';
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed <= 0) return 'Enter a valid amount';
    return null;
  }

  /// Validate SA ID number (13 digits, basic Luhn check).
  static String? idNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Optional
    final cleaned = value.replaceAll(RegExp(r'\s'), '');
    if (cleaned.length != 13 || !RegExp(r'^\d{13}$').hasMatch(cleaned)) {
      return 'ID number must be 13 digits';
    }
    return null;
  }

  /// Sanitize input — strip HTML/script tags to prevent injection.
  static String sanitize(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp('[<>"' "'" ']'), '')
        .trim();
  }
}
