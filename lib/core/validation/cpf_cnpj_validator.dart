final _allSameDigit = RegExp(r'^(\d)\1*$');

int _checkDigit(List<int> digits, List<int> weights) {
  var sum = 0;
  for (var i = 0; i < weights.length; i++) {
    sum += digits[i] * weights[i];
  }
  final remainder = sum % 11;
  return remainder < 2 ? 0 : 11 - remainder;
}

bool isValidCpf(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 11 || _allSameDigit.hasMatch(digits)) return false;
  final nums = digits.split('').map(int.parse).toList();

  final d1 = _checkDigit(nums, [10, 9, 8, 7, 6, 5, 4, 3, 2]);
  if (d1 != nums[9]) return false;

  final d2 = _checkDigit(nums, [11, 10, 9, 8, 7, 6, 5, 4, 3, 2]);
  return d2 == nums[10];
}

bool isValidCnpj(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 14 || _allSameDigit.hasMatch(digits)) return false;
  final nums = digits.split('').map(int.parse).toList();

  final d1 = _checkDigit(nums, [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]);
  if (d1 != nums[12]) return false;

  final d2 = _checkDigit(nums, [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]);
  return d2 == nums[13];
}

bool isValidCpfCnpj(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 11) return isValidCpf(digits);
  if (digits.length == 14) return isValidCnpj(digits);
  return false;
}
