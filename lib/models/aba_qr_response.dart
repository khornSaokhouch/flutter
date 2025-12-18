class AbaQrResponse {
  final String tranId;
  final String? qrString;
  final String? qrImage;
  final String? deeplink;
  final String status;

  AbaQrResponse({
    required this.tranId,
    this.qrString,
    this.qrImage,
    this.deeplink,
    required this.status,
  });

  factory AbaQrResponse.fromJson(Map<String, dynamic> json) {
    return AbaQrResponse(
      tranId: json['tran_id'],
      qrString: json['qr_string'],
      qrImage: json['qr_image'],
      deeplink: json['deeplink'],
      status: json['status'],
    );
  }
}
