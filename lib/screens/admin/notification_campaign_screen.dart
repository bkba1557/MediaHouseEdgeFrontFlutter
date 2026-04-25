import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/admin_user.dart';
import '../../providers/notification_provider.dart';
import '../../providers/user_management_provider.dart';

class AdminNotificationCampaignScreen extends StatefulWidget {
  const AdminNotificationCampaignScreen({super.key});

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
    if (!_formKey.currentState!.validate()) return;
    if (_audience == 'single_user' &&
        (_selectedUserId == null || _selectedUserId!.isEmpty)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a client first')));
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

      _titleController.clear();
      _bodyController.clear();
      setState(() => _selectedUserId = null);

      messenger.showSnackBar(
        const SnackBar(content: Text('Notification sent successfully')),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();
    final userProvider = context.watch<UserManagementProvider>();
    final users = userProvider.users.where((user) => user.isClient).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
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
                const Text(
                  'Promotional Notifications',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Send an offer or announcement to all clients or a selected client.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: _audience,
                  decoration: const InputDecoration(
                    labelText: 'Audience',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'all_clients',
                      child: Text('All clients'),
                    ),
                    DropdownMenuItem(
                      value: 'single_user',
                      child: Text('Specific client'),
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
                    decoration: const InputDecoration(
                      labelText: 'Client',
                      border: OutlineInputBorder(),
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
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bodyController,
                  minLines: 4,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a message';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: userProvider.isLoading
                            ? null
                            : () => userProvider.fetchUsers(role: 'client'),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh Clients'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: notificationProvider.isSending
                            ? null
                            : _send,
                        icon: notificationProvider.isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_outlined),
                        label: Text(
                          notificationProvider.isSending
                              ? 'Sending...'
                              : 'Send',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _userLabel(AdminUser user) {
    final email = user.email.trim();
    if (email.isEmpty) return user.username;
    return '${user.username} - $email';
  }
}
