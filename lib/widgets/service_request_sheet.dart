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

class _ArText {
  static const sheetTitle =
      '\u062A\u0642\u062F\u064A\u0645 \u0637\u0644\u0628 \u0627\u0644\u062E\u062F\u0645\u0629';
  static const nameLabel = '\u0627\u0644\u0627\u0633\u0645';
  static const nameRequired =
      '\u0627\u0643\u062A\u0628 \u0627\u0633\u0645\u0643';
  static const emailLabel =
      '\u0627\u0644\u0628\u0631\u064A\u062F \u0627\u0644\u0625\u0644\u0643\u062A\u0631\u0648\u0646\u064A';
  static const emailRequired =
      '\u0627\u0643\u062A\u0628 \u0628\u0631\u064A\u062F\u0643 \u0627\u0644\u0625\u0644\u0643\u062A\u0631\u0648\u0646\u064A';
  static const emailInvalid =
      '\u0628\u0631\u064A\u062F \u063A\u064A\u0631 \u0635\u062D\u064A\u062D';
  static const countryLabel = '\u0627\u0644\u062F\u0648\u0644\u0629';
  static const phoneLabel =
      '\u0631\u0642\u0645 \u0627\u0644\u062C\u0648\u0627\u0644';
  static const phoneRequired =
      '\u0627\u0643\u062A\u0628 \u0631\u0642\u0645 \u0627\u0644\u062C\u0648\u0627\u0644';
  static const phoneInvalid =
      '\u0631\u0642\u0645 \u0627\u0644\u062C\u0648\u0627\u0644 \u063A\u064A\u0631 \u0635\u062D\u064A\u062D';
  static const detailsLabel =
      '\u062A\u0641\u0627\u0635\u064A\u0644 \u0627\u0644\u0637\u0644\u0628';
  static const detailsRequired =
      '\u0627\u0643\u062A\u0628 \u062A\u0641\u0627\u0635\u064A\u0644 \u0627\u0644\u0637\u0644\u0628';
  static const sendLabel =
      '\u0625\u0631\u0633\u0627\u0644 \u0627\u0644\u0637\u0644\u0628';
  static const sentOk =
      '\u062A\u0645 \u0625\u0631\u0633\u0627\u0644 \u0637\u0644\u0628\u0643 \u0628\u0646\u062C\u0627\u062D';
  static const sendFailedPrefix =
      '\u0641\u0634\u0644 \u0627\u0644\u0625\u0631\u0633\u0627\u0644';
}

const List<_PhoneCountry> _phoneCountries = [
  _PhoneCountry(
    nameAr: '\u0627\u0644\u0633\u0639\u0648\u062F\u064A\u0629',
    iso2: 'SA',
    dialCode: '+966',
    flag: '\u{1F1F8}\u{1F1E6}',
  ),
  _PhoneCountry(
    nameAr: '\u0627\u0644\u0625\u0645\u0627\u0631\u0627\u062A',
    iso2: 'AE',
    dialCode: '+971',
    flag: '\u{1F1E6}\u{1F1EA}',
  ),
  _PhoneCountry(
    nameAr: '\u0627\u0644\u0643\u0648\u064A\u062A',
    iso2: 'KW',
    dialCode: '+965',
    flag: '\u{1F1F0}\u{1F1FC}',
  ),
  _PhoneCountry(
    nameAr: '\u0642\u0637\u0631',
    iso2: 'QA',
    dialCode: '+974',
    flag: '\u{1F1F6}\u{1F1E6}',
  ),
  _PhoneCountry(
    nameAr: '\u0627\u0644\u0628\u062D\u0631\u064A\u0646',
    iso2: 'BH',
    dialCode: '+973',
    flag: '\u{1F1E7}\u{1F1ED}',
  ),
  _PhoneCountry(
    nameAr: '\u0639\u0645\u0627\u0646',
    iso2: 'OM',
    dialCode: '+968',
    flag: '\u{1F1F4}\u{1F1F2}',
  ),
  _PhoneCountry(
    nameAr: '\u0645\u0635\u0631',
    iso2: 'EG',
    dialCode: '+20',
    flag: '\u{1F1EA}\u{1F1EC}',
  ),
  _PhoneCountry(
    nameAr: '\u0627\u0644\u0623\u0631\u062F\u0646',
    iso2: 'JO',
    dialCode: '+962',
    flag: '\u{1F1EF}\u{1F1F4}',
  ),
  _PhoneCountry(
    nameAr: '\u0644\u0628\u0646\u0627\u0646',
    iso2: 'LB',
    dialCode: '+961',
    flag: '\u{1F1F1}\u{1F1E7}',
  ),
  _PhoneCountry(
    nameAr: '\u0627\u0644\u0639\u0631\u0627\u0642',
    iso2: 'IQ',
    dialCode: '+964',
    flag: '\u{1F1EE}\u{1F1F6}',
  ),
  _PhoneCountry(
    nameAr: '\u0627\u0644\u0645\u063A\u0631\u0628',
    iso2: 'MA',
    dialCode: '+212',
    flag: '\u{1F1F2}\u{1F1E6}',
  ),
  _PhoneCountry(
    nameAr: '\u062A\u0648\u0646\u0633',
    iso2: 'TN',
    dialCode: '+216',
    flag: '\u{1F1F9}\u{1F1F3}',
  ),
  _PhoneCountry(
    nameAr: '\u0627\u0644\u062C\u0632\u0627\u0626\u0631',
    iso2: 'DZ',
    dialCode: '+213',
    flag: '\u{1F1E9}\u{1F1FF}',
  ),
  _PhoneCountry(
    nameAr: '\u0623\u0645\u0631\u064A\u0643\u0627',
    iso2: 'US',
    dialCode: '+1',
    flag: '\u{1F1FA}\u{1F1F8}',
  ),
  _PhoneCountry(
    nameAr: '\u0628\u0631\u064A\u0637\u0627\u0646\u064A\u0627',
    iso2: 'GB',
    dialCode: '+44',
    flag: '\u{1F1EC}\u{1F1E7}',
  ),
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
                                _ArText.sheetTitle,
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
                            labelText: _ArText.nameLabel,
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return _ArText.nameRequired;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: _ArText.emailLabel,
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) {
                              return _ArText.emailRequired;
                            }
                            if (!text.contains('@')) {
                              return _ArText.emailInvalid;
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
                                initialValue: selectedCountry,
                                decoration: const InputDecoration(
                                  labelText: _ArText.countryLabel,
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
                                  if (value == null) {
                                    return;
                                  }
                                  setState(() => selectedCountry = value);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: phoneController,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  labelText: _ArText.phoneLabel,
                                  hintText: selectedCountry.iso2 == 'SA'
                                      ? '5xxxxxxxx'
                                      : null,
                                  border: const OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  final text = value?.trim() ?? '';
                                  if (text.isEmpty) {
                                    return _ArText.phoneRequired;
                                  }
                                  if (text.length < 7 || text.length > 15) {
                                    return _ArText.phoneInvalid;
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
                            labelText: _ArText.detailsLabel,
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return _ArText.detailsRequired;
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
                                      final authProvider =
                                          Provider.of<AuthProvider>(
                                            context,
                                            listen: false,
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
                                          token: authProvider.token,
                                        );
                                        navigator.pop();
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(_ArText.sentOk),
                                          ),
                                        );
                                      } catch (e) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '${_ArText.sendFailedPrefix}: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                              icon: const Icon(Icons.send),
                              label: const Text(_ArText.sendLabel),
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
