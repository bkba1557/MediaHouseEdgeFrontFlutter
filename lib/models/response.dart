class ClientResponse {
  final String id;
  final String clientName;
  final String clientEmail;
  final String message;
  final String? mediaId;
  final int? rating;
  final String status;
  final String? adminReply;
  final DateTime createdAt;

  ClientResponse({
    required this.id,
    required this.clientName,
    required this.clientEmail,
    required this.message,
    this.mediaId,
    this.rating,
    required this.status,
    this.adminReply,
    required this.createdAt,
  });

  factory ClientResponse.fromJson(Map<String, dynamic> json) {
    return ClientResponse(
      id: json['_id'],
      clientName: json['clientName'],
      clientEmail: json['clientEmail'],
      message: json['message'],
      mediaId: json['mediaId']?['_id'] ?? json['mediaId'],
      rating: json['rating'],
      status: json['status'],
      adminReply: json['adminReply'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
