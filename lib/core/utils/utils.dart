// utils.dart

/// Formats a phone number to E.164 format for Cambodia (+855)
/// Formats a phone number to E.164 format for Cambodia (+855)
/// If the input is an email, returns it unchanged.
String formatPhoneNumber(String input) {
  input = input.trim();

  // 🔹 If it's an email, return as is
  if (input.contains('@')) return input;

  // 🔹 Handle phone numbers
  if (input.startsWith('0')) input = input.substring(1);

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


/// Convert file extension to MIME type
String getMimeType(String path) {
  final ext = path.split('.').last.toLowerCase();
  switch (ext) {
    case 'png':
      return 'png';
    case 'jpg':
    case 'jpeg':
      return 'jpeg';
    case 'heic': // iOS default format
      return 'jpeg'; // Convert HEIC to jpeg
    case 'gif':
      return 'gif';
    default:
      return 'jpeg';
  }
}


String formatTime(String? timeString) {
  if (timeString == null) return '--:--';
  final parts = timeString.split(':');
  if (parts.length < 2) return timeString;
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = parts[1];
  final suffix = hour >= 12 ? 'PM' : 'AM';
  final formattedHour = (hour % 12 == 0) ? 12 : hour % 12;
  return '$formattedHour:$minute $suffix';
}

bool checkIfOpen(String? openTime, String? closeTime) {
  if (openTime == null || closeTime == null) return false;

  try {
    final now = DateTime.now();

    // Parse "HH:mm"
    final openParts = openTime.split(":");
    final closeParts = closeTime.split(":");

    final openHour = int.parse(openParts[0]);
    final openMinute = int.parse(openParts[1]);

    final closeHour = int.parse(closeParts[0]);
    final closeMinute = int.parse(closeParts[1]);

    // Today’s open/close times
    final openDate = DateTime(now.year, now.month, now.day, openHour, openMinute);
    var closeDate = DateTime(now.year, now.month, now.day, closeHour, closeMinute);

    // If close time is past midnight (e.g. closes at 02:00)
    if (closeDate.isBefore(openDate)) {
      closeDate = closeDate.add(const Duration(days: 1));
    }

    return now.isAfter(openDate) && now.isBefore(closeDate);
  } catch (e) {
    return false;
  }
}
