import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/response_provider.dart';
import '../../providers/auth_provider.dart';

class AdminResponsesScreen extends StatefulWidget {
  const AdminResponsesScreen({super.key});

  @override
  State<AdminResponsesScreen> createState() => _AdminResponsesScreenState();
}

class _AdminResponsesScreenState extends State<AdminResponsesScreen> {
  @override
  void initState() {
    super.initState();
    _loadResponses();
  }

  Future<void> _loadResponses() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final responseProvider = Provider.of<ResponseProvider>(
      context,
      listen: false,
    );
    await responseProvider.fetchResponses(authProvider.token!);
  }

  Future<void> _showReplyDialog(String id, String currentReply) async {
    final replyController = TextEditingController(text: currentReply);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reply to Feedback'),
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
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              final responseProvider = Provider.of<ResponseProvider>(
                context,
                listen: false,
              );
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              await responseProvider.replyToResponse(
                id,
                replyController.text,
                authProvider.token!,
              );

              if (!mounted) return;
              navigator.pop();
              messenger.showSnackBar(
                const SnackBar(content: Text('Reply sent successfully')),
              );
            },
            child: const Text('Send Reply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responseProvider = Provider.of<ResponseProvider>(context);
    final responses = responseProvider.responses
        .where((r) => r.serviceCategory == null)
        .toList(growable: false);

    if (responseProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (responses.isEmpty) {
      return const Center(child: Text('No responses yet'));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: responses.length,
      itemBuilder: (context, index) {
        final response = responses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: response.status == 'pending'
                          ? Colors.orange
                          : Colors.green,
                      child: Text(
                        response.rating?.toString() ?? '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(response.clientName),
                    subtitle: Text(response.clientEmail),
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
                            if (response.rating != null) ...[
                              const Text(
                                'Rating:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: List.generate(
                                  response.rating!,
                                  (index) => const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (response.adminReply != null) ...[
                              const Text(
                                'Admin Reply:',
                                style: TextStyle(fontWeight: FontWeight.bold),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
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
    );
  }
}
