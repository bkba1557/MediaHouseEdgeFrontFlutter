import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../localization/app_localizations.dart';
import '../../models/admin_user.dart';
import '../../providers/user_management_provider.dart';

class AdminUserManagementScreen extends StatefulWidget {
  final bool embedded;

  const AdminUserManagementScreen({super.key, this.embedded = false});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UserManagementProvider>().fetchUsers(role: '');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserManagementProvider>();
    final users = provider.users;

    final content = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final horizontalPadding = width < 720 ? 12.0 : 24.0;
        final isNarrow = width < 820;

        final searchField = TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: context.tr(
              'ابحث بالاسم أو البريد',
              fallback: 'Search by username or email',
            ),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              onPressed: () async {
                _searchController.clear();
                await provider.fetchUsers(search: '', role: '');
              },
              icon: const Icon(Icons.clear),
              tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
            ),
            border: const OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (value) {
            provider.fetchUsers(search: value, role: '');
          },
        );

        final refreshButton = IconButton(
          onPressed: () =>
              provider.fetchUsers(search: _searchController.text, role: ''),
          icon: const Icon(Icons.refresh),
          tooltip: context.tr('تحديث', fallback: 'Refresh'),
        );

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                16,
                horizontalPadding,
                0,
              ),
              child: Column(
                children: [
                  if (isNarrow) ...[
                    searchField,
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: refreshButton,
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(child: searchField),
                        const SizedBox(width: 12),
                        refreshButton,
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Expanded(
                    child: provider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : users.isEmpty
                        ? Center(
                            child: Text(
                              context.tr(
                                'لا يوجد مستخدمون',
                                fallback: 'No users found',
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: users.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final user = users[index];
                              return _AdminUserCard(user: user);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (widget.embedded) return content;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('إدارة المستخدمين', fallback: 'Manage Users')),
        backgroundColor: const Color(0xFFE50914),
      ),
      body: SafeArea(child: content),
    );
  }
}

class _AdminUserCard extends StatelessWidget {
  final AdminUser user;

  const _AdminUserCard({required this.user});

  String _roleLabel(BuildContext context, String role) {
    switch (role.trim().toLowerCase()) {
      case 'admin':
        return context.tr('مدير', fallback: 'ADMIN');
      case 'client':
        return context.tr('عميل', fallback: 'CLIENT');
      case 'guest':
        return context.tr('زائر', fallback: 'GUEST');
      default:
        return role.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserManagementProvider>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: const Color(
                  0xFFE50914,
                ).withValues(alpha: 0.18),
                child: const Icon(Icons.person_outline),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (user.email.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          user.email,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaChip(label: _roleLabel(context, user.role)),
                        _MetaChip(
                          label: context.tr(
                            'رموز الدفع: {count}',
                            fallback:
                                '${user.notificationTokenCount} push token(s)',
                            params: {'count': '${user.notificationTokenCount}'},
                          ),
                        ),
                        if (user.createdAt != null)
                          _MetaChip(
                            label: DateFormat(
                              'yyyy/MM/dd',
                            ).format(user.createdAt!.toLocal()),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: DropdownButtonFormField<String>(
                initialValue: user.customerTier,
                decoration: InputDecoration(
                  labelText: context.tr(
                    'فئة العميل',
                    fallback: 'Customer tier',
                  ),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'regular',
                    child: Text(context.tr('عادي', fallback: 'Regular')),
                  ),
                  DropdownMenuItem(
                    value: 'vip',
                    child: Text(context.tr('مميز', fallback: 'VIP')),
                  ),
                  DropdownMenuItem(
                    value: 'key_account',
                    child: Text(
                      context.tr('حساب رئيسي', fallback: 'Key Account'),
                    ),
                  ),
                ],
                onChanged: !user.isClient || provider.isUpdating(user.id)
                    ? null
                    : (value) async {
                        if (value == null || value == user.customerTier) return;
                        try {
                          await context
                              .read<UserManagementProvider>()
                              .updateCustomerTier(
                                userId: user.id,
                                customerTier: value,
                              );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.tr(
                                  'تم تحديث فئة العميل',
                                  fallback: 'Customer tier updated',
                                ),
                              ),
                            ),
                          );
                        } catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('$error')));
                        }
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
