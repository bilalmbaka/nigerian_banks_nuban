import 'models/bank.dart';
import 'data/banks_data.dart';

class NigerianBanks {
  /// Returns a list of all banks.
  List<Bank> getBanks() {
    return banks;
  }

  /// Returns a bank by its slug.
  Bank? getBankBySlug(String slug, {List<Bank>? availableBanks}) {
    try {
      return (availableBanks ?? banks).firstWhere((bank) => bank.slug == slug);
    } catch (e) {
      return null;
    }
  }

  /// Returns a bank by its code.
  Bank? getBankByCode(String code, {List<Bank>? availableBanks}) {
    try {
      return (availableBanks ?? banks).firstWhere((bank) => bank.code == code);
    } catch (e) {
      return null;
    }
  }

  /// Returns a list of banks that match the account number's check digit.
  /// This relies on the NUBAN algorithm.
  List<Bank> getBanksByAccountNumber(
    String accountNumber, {
    List<Bank>? availableBanks,
  }) {
    if (accountNumber.length != 10) {
      return [];
    }

    final source = availableBanks ?? banks;

    return source.where((bank) {
      // Skip banks with non-numeric codes (e.g. 035A)
      final isNumeric = RegExp(r'^[0-9]+$').hasMatch(bank.code);
      if (!isNumeric) {
        return false;
      }

      return _isNubanValid(bank.code, accountNumber);
    }).toList();
  }

  /// Finds a bank by name using fuzzy matching.
  Bank? findBankByName(String name, {List<Bank>? availableBanks}) {
    final normalizedInput = normalizeName(name);
    if (normalizedInput.isEmpty) return null;

    final source = availableBanks ?? banks;
    Bank? bestMatch;
    int bestScore = 0;

    for (final bank in source) {
      final normalizedBankName = normalizeName(bank.name);

      if (normalizedBankName == normalizedInput) {
        return bank;
      }

      final score = _calculateMatchScore(normalizedInput, normalizedBankName);
      if (score > bestScore) {
        bestScore = score;
        bestMatch = bank;
      }
    }

    return bestScore >= 50 ? bestMatch : null;
  }

  /// Searches banks by name, slug, or code.
  List<Bank> searchBanks(String query, {List<Bank>? availableBanks}) {
    if (query.isEmpty) return [];

    final normalizedQuery = query.toLowerCase().trim();
    final source = availableBanks ?? banks;

    return source.where((bank) {
      return bank.name.toLowerCase().contains(normalizedQuery) ||
          bank.slug.toLowerCase().contains(normalizedQuery) ||
          bank.code.toLowerCase().contains(normalizedQuery) ||
          normalizeName(bank.name).contains(normalizeName(query));
    }).toList();
  }

  // --- Internal Helper Methods ---

  bool _isNubanValid(String bankCode, String accountNumber) {
    if (accountNumber.length != 10) return false;

    final String serialNumber = accountNumber.substring(0, 9);
    final int checkDigit = int.parse(accountNumber.substring(9));

    final String paddedBankCode = bankCode.padLeft(6, '0');
    final String verificationString = paddedBankCode + serialNumber;

    const List<int> weights = [3, 7, 3, 3, 7, 3, 3, 7, 3, 3, 7, 3, 3, 7, 3];
    int sum = 0;

    for (int i = 0; i < verificationString.length; i++) {
      final int digit = int.parse(verificationString[i]);
      sum += digit * weights[i];
    }

    int calculatedCheckDigit = 10 - (sum % 10);
    if (calculatedCheckDigit == 10) calculatedCheckDigit = 0;

    return calculatedCheckDigit == checkDigit;
  }

  static String normalizeName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(
          RegExp(r'\b(bank|mfb|microfinance|plc|limited|ltd|nigeria|ng)\b'),
          '',
        )
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
  }

  int _calculateMatchScore(String input, String target) {
    if (input == target) return 100;
    if (target.contains(input) || input.contains(target)) {
      final shorter = input.length < target.length ? input : target;
      final longer = input.length >= target.length ? input : target;
      return (shorter.length / longer.length * 100).round();
    }

    int matches = 0;
    for (int i = 0; i < input.length && i < target.length; i++) {
      if (input[i] == target[i]) matches++;
    }
    return (matches /
            (input.length > target.length ? input.length : target.length) *
            100)
        .round();
  }
}
