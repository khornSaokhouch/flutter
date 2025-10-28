// utils.dart

/// Formats a phone number to E.164 format for Cambodia (+855)
String formatPhoneNumber(String input) {
  input = input.trim();

  // Remove leading 0 if present
  if (input.startsWith('0')) input = input.substring(1);

  // Add country code if missing
  if (!input.startsWith('+855')) input = '+855$input';

  return input;
}

/// Checks if a password is strong
/// Rules:
/// - Minimum 8 characters
/// - At least one uppercase letter
/// - At least one lowercase letter
/// - At least one number
/// - At least one special character (@$!%*?&)
bool isPasswordValid(String password) {
  if (password.length < 8) return false;

  final regex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$');

  return regex.hasMatch(password);
}

/// Checks if two passwords match
bool doPasswordsMatch(String password, String confirmPassword) {
  return password == confirmPassword;
}

String getGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return "Morning";
  if (hour < 17) return "Afternoon";
  return "Evening";
}