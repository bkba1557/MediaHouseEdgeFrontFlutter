import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../localization/app_localizations.dart';
import '../../models/admin_user.dart';
import '../../providers/notification_provider.dart';
import '../../providers/user_management_provider.dart';

class AdminNotificationCampaignScreen extends StatefulWidget {
  final bool embedded;

  const AdminNotificationCampaignScreen({super.key, this.embedded = false});

  @override
  State<AdminNotificationCampaignScreen> createState() =>
      _AdminNotificationCampaignScreenState();
}

class _AdminNotificationCampaignScreenState
    extends State<AdminNotificationCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  String _audience = 'all_clients';
  String? _selectedUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UserManagementProvider>().fetchUsers(role: 'client');
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final selectClientMessage = context.tr(
      'اختر عميلًا أولًا',
      fallback: 'Select a client first',
    );
    final successMessage = context.tr(
      'تم إرسال الإشعار بنجاح',
      fallback: 'Notification sent successfully',
    );

    if (!_formKey.currentState!.validate()) return;
    if (_audience == 'single_user' &&
        (_selectedUserId == null || _selectedUserId!.isEmpty)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(selectClientMessage)));
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    try {
      await context.read<NotificationProvider>().sendPromotion(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        audience: _audience,
        userId: _selectedUserId,
      );

      if (!mounted) return;
      _titleController.clear();
      _bodyController.clear();
      setState(() => _selectedUserId = null);

      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();
    final userProvider = context.watch<UserManagementProvider>();
    final users = userProvider.users.where((user) => user.isClient).toList();

    final body = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final horizontalPadding = width < 720 ? 12.0 : 24.0;
        final isNarrow = width < 940;

        final actions = isNarrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: userProvider.isLoading
                        ? null
                        : () => userProvider.fetchUsers(role: 'client'),
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      context.tr('تحديث العملاء', fallback: 'Refresh Clients'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: notificationProvider.isSending ? null : _send,
                    icon: notificationProvider.isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_outlined),
                    label: Text(
                      notificationProvider.isSending
                          ? context.tr(
                              'جارٍ الإرسال...',
                              fallback: 'Sending...',
                            )
                          : context.tr('إرسال', fallback: 'Send'),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: userProvider.isLoading
                          ? null
                          : () => userProvider.fetchUsers(role: 'client'),
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        context.tr(
                          'تحديث العملاء',
                          fallback: 'Refresh Clients',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: notificationProvider.isSending ? null : _send,
                      icon: notificationProvider.isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_outlined),
                      label: Text(
                        notificationProvider.isSending
                            ? context.tr(
                                'جارٍ الإرسال...',
                                fallback: 'Sending...',
                              )
                            : context.tr('إرسال', fallback: 'Send'),
                      ),
                    ),
                  ),
                ],
              );

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                16,
                horizontalPadding,
                24,
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(
                            'إشعارات ترويجية',
                            fallback: 'Promotional Notifications',
                          ),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.tr(
                            'أرسل عرضًا أو إعلانًا إلى جميع العملاء أو عميل محدد.',
                            fallback:
                                'Send an offer or announcement to all clients or a selected client.',
                          ),
                          style: const TextStyle(
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),
                        DropdownButtonFormField<String>(
                          initialValue: _audience,
                          decoration: InputDecoration(
                            labelText: context.tr(
                              'الجمهور',
                              fallback: 'Audience',
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'all_clients',
                              child: Text(
                                context.tr(
                                  'كل العملاء',
                                  fallback: 'All clients',
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'single_user',
                              child: Text(
                                context.tr(
                                  'عميل محدد',
                                  fallback: 'Specific client',
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _audience = value ?? 'all_clients';
                              if (_audience != 'single_user') {
                                _selectedUserId = null;
                              }
                            });
                          },
                        ),
                        if (_audience == 'single_user') ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedUserId,
                            decoration: InputDecoration(
                              labelText: context.tr(
                                'العميل',
                                fallback: 'Client',
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            items: users
                                .map(
                                  (user) => DropdownMenuItem(
                                    value: user.id,
                                    child: Text(_userLabel(user)),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (value) {
                              setState(() => _selectedUserId = value);
                            },
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: context.tr('العنوان', fallback: 'Title'),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return context.tr(
                                'أدخل العنوان',
                                fallback: 'Enter a title',
                              );
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _bodyController,
                          minLines: 4,
                          maxLines: 6,
                          decoration: InputDecoration(
                            labelText: context.tr(
                              'الرسالة',
                              fallback: 'Message',
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return context.tr(
                                'أدخل الرسالة',
                                fallback: 'Enter a message',
                              );
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        actions,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('إرسال العروض', fallback: 'Send Promotions')),
        backgroundColor: const Color(0xFFE50914),
      ),
      body: SafeArea(child: body),
    );
  }

  String _userLabel(AdminUser user) {
    final email = user.email.trim();
    if (email.isEmpty) return user.username;
    return '${user.username} - $email';
  }
}
