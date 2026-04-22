import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/response_provider.dart';

class _PhoneCountry {
  final String nameAr;
  final String iso2;
  final String dialCode;
  final String flag;

  const _PhoneCountry({
    required this.nameAr,
    required this.iso2,
    required this.dialCode,
    required this.flag,
  });
}

const List<_PhoneCountry> _phoneCountries = [
  _PhoneCountry(nameAr: 'السعودية', iso2: 'SA', dialCode: '+966', flag: '🇸🇦'),
  _PhoneCountry(nameAr: 'الإمارات', iso2: 'AE', dialCode: '+971', flag: '🇦🇪'),
  _PhoneCountry(nameAr: 'الكويت', iso2: 'KW', dialCode: '+965', flag: '🇰🇼'),
  _PhoneCountry(nameAr: 'قطر', iso2: 'QA', dialCode: '+974', flag: '🇶🇦'),
  _PhoneCountry(nameAr: 'البحرين', iso2: 'BH', dialCode: '+973', flag: '🇧🇭'),
  _PhoneCountry(nameAr: 'عُمان', iso2: 'OM', dialCode: '+968', flag: '🇴🇲'),
  _PhoneCountry(nameAr: 'مصر', iso2: 'EG', dialCode: '+20', flag: '🇪🇬'),
  _PhoneCountry(nameAr: 'الأردن', iso2: 'JO', dialCode: '+962', flag: '🇯🇴'),
  _PhoneCountry(nameAr: 'لبنان', iso2: 'LB', dialCode: '+961', flag: '🇱🇧'),
  _PhoneCountry(nameAr: 'العراق', iso2: 'IQ', dialCode: '+964', flag: '🇮🇶'),
  _PhoneCountry(nameAr: 'المغرب', iso2: 'MA', dialCode: '+212', flag: '🇲🇦'),
  _PhoneCountry(nameAr: 'تونس', iso2: 'TN', dialCode: '+216', flag: '🇹🇳'),
  _PhoneCountry(nameAr: 'الجزائر', iso2: 'DZ', dialCode: '+213', flag: '🇩🇿'),
  _PhoneCountry(nameAr: 'أمريكا', iso2: 'US', dialCode: '+1', flag: '🇺🇸'),
  _PhoneCountry(nameAr: 'بريطانيا', iso2: 'GB', dialCode: '+44', flag: '🇬🇧'),
];

Future<void> showServiceRequestSheet(
  BuildContext context, {
  required String serviceCategory,
  required String serviceTitle,
}) async {
  final user = Provider.of<AuthProvider>(context, listen: false).user;
  final nameController = TextEditingController(text: user?.username ?? '');
  final emailController = TextEditingController(text: user?.email ?? '');
  final phoneController = TextEditingController();
  final messageController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  _PhoneCountry selectedCountry = _phoneCountries.firstWhere(
    (c) => c.iso2 == 'SA',
    orElse: () => _phoneCountries.first,
  );

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final viewInsets = MediaQuery.viewInsetsOf(context);
          final width = MediaQuery.sizeOf(context).width;
          final isNarrow = width < 420;

          return Padding(
            padding: EdgeInsets.only(bottom: viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0E0E0E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'تقديم طلب الخدمة',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        Text(
                          serviceTitle,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'الاسم',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'اكتب اسمك';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) {
                              return 'اكتب بريدك الإلكتروني';
                            }
                            if (!text.contains('@')) {
                              return 'بريد غير صحيح';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: isNarrow ? 128 : 168,
                              child: DropdownButtonFormField<_PhoneCountry>(
                                value: selectedCountry,
                                decoration: const InputDecoration(
                                  labelText: 'الدولة',
                                  border: OutlineInputBorder(),
                                ),
                                dropdownColor: const Color(0xFF1A1A1A),
                                items: _phoneCountries
                                    .map(
                                      (c) => DropdownMenuItem<_PhoneCountry>(
                                        value: c,
                                        child: Text(
                                          '${c.flag} ${c.dialCode}',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => selectedCountry = value);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: phoneController,
                                keyboardType: TextInputType.phone,
                                inputFormatters: const [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  labelText: 'رقم الجوال',
                                  hintText: selectedCountry.iso2 == 'SA'
                                      ? '5xxxxxxxx'
                                      : null,
                                  border: const OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  final text = value?.trim() ?? '';
                                  if (text.isEmpty) {
                                    return 'اكتب رقم الجوال';
                                  }
                                  if (text.length < 7 || text.length > 15) {
                                    return 'رقم الجوال غير صحيح';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: messageController,
                          minLines: 3,
                          maxLines: 6,
                          decoration: const InputDecoration(
                            labelText: 'تفاصيل الطلب',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'اكتب تفاصيل الطلب';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Consumer<ResponseProvider>(
                          builder: (context, responseProvider, _) {
                            return ElevatedButton.icon(
                              onPressed:
                                  responseProvider.isSubmittingServiceRequest
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) {
                                        return;
                                      }
                                      final navigator = Navigator.of(context);
                                      final messenger = ScaffoldMessenger.of(
                                        context,
                                      );
                                      try {
                                        await Provider.of<ResponseProvider>(
                                          context,
                                          listen: false,
                                        ).submitServiceRequest(
                                          serviceCategory: serviceCategory,
                                          serviceTitle: serviceTitle,
                                          clientName: nameController.text
                                              .trim(),
                                          clientEmail: emailController.text
                                              .trim(),
                                          clientPhoneCountry:
                                              selectedCountry.nameAr,
                                          clientPhoneDialCode:
                                              selectedCountry.dialCode,
                                          clientPhoneNumber: phoneController
                                              .text
                                              .trim(),
                                          message: messageController.text
                                              .trim(),
                                        );
                                        navigator.pop();
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'تم إرسال طلبك بنجاح',
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text('فشل الإرسال: $e'),
                                          ),
                                        );
                                      }
                                    },
                              icon: const Icon(Icons.send),
                              label: const Text('إرسال الطلب'),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );

  nameController.dispose();
  emailController.dispose();
  phoneController.dispose();
  messageController.dispose();
}
