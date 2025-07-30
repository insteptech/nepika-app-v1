class Validators {
  static bool validatePhoneNumber(String number) {
    final regExp = RegExp(r'^\d{10,15}$'); // Basic regex for phone validation
    return regExp.hasMatch(number);
  }
}
