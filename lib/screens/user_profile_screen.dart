import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/response.dart';
import '../providers/auth_provider.dart';
import '../providers/response_provider.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) return;
    await context.read<ResponseProvider>().fetchMyServiceRequests(token);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final responseProvider = context.watch<ResponseProvider>();
    final user = authProvider.user;

    if (user == null || user.isGuest) {
      return Scaffold(
        appBar: AppBar(title: const Text('ملفي')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('سجّل الدخول لعرض طلباتك وعقودك.'),
          ),
        ),
      );
    }

    final requests = responseProvider.myServiceRequests;
    final contracts = requests
        .expand(
          (request) => request.contracts.map(
            (contract) => _ContractEntry(request: request, contract: contract),
          ),
        )
        .toList(growable: false);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ملفي'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'طلباتي'),
              Tab(text: 'عقودي'),
            ],
          ),
        ),
        body: Column(
          children: [
            _AccountHeader(
              name: user.username,
              email: user.email,
              customerTier: user.customerTier,
              requestsCount: requests.length,
              contractsCount: contracts.length,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  RefreshIndicator(
                    onRefresh: _load,
                    child: _RequestsTab(
                      isLoading: responseProvider.isLoadingMyServiceRequests,
                      requests: requests,
                    ),
                  ),
                  RefreshIndicator(
                    onRefresh: _load,
                    child: _ContractsTab(
                      isLoading: responseProvider.isLoadingMyServiceRequests,
                      contracts: contracts,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  final String name;
  final String email;
  final String customerTier;
  final int requestsCount;
  final int contractsCount;

  const _AccountHeader({
    required this.name,
    required this.email,
    required this.customerTier,
    required this.requestsCount,
    required this.contractsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            const Color(0xFFE50914).withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFE50914).withValues(alpha: 0.20),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white12),
                ),
                child: const Icon(Icons.account_circle, size: 34),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (email.trim().isNotEmpty)
                      Text(
                        email,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    const SizedBox(height: 10),
                    _CustomerTierBadge(customerTier: customerTier),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'طلباتي',
                  value: requestsCount.toString(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  label: 'عقودي',
                  value: contractsCount.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerTierBadge extends StatelessWidget {
  final String customerTier;

  const _CustomerTierBadge({required this.customerTier});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (customerTier) {
      'vip' => (
        'VIP Client',
        Colors.amberAccent,
        Icons.workspace_premium_outlined,
      ),
      'key_account' => (
        'Key Account',
        Colors.lightBlueAccent,
        Icons.business_center_outlined,
      ),
      _ => ('Regular Client', Colors.white70, Icons.verified_user_outlined),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _RequestsTab extends StatelessWidget {
  final bool isLoading;
  final List<ClientResponse> requests;

  const _RequestsTab({required this.isLoading, required this.requests});

  @override
  Widget build(BuildContext context) {
    if (isLoading && requests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (requests.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 60),
          Icon(Icons.assignment_outlined, size: 56, color: Colors.white38),
          SizedBox(height: 12),
          Center(child: Text('لا توجد طلبات خدمات مرتبطة بحسابك حتى الآن.')),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _RequestCard(request: requests[index]),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final ClientResponse request;

  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final phone = [
      request.clientPhoneDialCode,
      request.clientPhoneNumber,
    ].where((part) => (part ?? '').trim().isNotEmpty).join(' ');

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.serviceTitle ??
                          request.serviceCategory ??
                          'طلب خدمة',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(request.createdAt),
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(
                label: _requestStatusLabel(request.status),
                color: _requestStatusColor(request.status),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            request.message,
            style: const TextStyle(color: Colors.white70, height: 1.55),
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoLine(label: 'الجوال', value: phone),
          ],
          if ((request.adminReply ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE50914).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE50914).withValues(alpha: 0.24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'رد الإدارة',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    request.adminReply!,
                    style: const TextStyle(color: Colors.white70, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
          if (request.contracts.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'العقود المرتبطة: ${request.contracts.length}',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContractsTab extends StatelessWidget {
  final bool isLoading;
  final List<_ContractEntry> contracts;

  const _ContractsTab({required this.isLoading, required this.contracts});

  @override
  Widget build(BuildContext context) {
    if (isLoading && contracts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (contracts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 60),
          Icon(Icons.article_outlined, size: 56, color: Colors.white38),
          SizedBox(height: 12),
          Center(child: Text('لا توجد عقود مضافة إلى حسابك حتى الآن.')),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: contracts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _ContractCard(entry: contracts[index]),
    );
  }
}

class _ContractCard extends StatelessWidget {
  final _ContractEntry entry;

  const _ContractCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final contract = entry.contract;
    final request = entry.request;

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contract.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'مرتبط بطلب: ${request.serviceTitle ?? request.serviceCategory ?? 'طلب خدمة'}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              _StatusChip(
                label: _contractStatusLabel(contract.status),
                color: _contractStatusColor(contract.status),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'قراءة فقط',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          if ((contract.contractNumber ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoLine(
              label: 'رقم العقد',
              value: contract.contractNumber!.trim(),
            ),
          ],
          if ((contract.description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              contract.description!.trim(),
              style: const TextStyle(color: Colors.white70, height: 1.55),
            ),
          ],
          if ((contract.documentUrl ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoLine(label: 'رابط الملف', value: contract.documentUrl!.trim()),
          ],
          if (contract.createdAt != null) ...[
            const SizedBox(height: 10),
            _InfoLine(
              label: 'تاريخ الإضافة',
              value: _formatDate(contract.createdAt!),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w800)),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ContractEntry {
  final ClientResponse request;
  final ResponseContract contract;

  const _ContractEntry({required this.request, required this.contract});
}

String _formatDate(DateTime value) {
  return DateFormat('yyyy/MM/dd - hh:mm a').format(value.toLocal());
}

String _requestStatusLabel(String status) {
  switch (status) {
    case 'approved':
      return 'مقبول';
    case 'rejected':
      return 'مرفوض';
    case 'replied':
      return 'تم الرد';
    case 'resolved':
      return 'مغلق';
    default:
      return 'قيد المراجعة';
  }
}

Color _requestStatusColor(String status) {
  switch (status) {
    case 'approved':
      return Colors.green;
    case 'rejected':
      return Colors.redAccent;
    case 'replied':
      return Colors.blueAccent;
    case 'resolved':
      return Colors.tealAccent;
    default:
      return Colors.orangeAccent;
  }
}

String _contractStatusLabel(String status) {
  switch (status) {
    case 'draft':
      return 'مسودة';
    case 'signed':
      return 'موقّع';
    case 'completed':
      return 'مكتمل';
    case 'cancelled':
      return 'ملغي';
    default:
      return 'نشط';
  }
}

Color _contractStatusColor(String status) {
  switch (status) {
    case 'draft':
      return Colors.orangeAccent;
    case 'signed':
      return Colors.blueAccent;
    case 'completed':
      return Colors.greenAccent;
    case 'cancelled':
      return Colors.redAccent;
    default:
      return const Color(0xFFE50914);
  }
}
