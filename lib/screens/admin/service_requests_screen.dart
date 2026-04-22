import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/response_provider.dart';

class AdminServiceRequestsScreen extends StatefulWidget {
  const AdminServiceRequestsScreen({super.key});

  @override
  State<AdminServiceRequestsScreen> createState() =>
      _AdminServiceRequestsScreenState();
}

class _AdminServiceRequestsScreenState
    extends State<AdminServiceRequestsScreen> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final responseProvider = Provider.of<ResponseProvider>(
      context,
      listen: false,
    );
    final token = authProvider.token;
    if (token == null || token.isEmpty) return;
    await responseProvider.fetchServiceRequests(token);
  }

  Future<void> _setStatus(String id, String status) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final responseProvider = Provider.of<ResponseProvider>(
      context,
      listen: false,
    );
    final token = authProvider.token;
    if (token == null || token.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await responseProvider.updateResponseStatus(
        id: id,
        status: status,
        token: token,
      );
      await responseProvider.fetchServiceRequests(token);
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Updated')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _showReplyDialog(String id, String currentReply) async {
    final replyController = TextEditingController(text: currentReply);
    final messenger = ScaffoldMessenger.of(context);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reply to Service Request'),
        content: TextField(
          controller: replyController,
          decoration: const InputDecoration(
            labelText: 'Your Reply',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              final responseProvider = Provider.of<ResponseProvider>(
                context,
                listen: false,
              );
              final token = authProvider.token;
              if (token == null || token.isEmpty) return;

              try {
                await responseProvider.replyToResponse(
                  id,
                  replyController.text,
                  token,
                  refreshServiceRequests: true,
                );
                if (!mounted) return;
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Reply sent successfully')),
                );
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
              }
            },
            child: const Text('Send Reply'),
          ),
        ],
      ),
    ).whenComplete(replyController.dispose);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'replied':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final responseProvider = Provider.of<ResponseProvider>(context);
    final items = responseProvider.serviceRequests
        .where((r) => r.serviceCategory != null)
        .toList(growable: false);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'طلبات الخدمات',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
              IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        Expanded(
          child: responseProvider.isLoadingServiceRequests
              ? const Center(child: CircularProgressIndicator())
              : items.isEmpty
              ? const Center(child: Text('No service requests yet'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final response = items[index];
                    final phone =
                        [
                              response.clientPhoneDialCode,
                              response.clientPhoneNumber,
                            ]
                            .where((s) => (s ?? '').trim().isNotEmpty)
                            .map((s) => s!.trim())
                            .join(' ');
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: _statusColor(response.status),
                          child: const Icon(
                            Icons.assignment_outlined,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(response.clientName),
                        subtitle: Text(
                          '${response.serviceTitle ?? response.serviceCategory ?? ''}\n'
                          '${response.clientEmail}'
                          '${phone.isEmpty ? '' : '\n$phone'}',
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Message:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(response.message),
                                const SizedBox(height: 12),
                                if (response.adminReply != null &&
                                    response.adminReply!.trim().isNotEmpty) ...[
                                  const Text(
                                    'Admin Reply:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(response.adminReply!),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  alignment: WrapAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          _setStatus(response.id, 'approved'),
                                      icon: const Icon(Icons.check_circle),
                                      label: const Text('Approve'),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          _setStatus(response.id, 'rejected'),
                                      icon: const Icon(Icons.cancel),
                                      label: const Text('Reject'),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => _showReplyDialog(
                                        response.id,
                                        response.adminReply ?? '',
                                      ),
                                      icon: const Icon(Icons.reply),
                                      label: const Text('Reply'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
