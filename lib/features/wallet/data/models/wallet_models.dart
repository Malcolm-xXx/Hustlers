// ── UI enums (used by wallet view) ────────────────────────────────────────────

enum TransactionType { order, topUp, withdrawal, refund }

enum TransactionStatus { completed, processing, failed }

enum TransactionFilter { all, orders, topUps, withdrawals }

// ── UI models ─────────────────────────────────────────────────────────────────

class WalletTransaction {
  final String id;
  final String title;
  final double amount; // always positive (absolute value)
  final bool isCredit; // explicit direction flag (not derived from sign)
  final TransactionType type;
  final TransactionStatus status;
  final String time; // formatted "2:14 PM"
  final String date; // formatted "TODAY"

  const WalletTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.isCredit,
    required this.type,
    required this.status,
    required this.time,
    required this.date,
  });
}

class WalletSavedCard {
  final String id;
  final String type; // 'visa' | 'mastercard'
  final String lastFour;
  final String expires; // 'MM/YY'
  final bool isDefault;

  const WalletSavedCard({
    required this.id,
    required this.type,
    required this.lastFour,
    required this.expires,
    this.isDefault = false,
  });
}

class LinkedBankAccount {
  final String id;
  final String bankName;
  final String bankCode;
  final String lastFour;
  final String accountName;
  final String recipientCode;

  const LinkedBankAccount({
    required this.id,
    required this.bankName,
    this.bankCode = '',
    required this.lastFour,
    required this.accountName,
    this.recipientCode = '',
  });
}

// ── API response models ────────────────────────────────────────────────────────

class WalletAnalyticsModel {
  final int availableBalance;
  final int moneyInThisWeek;
  final int moneyOutThisWeek;

  const WalletAnalyticsModel({
    required this.availableBalance,
    required this.moneyInThisWeek,
    required this.moneyOutThisWeek,
  });

  factory WalletAnalyticsModel.fromJson(Map<String, dynamic> json) =>
      WalletAnalyticsModel(
        availableBalance: json['available_balance'] as int,
        moneyInThisWeek: json['money_in_this_week'] as int,
        moneyOutThisWeek: json['money_out_this_week'] as int,
      );
}

class WalletTransactionApiModel {
  final String id;
  final int amount;
  final int balanceBefore;
  final int balanceAfter;
  final String transactionType;
  final DateTime createdAt;

  const WalletTransactionApiModel({
    required this.id,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.transactionType,
    required this.createdAt,
  });

  factory WalletTransactionApiModel.fromJson(Map<String, dynamic> json) =>
      WalletTransactionApiModel(
        id: json['id'] as String,
        amount: json['amount'] as int,
        balanceBefore: json['balance_before'] as int,
        balanceAfter: json['balance_after'] as int,
        transactionType: json['transaction_type'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  bool get isCredit =>
      transactionType == 'order_credit' ||
      transactionType == 'topup' ||
      transactionType == 'refund';

  TransactionType get uiType => switch (transactionType) {
        'topup' => TransactionType.topUp,
        'withdrawal' => TransactionType.withdrawal,
        'refund' => TransactionType.refund,
        _ => TransactionType.order,
      };

  WalletTransaction toDisplayModel() {
    final now = DateTime.now();
    final isToday = createdAt.year == now.year &&
        createdAt.month == now.month &&
        createdAt.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = createdAt.year == yesterday.year &&
        createdAt.month == yesterday.month &&
        createdAt.day == yesterday.day;

    final hour = createdAt.hour;
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final time =
        '$displayHour:${createdAt.minute.toString().padLeft(2, '0')} $amPm';

    const monthNames = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    const dayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final String date;
    if (isToday) {
      date = 'TODAY';
    } else if (isYesterday) {
      date = 'YESTERDAY';
    } else {
      final weekday = dayNames[createdAt.weekday - 1];
      final month = monthNames[createdAt.month - 1];
      date = '$weekday, ${createdAt.day} $month';
    }

    final title = switch (transactionType) {
      'topup' => 'Wallet Top Up',
      'withdrawal' => 'Withdrawal',
      'refund' => 'Refund',
      'order_credit' => 'Order Credit',
      'order_debit' => 'Order Payment',
      _ => 'Transaction',
    };

    return WalletTransaction(
      id: id,
      title: title,
      amount: amount.toDouble(),
      isCredit: isCredit,
      type: uiType,
      status: TransactionStatus.completed,
      time: time,
      date: date,
    );
  }
}

class WalletTopupResponseModel {
  final String? authorizationUrl;
  final String? reference;
  final String? accessCode;
  final String status;

  const WalletTopupResponseModel({
    this.authorizationUrl,
    this.reference,
    this.accessCode,
    this.status = 'pending',
  });

  factory WalletTopupResponseModel.fromJson(Map<String, dynamic> json) =>
      WalletTopupResponseModel(
        authorizationUrl: json['authorization_url'] as String?,
        reference: json['reference'] as String?,
        accessCode: json['access_code'] as String?,
        status: (json['status'] as String?) ?? 'pending',
      );
}

class WalletWithdrawResponseModel {
  final WalletTransactionApiModel debit;
  final String? transferCode;
  final bool requiresOtp;

  const WalletWithdrawResponseModel({
    required this.debit,
    this.transferCode,
    this.requiresOtp = false,
  });

  factory WalletWithdrawResponseModel.fromJson(Map<String, dynamic> json) =>
      WalletWithdrawResponseModel(
        debit: WalletTransactionApiModel.fromJson(
            json['debit'] as Map<String, dynamic>),
        transferCode: json['transfer_code'] as String?,
        requiresOtp: (json['requires_otp'] as bool?) ?? false,
      );
}

class TransferRecipientModel {
  final String recipientCode;

  const TransferRecipientModel({required this.recipientCode});

  factory TransferRecipientModel.fromJson(Map<String, dynamic> json) =>
      TransferRecipientModel(
        recipientCode: json['recipient_code'] as String,
      );
}
