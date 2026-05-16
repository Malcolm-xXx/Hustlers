import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoanState {
  final double? selectedAmount;
  final int? selectedWeeks;

  const LoanState({this.selectedAmount, this.selectedWeeks});

  LoanState copyWith({
    double? selectedAmount,
    int? selectedWeeks,
  }) =>
      LoanState(
        selectedAmount: selectedAmount ?? this.selectedAmount,
        selectedWeeks: selectedWeeks ?? this.selectedWeeks,
      );

  bool get isReady => selectedAmount != null && selectedWeeks != null;

  double get extensionFee {
    switch (selectedWeeks) {
      case 6:
        return 250;
      case 8:
        return 500;
      default:
        return 0;
    }
  }

  double get totalRepayable => (selectedAmount ?? 0) + extensionFee;

  String get feeLabel {
    switch (selectedWeeks) {
      case 6:
        return '+₦250';
      case 8:
        return '+₦500';
      default:
        return 'No fee';
    }
  }
}

class LoanNotifier extends Notifier<LoanState> {
  @override
  LoanState build() => const LoanState();

  void selectAmount(double amount) =>
      state = state.copyWith(selectedAmount: amount);

  void selectWeeks(int weeks) =>
      state = state.copyWith(selectedWeeks: weeks);

  void reset() => state = const LoanState();
}

final loanProvider =
    NotifierProvider<LoanNotifier, LoanState>(LoanNotifier.new);
