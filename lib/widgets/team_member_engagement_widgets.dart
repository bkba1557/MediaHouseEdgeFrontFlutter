import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/team_member.dart';
import '../providers/auth_provider.dart';
import '../providers/team_provider.dart';
import '../services/visitor_identity_service.dart';

Future<void> showTeamMemberCommentsSheet(
  BuildContext context, {
  required TeamMember member,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return FractionallySizedBox(
        heightFactor: 0.88,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF121212),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: TeamMemberCommentsPanel(
                  memberId: member.id,
                  title: 'تعليقات ${member.name}',
                  compactComposer: false,
                  showCloseButton: true,
                  expandList: true,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class TeamMemberMetricChips extends StatelessWidget {
  final TeamMember member;
  final bool dense;

  const TeamMemberMetricChips({
    super.key,
    required this.member,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = theme.brightness == Brightness.light
        ? Colors.black87
        : Colors.white;
    final stats = [
      _MetricData(
        icon: Icons.visibility_outlined,
        value: '${member.viewsCount}',
        label: 'مشاهدة',
      ),
      _MetricData(
        icon: Icons.analytics_outlined,
        value: '${_formatPercent(member.viewSharePercent)}%',
        label: 'النسبة',
      ),
      _MetricData(
        icon: Icons.favorite_border,
        value: '${member.likesCount}',
        label: 'إعجاب',
      ),
      _MetricData(
        icon: Icons.mode_comment_outlined,
        value: '${member.commentsCount}',
        label: 'تعليق',
      ),
    ];

    return Row(
      children: [
        for (var index = 0; index < stats.length; index++) ...[
          if (index > 0) SizedBox(width: dense ? 6 : 8),
          Expanded(
            child: _MetricChip(
              icon: stats[index].icon,
              value: stats[index].value,
              label: stats[index].label,
              dense: dense,
              foreground: foreground,
            ),
          ),
        ],
      ],
    );
  }

  static String _formatPercent(double value) {
    final safeValue = value.isFinite ? value.clamp(0, 100) : 0.0;
    final rounded = safeValue.roundToDouble();
    if ((safeValue - rounded).abs() < 0.05) {
      return rounded.toStringAsFixed(0);
    }
    return safeValue.toStringAsFixed(1);
  }
}

class TeamMemberCommentsPanel extends StatefulWidget {
  final String memberId;
  final String title;
  final bool compactComposer;
  final bool showCloseButton;
  final bool expandList;

  const TeamMemberCommentsPanel({
    super.key,
    required this.memberId,
    this.title = 'التعليقات',
    this.compactComposer = true,
    this.showCloseButton = false,
    this.expandList = false,
  });

  @override
  State<TeamMemberCommentsPanel> createState() =>
      _TeamMemberCommentsPanelState();
}

class _TeamMemberCommentsPanelState extends State<TeamMemberCommentsPanel> {
  final _nameController = TextEditingController();
  final _messageController = TextEditingController();
  bool _didPrefill = false;
  bool _isSubmitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrefill) return;
    _didPrefill = true;
    _prefillName();
  }

  Future<void> _prefillName() async {
    final user = context.read<AuthProvider>().user;
    if (user != null && user.username.trim().isNotEmpty) {
      _nameController.text = user.username.trim();
      return;
    }

    final stored = await VisitorIdentityService.getVisitorDisplayName();
    if (!mounted || stored == null || stored.isEmpty) return;
    _nameController.text = stored;
  }

  Future<void> _submit() async {
    final authProvider = context.read<AuthProvider>();
    final teamProvider = context.read<TeamProvider>();
    final authorName = _nameController.text.trim();
    final message = _messageController.text.trim();

    if (authorName.isEmpty) {
      _showSnackBar('اكتب اسمك قبل إرسال التعليق');
      return;
    }
    if (message.isEmpty) {
      _showSnackBar('اكتب تعليقك أولًا');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await teamProvider.addMemberComment(
        memberId: widget.memberId,
        authorName: authorName,
        message: message,
        userId: authProvider.user?.id,
      );
      await VisitorIdentityService.saveVisitorDisplayName(authorName);
      _messageController.clear();
      if (!mounted) return;
      _showSnackBar('تم إرسال التعليق');
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('تعذر إرسال التعليق: $error');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final currentMember = context.watch<TeamProvider>().memberById(
      widget.memberId,
    );
    final comments = currentMember?.comments ?? const <TeamMemberComment>[];
    final authUser = context.watch<AuthProvider>().user;
    final readOnlyName =
        authUser != null && authUser.username.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comments.isEmpty
                        ? 'لا توجد تعليقات حتى الآن'
                        : '${comments.length} تعليق متاح الآن',
                    style: TextStyle(
                      color: isLight ? Colors.black54 : Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.showCloseButton)
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(widget.compactComposer ? 14 : 16),
          decoration: BoxDecoration(
            color: isLight
                ? Colors.black.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                readOnly: readOnlyName,
                decoration: InputDecoration(
                  labelText: 'الاسم',
                  hintText: 'اسمك الظاهر مع التعليق',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _messageController,
                minLines: widget.compactComposer ? 2 : 3,
                maxLines: widget.compactComposer ? 4 : 5,
                decoration: InputDecoration(
                  labelText: 'أضف تعليقًا',
                  hintText: 'اكتب رأيك أو ملاحظتك عن عضو الفريق',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_isSubmitting ? 'جارٍ الإرسال' : 'إرسال التعليق'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (widget.expandList)
          Expanded(child: _buildCommentsList(comments, isLight))
        else
          _buildCommentsList(comments, isLight),
      ],
    );
  }

  Widget _buildCommentsList(List<TeamMemberComment> comments, bool isLight) {
    if (comments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isLight
              ? Colors.black.withValues(alpha: 0.03)
              : Colors.white.withValues(alpha: 0.035),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
        ),
        child: const Text(
          'ابدأ أول تعليق لهذا العضو.',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: !widget.expandList,
      physics: widget.expandList
          ? const AlwaysScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final comment = comments[index];
        return _CommentCard(comment: comment, isLight: isLight);
      },
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool dense;
  final Color foreground;

  const _MetricChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.dense,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: dense ? 16 : 18, color: const Color(0xFFE50914)),
          SizedBox(height: dense ? 6 : 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: foreground,
              fontSize: dense ? 12 : 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: foreground,
              fontSize: dense ? 9 : 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricData {
  final IconData icon;
  final String value;
  final String label;

  const _MetricData({
    required this.icon,
    required this.value,
    required this.label,
  });
}

class _CommentCard extends StatelessWidget {
  final TeamMemberComment comment;
  final bool isLight;

  const _CommentCard({required this.comment, required this.isLight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isLight
            ? Colors.black.withValues(alpha: 0.03)
            : Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  comment.authorName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                _formatCommentDate(comment.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  color: isLight ? Colors.black54 : Colors.white54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.message,
            style: TextStyle(
              height: 1.6,
              color: isLight ? Colors.black87 : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatCommentDate(DateTime? date) {
    if (date == null) return 'الآن';
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 1) return 'الآن';
    if (difference.inHours < 1) return 'منذ ${difference.inMinutes} د';
    if (difference.inDays < 1) return 'منذ ${difference.inHours} س';
    if (difference.inDays < 30) return 'منذ ${difference.inDays} يوم';
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
