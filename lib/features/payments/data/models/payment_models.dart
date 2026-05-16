enum PaymentMethod {
  wallet,
  card,
  bankTransfer;

  String get apiValue => switch (this) {
    PaymentMethod.wallet => 'wallet',
    PaymentMethod.card => 'card',
    PaymentMethod.bankTransfer => 'bank_transfer',
  };

  static PaymentMethod fromString(String v) => switch (v) {
    'wallet' => PaymentMethod.wallet,
    'card' => PaymentMethod.card,
    'bank_transfer' => PaymentMethod.bankTransfer,
    _ => PaymentMethod.card,
  };
}

class SavedCardModel {
  final String id;
  final String lastFourDigits;
  final String? brand;
  final int? expiryMonth;
  final int? expiryYear;
  final bool isDefault;

  const SavedCardModel({
    required this.id,
    required this.lastFourDigits,
    this.brand,
    this.expiryMonth,
    this.expiryYear,
    required this.isDefault,
  });

  factory SavedCardModel.fromJson(Map<String, dynamic> json) => SavedCardModel(
        id: json['id'] as String,
        lastFourDigits: json['last_four_digits'] as String,
        brand: json['brand'] as String?,
        expiryMonth: json['expiry_month'] as int?,
        expiryYear: json['expiry_year'] as int?,
        isDefault: json['is_default'] as bool,
      );
}

class PaymentVerifyResponseModel {
  final String? paymentId;
  final String status;
  final int amount;
  final String? channel;
  final String? paidAt;
  final String reference;
  final String? authorizationCode;
  final String? type;

  const PaymentVerifyResponseModel({
    this.paymentId,
    required this.status,
    required this.amount,
    this.channel,
    this.paidAt,
    required this.reference,
    this.authorizationCode,
    this.type,
  });

  factory PaymentVerifyResponseModel.fromJson(Map<String, dynamic> json) =>
      PaymentVerifyResponseModel(
        paymentId: json['payment_id'] as String?,
        status: json['status'] as String? ?? '',
        amount: json['amount'] as int? ?? 0,
        channel: json['channel'] as String?,
        paidAt: json['paid_at'] as String?,
        reference: json['reference'] as String? ?? '',
        authorizationCode: json['authorization_code'] as String?,
        type: json['type'] as String?,
      );

  bool get isSuccessful => status == 'success' || status == 'completed';
}

class PaymentInitResponseModel {
  final String? authorizationUrl;
  final String? reference;
  final String? accessCode;
  final String status;

  const PaymentInitResponseModel({
    this.authorizationUrl,
    this.reference,
    this.accessCode,
    this.status = 'pending',
  });

  factory PaymentInitResponseModel.fromJson(Map<String, dynamic> json) =>
      PaymentInitResponseModel(
        authorizationUrl: json['authorization_url'] as String?,
        reference: json['reference'] as String?,
        accessCode: json['access_code'] as String?,
        status: (json['status'] as String?) ?? 'pending',
      );
}
