class ResponseContract {
  final String id;
  final String title;
  final String? contractNumber;
  final String status;
  final String? description;
  final String? documentUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ResponseContract({
    required this.id,
    required this.title,
    this.contractNumber,
    required this.status,
    this.description,
    this.documentUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory ResponseContract.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      final raw = value?.toString();
      if (raw == null || raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    }

    return ResponseContract(
      id: (json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      contractNumber: json['contractNumber']?.toString(),
      status: (json['status'] ?? 'active').toString(),
      description: json['description']?.toString(),
      documentUrl: json['documentUrl']?.toString(),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }
}

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
  final List<ResponseContract> contracts;
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
    this.contracts = const [],
    required this.createdAt,
  });

  factory ClientResponse.fromJson(Map<String, dynamic> json) {
    final rawContracts = json['contracts'];

    return ClientResponse(
      id: (json['_id'] ?? '').toString(),
      clientName: (json['clientName'] ?? '').toString(),
      clientEmail: (json['clientEmail'] ?? '').toString(),
      clientPhoneCountry: json['clientPhoneCountry'],
      clientPhoneDialCode: json['clientPhoneDialCode'],
      clientPhoneNumber: json['clientPhoneNumber'],
      message: (json['message'] ?? '').toString(),
      mediaId: json['mediaId']?['_id'] ?? json['mediaId'],
      rating: json['rating'],
      status: (json['status'] ?? 'pending').toString(),
      adminReply: json['adminReply'],
      serviceCategory: json['serviceCategory'],
      serviceTitle: json['serviceTitle'],
      contracts: rawContracts is List
          ? rawContracts
                .whereType<Map>()
                .map(
                  (contractJson) => ResponseContract.fromJson(
                    contractJson.cast<String, dynamic>(),
                  ),
                )
                .toList(growable: false)
          : const [],
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
