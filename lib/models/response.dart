class ClientResponse {
  final String id;
  final String clientName;
  final String clientEmail;
  final String? clientPhoneCountry;
  final String? clientPhoneDialCode;
  final String? clientPhoneNumber;
  final String message;
  final String? mediaId;
  final int? rating;
  final String status;
  final String? adminReply;
  final String? serviceCategory;
  final String? serviceTitle;
  final DateTime createdAt;

  ClientResponse({
    required this.id,
    required this.clientName,
    required this.clientEmail,
    this.clientPhoneCountry,
    this.clientPhoneDialCode,
    this.clientPhoneNumber,
    required this.message,
    this.mediaId,
    this.rating,
    required this.status,
    this.adminReply,
    this.serviceCategory,
    this.serviceTitle,
    required this.createdAt,
  });

  factory ClientResponse.fromJson(Map<String, dynamic> json) {
    return ClientResponse(
      id: json['_id'],
      clientName: json['clientName'],
      clientEmail: json['clientEmail'],
      clientPhoneCountry: json['clientPhoneCountry'],
      clientPhoneDialCode: json['clientPhoneDialCode'],
      clientPhoneNumber: json['clientPhoneNumber'],
      message: json['message'],
      mediaId: json['mediaId']?['_id'] ?? json['mediaId'],
      rating: json['rating'],
      status: json['status'],
      adminReply: json['adminReply'],
      serviceCategory: json['serviceCategory'],
      serviceTitle: json['serviceTitle'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
