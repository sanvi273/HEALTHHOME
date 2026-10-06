class PaymentModel {
  final String orderId;
  final int amount;
  final String currency;
  final String key;

  PaymentModel({
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.key,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      orderId: json["order"]["id"],
      amount: json["order"]["amount"],
      currency: json["order"]["currency"],
      key: json["key"],
    );
  }
}