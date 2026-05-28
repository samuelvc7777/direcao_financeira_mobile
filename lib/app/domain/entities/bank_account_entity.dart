enum AccountType {
  checking,
  savings,
  wallet,
  investment,
  other;

  String get label {
    switch (this) {
      case AccountType.checking:
        return 'Conta Corrente';
      case AccountType.savings:
        return 'Poupanca';
      case AccountType.wallet:
        return 'Dinheiro';
      case AccountType.investment:
        return 'Investimento';
      case AccountType.other:
        return 'Outro';
    }
  }
}

class BankAccountEntity {
  final int id;
  final String name;
  final String bankName;
  final String color;
  final AccountType accountType;
  final int initialBalanceCents;
  final int currentBalanceCents;
  final bool isActive;

  BankAccountEntity({
    required this.id,
    required this.name,
    required this.bankName,
    required this.color,
    required this.accountType,
    required this.initialBalanceCents,
    required this.currentBalanceCents,
    required this.isActive,
  });

  double get currentBalance => currentBalanceCents / 100.0;
  double get initialBalance => initialBalanceCents / 100.0;
}
