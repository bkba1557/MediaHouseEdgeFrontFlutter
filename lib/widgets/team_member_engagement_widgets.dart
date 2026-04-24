import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
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
                title: context.tr(
                  'تعليقات {name}',
                  params: {'name': member.name},
                ),
                compactComposer: false,
                showCloseButton: true,
                expandList: true,
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
        label: context.tr('مشاهدة'),
      ),
      _MetricData(
        icon: Icons.analytics_outlined,
        value: '${_formatPercent(member.viewSharePercent)}%',
        label: context.tr('النسبة'),
      ),
      _MetricData(
        icon: Icons.favorite_border,
        value: '${member.likesCount}',
        label: context.tr('إعجاب'),
      ),
      _MetricData(
        icon: Icons.mode_comment_outlined,
        value: '${member.commentsCount}',
        label: context.tr('تعليق'),
      ),
    ];

    if (dense) {
      return Row(
        children: [
          for (var index = 0; index < stats.length; index++) ...[
            if (index > 0) const SizedBox(width: 2),
            Expanded(
              child: _MetricChip(
                icon: stats[index].icon,
                value: stats[index].value,
                label: stats[index].label,
                dense: true,
                foreground: foreground,
              ),
            ),
          ],
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        const minItemWidth = 94.0;
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 0.0;
        final neededWidth =
            (minItemWidth * stats.length) + (spacing * (stats.length - 1));
        if (availableWidth <= 0) {
          return Row(
            children: [
              for (var index = 0; index < stats.length; index++) ...[
                if (index > 0) const SizedBox(width: 8),
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
        final useWrappedLayout =
            availableWidth > 0 && availableWidth < neededWidth;

        if (useWrappedLayout) {
          final itemWidth = (availableWidth - spacing) / 2;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final stat in stats)
                SizedBox(
                  width: itemWidth,
                  child: _MetricChip(
                    icon: stat.icon,
                    value: stat.value,
                    label: stat.label,
                    dense: dense,
                    foreground: foreground,
                  ),
                ),
            ],
          );
        }

        final children = [
          for (var index = 0; index < stats.length; index++) ...[
            if (index > 0) const SizedBox(width: 8),
            SizedBox(
              width:
                  (availableWidth - (spacing * (stats.length - 1))) /
                  stats.length,
              child: _MetricChip(
                icon: stats[index].icon,
                value: stats[index].value,
                label: stats[index].label,
                dense: dense,
                foreground: foreground,
              ),
            ),
          ],
        ];

        return Row(children: children);
      },
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
      _showSnackBar(context.tr('اكتب اسمك قبل إرسال التعليق'));
      return;
    }
    if (message.isEmpty) {
      _showSnackBar(context.tr('اكتب تعليقك أولًا'));
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
      _showSnackBar(context.tr('تم إرسال التعليق'));
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(
        context.tr('تعذر إرسال التعليق: {error}', params: {'error': '$error'}),
      );
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
                    context.tr(widget.title),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comments.isEmpty
                        ? context.tr('لا توجد تعليقات حتى الآن')
                        : context.tr(
                            '{count} تعليق متاح الآن',
                            params: {'count': '${comments.length}'},
                          ),
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
                  labelText: context.tr('الاسم'),
                  hintText: context.tr('اسمك الظاهر مع التعليق'),
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
                  labelText: context.tr('أضف تعليقًا'),
                  hintText: context.tr('اكتب رأيك أو ملاحظتك عن عضو الفريق'),
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
                  label: Text(
                    _isSubmitting
                        ? context.tr('جارٍ الإرسال')
                        : context.tr('إرسال التعليق'),
                  ),
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
        child: Text(
          context.tr('ابدأ أول تعليق لهذا العضو.'),
          style: const TextStyle(fontWeight: FontWeight.w700),
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
        horizontal: dense ? 5 : 10,
        vertical: dense ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(dense ? 14 : 16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: dense ? 13 : 18, color: const Color(0xFFE50914)),
          SizedBox(height: dense ? 4 : 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: foreground,
              fontSize: dense ? 10 : 14,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          SizedBox(height: dense ? 1 : 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: foreground,
              fontSize: dense ? 7.5 : 10,
              fontWeight: FontWeight.w800,
              height: 1.1,
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
                _formatCommentDate(context, comment.createdAt),
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

  static String _formatCommentDate(BuildContext context, DateTime? date) {
    if (date == null) return context.tr('الآن');
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 1) return context.tr('الآن');
    if (difference.inHours < 1) {
      return context.tr(
        'منذ {value} د',
        params: {'value': '${difference.inMinutes}'},
      );
    }
    if (difference.inDays < 1) {
      return context.tr(
        'منذ {value} س',
        params: {'value': '${difference.inHours}'},
      );
    }
    if (difference.inDays < 30) {
      return context.tr(
        'منذ {value} يوم',
        params: {'value': '${difference.inDays}'},
      );
    }
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
