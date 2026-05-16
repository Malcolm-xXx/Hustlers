import 'package:flutter_riverpod/flutter_riverpod.dart';

class SavingsActivity {
  final String id;
  final String orderRef;
  final double amount;
  final int percentage;
  final String date;

  const SavingsActivity({
    required this.id,
    required this.orderRef,
    required this.amount,
    required this.percentage,
    required this.date,
  });
}

class SavingsState {
  final double totalSaved;
  final double interestEarned;
  final double thisMonthSaved;
  final int autoSaveCount;
  final bool autoSaveEnabled;
  final int savePercentage;
  final bool saveAlertsEnabled;
  final bool isWithdrawalLocked;
  final String unlockDate;
  final int daysLeft;
  final List<double> monthlyValues;
  final List<SavingsActivity> activities;

  const SavingsState({
    this.totalSaved = 0,
    this.interestEarned = 0,
    this.thisMonthSaved = 0,
    this.autoSaveCount = 0,
    this.autoSaveEnabled = true,
    this.savePercentage = 10,
    this.saveAlertsEnabled = true,
    this.isWithdrawalLocked = true,
    this.unlockDate = '17 May 2025',
    this.daysLeft = 7,
    this.monthlyValues = const [350, 680, 1050, 490, 2100],
    this.activities = const [],
  });

  SavingsState copyWith({
    double? totalSaved,
    double? interestEarned,
    double? thisMonthSaved,
    int? autoSaveCount,
    bool? autoSaveEnabled,
    int? savePercentage,
    bool? saveAlertsEnabled,
    bool? isWithdrawalLocked,
    String? unlockDate,
    int? daysLeft,
    List<double>? monthlyValues,
    List<SavingsActivity>? activities,
  }) =>
      SavingsState(
        totalSaved: totalSaved ?? this.totalSaved,
        interestEarned: interestEarned ?? this.interestEarned,
        thisMonthSaved: thisMonthSaved ?? this.thisMonthSaved,
        autoSaveCount: autoSaveCount ?? this.autoSaveCount,
        autoSaveEnabled: autoSaveEnabled ?? this.autoSaveEnabled,
        savePercentage: savePercentage ?? this.savePercentage,
        saveAlertsEnabled: saveAlertsEnabled ?? this.saveAlertsEnabled,
        isWithdrawalLocked: isWithdrawalLocked ?? this.isWithdrawalLocked,
        unlockDate: unlockDate ?? this.unlockDate,
        daysLeft: daysLeft ?? this.daysLeft,
        monthlyValues: monthlyValues ?? this.monthlyValues,
        activities: activities ?? this.activities,
      );
}

class SavingsNotifier extends Notifier<SavingsState> {
  @override
  SavingsState build() {
    Future.microtask(_load);
    return const SavingsState();
  }

  void _load() {
    state = const SavingsState(
      totalSaved: 12430,
      interestEarned: 248.94,
      thisMonthSaved: 82.87,
      autoSaveCount: 24,
      autoSaveEnabled: true,
      savePercentage: 10,
      saveAlertsEnabled: true,
      isWithdrawalLocked: true,
      unlockDate: '17 May 2025',
      daysLeft: 7,
      monthlyValues: [350, 680, 1050, 490, 2100],
      activities: [
        SavingsActivity(
          id: 'sa1',
          orderRef: 'Order #8842 payout',
          amount: 350,
          percentage: 10,
          date: 'Today, 2:14 PM',
        ),
        SavingsActivity(
          id: 'sa2',
          orderRef: 'Order #8791 payout',
          amount: 220,
          percentage: 10,
          date: 'Yesterday, 6:45 PM',
        ),
        SavingsActivity(
          id: 'sa3',
          orderRef: 'Order #8765 payout',
          amount: 180,
          percentage: 10,
          date: 'Mon, 5 May',
        ),
        SavingsActivity(
          id: 'sa4',
          orderRef: 'Order #8701 payout',
          amount: 310,
          percentage: 10,
          date: 'Sun, 4 May',
        ),
      ],
    );
  }

  void toggleAutoSave() =>
      state = state.copyWith(autoSaveEnabled: !state.autoSaveEnabled);

  void toggleSaveAlerts() =>
      state = state.copyWith(saveAlertsEnabled: !state.saveAlertsEnabled);

  void setSavePercentage(int pct) =>
      state = state.copyWith(savePercentage: pct);

  void withdraw(double amount) {
    state = state.copyWith(totalSaved: state.totalSaved - amount);
  }
}

final savingsProvider =
    NotifierProvider<SavingsNotifier, SavingsState>(SavingsNotifier.new);
