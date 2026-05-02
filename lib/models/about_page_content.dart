import '../config/company_info.dart';
import 'content_asset.dart';

class AboutPageContent {
  final String? id;
  final String heroTitle;
  final String heroSubtitle;
  final String intro;
  final CompanyProfile companyProfile;
  final List<AboutSection> sections;
  final DateTime? updatedAt;

  const AboutPageContent({
    this.id,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.intro,
    this.companyProfile = const CompanyProfile.empty(),
    this.sections = const [],
    this.updatedAt,
  });

  const AboutPageContent.empty()
    : id = null,
      heroTitle = 'من نحن',
      heroSubtitle = '',
      intro = '',
      companyProfile = const CompanyProfile.defaults(),
      sections = const [],
      updatedAt = null;

  factory AboutPageContent.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'];
    final rawCompanyProfile = json['companyProfile'];

    return AboutPageContent(
      id: json['_id']?.toString(),
      heroTitle: (json['heroTitle'] ?? 'من نحن').toString(),
      heroSubtitle: (json['heroSubtitle'] ?? '').toString(),
      intro: (json['intro'] ?? '').toString(),
      companyProfile: rawCompanyProfile is Map<String, dynamic>
          ? CompanyProfile.fromJson(rawCompanyProfile)
          : rawCompanyProfile is Map
          ? CompanyProfile.fromJson(
              Map<String, dynamic>.from(rawCompanyProfile),
            )
          : const CompanyProfile.defaults(),
      sections: rawSections is List
          ? rawSections
                .whereType<Map<String, dynamic>>()
                .map(AboutSection.fromJson)
                .toList(growable: false)
          : const [],
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.tryParse(json['updatedAt'].toString()),
    );
  }
}

class CompanyProfile {
  final String commercialRegister;
  final String taxNumber;
  final String addressAr;
  final String addressEn;
  final String phone;
  final String email;
  final String website;
  final String whatsapp;

  const CompanyProfile({
    required this.commercialRegister,
    required this.taxNumber,
    required this.addressAr,
    required this.addressEn,
    required this.phone,
    required this.email,
    required this.website,
    required this.whatsapp,
  });

  const CompanyProfile.empty()
    : commercialRegister = '',
      taxNumber = '',
      addressAr = '',
      addressEn = '',
      phone = '',
      email = '',
      website = '',
      whatsapp = '';

  const CompanyProfile.defaults()
    : commercialRegister = CompanyInfo.commercialRegister,
      taxNumber = CompanyInfo.taxNumber,
      addressAr = CompanyInfo.addressAr,
      addressEn = CompanyInfo.addressEn,
      phone = CompanyInfo.phone,
      email = CompanyInfo.email,
      website = CompanyInfo.website,
      whatsapp = CompanyInfo.whatsapp;

  factory CompanyProfile.fromJson(Map<String, dynamic> json) {
    return CompanyProfile(
      commercialRegister: (json['commercialRegister'] ?? '').toString(),
      taxNumber: (json['taxNumber'] ?? '').toString(),
      addressAr: (json['addressAr'] ?? '').toString(),
      addressEn: (json['addressEn'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      website: (json['website'] ?? '').toString(),
      whatsapp: (json['whatsapp'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'commercialRegister': commercialRegister,
    'taxNumber': taxNumber,
    'addressAr': addressAr,
    'addressEn': addressEn,
    'phone': phone,
    'email': email,
    'website': website,
    'whatsapp': whatsapp,
  };
}

class AboutSection {
  final String? id;
  final String title;
  final String body;
  final int order;
  final List<ContentAsset> media;

  const AboutSection({
    this.id,
    required this.title,
    required this.body,
    this.order = 0,
    this.media = const [],
  });

  factory AboutSection.fromJson(Map<String, dynamic> json) {
    final rawMedia = json['media'];
    return AboutSection(
      id: json['_id']?.toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      order: json['order'] is int
          ? json['order']
          : int.tryParse(json['order']?.toString() ?? '') ?? 0,
      media: rawMedia is List
          ? rawMedia
                .whereType<Map<String, dynamic>>()
                .map(ContentAsset.fromJson)
                .toList(growable: false)
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null && id!.isNotEmpty) '_id': id,
    'title': title,
    'body': body,
    'order': order,
    'media': media.map((item) => item.toJson()).toList(growable: false),
  };
}
