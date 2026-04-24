import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/response.dart';
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

  Future<void> _showAddContractDialog(ClientResponse response) async {
    final titleController = TextEditingController();
    final numberController = TextEditingController();
    final descriptionController = TextEditingController();
    final documentUrlController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var selectedStatus = 'active';
    final messenger = ScaffoldMessenger.of(context);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('إضافة عقد'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'عنوان العقد',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'اكتب عنوان العقد';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: numberController,
                      decoration: const InputDecoration(
                        labelText: 'رقم العقد',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'الحالة',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'draft', child: Text('مسودة')),
                        DropdownMenuItem(value: 'active', child: Text('نشط')),
                        DropdownMenuItem(value: 'signed', child: Text('موقّع')),
                        DropdownMenuItem(
                          value: 'completed',
                          child: Text('مكتمل'),
                        ),
                        DropdownMenuItem(
                          value: 'cancelled',
                          child: Text('ملغي'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => selectedStatus = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descriptionController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'وصف أو ملاحظات',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: documentUrlController,
                      decoration: const InputDecoration(
                        labelText: 'رابط الملف (اختياري)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('إلغاء'),
              ),
              Consumer<ResponseProvider>(
                builder: (context, responseProvider, _) {
                  return ElevatedButton(
                    onPressed: responseProvider.isSavingContract
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            final navigator = Navigator.of(dialogContext);
                            final token = context.read<AuthProvider>().token;
                            if (token == null || token.isEmpty) return;

                            try {
                              await responseProvider
                                  .addContractToServiceRequest(
                                    responseId: response.id,
                                    title: titleController.text.trim(),
                                    contractNumber: numberController.text
                                        .trim(),
                                    status: selectedStatus,
                                    description: descriptionController.text
                                        .trim(),
                                    documentUrl: documentUrlController.text
                                        .trim(),
                                    token: token,
                                  );
                              await responseProvider.fetchServiceRequests(
                                token,
                              );
                              if (!mounted) return;
                              navigator.pop();
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('تمت إضافة العقد'),
                                ),
                              );
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(content: Text('فشل الإضافة: $e')),
                              );
                            }
                          },
                    child: Text(
                      responseProvider.isSavingContract
                          ? 'جارٍ الحفظ...'
                          : 'حفظ العقد',
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );

    titleController.dispose();
    numberController.dispose();
    descriptionController.dispose();
    documentUrlController.dispose();
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
                                if (response.contracts.isNotEmpty) ...[
                                  const Text(
                                    'العقود المرتبطة:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...response.contracts.map(
                                    (contract) => Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            contract.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          if ((contract.contractNumber ?? '')
                                              .trim()
                                              .isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                              ),
                                              child: Text(
                                                'رقم العقد: ${contract.contractNumber}',
                                              ),
                                            ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Text(
                                              'الحالة: ${contract.status}',
                                            ),
                                          ),
                                          if ((contract.description ?? '')
                                              .trim()
                                              .isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                              ),
                                              child: Text(
                                                contract.description!.trim(),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
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
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          _showAddContractDialog(response),
                                      icon: const Icon(Icons.note_add_outlined),
                                      label: const Text('إضافة عقد'),
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
