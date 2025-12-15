class PaymentModel {
  final int id;
  final int amountCents;
  final String status;
  final String? paymentMethod;
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.amountCents,
    required this.status,
    this.paymentMethod,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'],
      amountCents: json['amount_cents'],
      status: json['status'],
      paymentMethod: json['payment_method_type'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
