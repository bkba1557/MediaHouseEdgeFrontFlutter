import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../models/team_member.dart';
import '../providers/auth_provider.dart';
import '../providers/team_provider.dart';
import '../widgets/app_network_image.dart';
import '../widgets/content_asset_preview_tile.dart';
import '../widgets/team_member_engagement_widgets.dart';
import 'content_asset_viewer_screen.dart';

class TeamMemberProfileScreen extends StatefulWidget {
  final TeamMember member;

  const TeamMemberProfileScreen({super.key, required this.member});

  @override
  State<TeamMemberProfileScreen> createState() =>
      _TeamMemberProfileScreenState();
}

class _TeamMemberProfileScreenState extends State<TeamMemberProfileScreen> {
  bool _didRegisterView = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didRegisterView) return;
    _didRegisterView = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        context
            .read<TeamProvider>()
            .registerMemberView(
              memberId: widget.member.id,
              userId: context.read<AuthProvider>().user?.id,
            )
            .catchError((_) {}),
      );
    });
  }

  Future<void> _toggleLike() async {
    await context.read<TeamProvider>().toggleMemberLike(
      memberId: widget.member.id,
      userId: context.read<AuthProvider>().user?.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TeamProvider>(
      builder: (context, teamProvider, _) {
        final member =
            teamProvider.memberById(widget.member.id) ?? widget.member;
        final isLiked = teamProvider.isMemberLiked(member.id);

        return Scaffold(
          appBar: AppBar(
            title: Text(member.name),
            actions: [
              IconButton(
                onPressed: () =>
                    showTeamMemberCommentsSheet(context, member: member),
                icon: const Icon(Icons.mode_comment_outlined),
                tooltip: context.tr('التعليقات'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProfileHero(
                        member: member,
                        isLiked: isLiked,
                        onLike: _toggleLike,
                        onComment: () => showTeamMemberCommentsSheet(
                          context,
                          member: member,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _ProfileSectionHeader(
                        title: context.tr('أعماله'),
                        subtitle: member.portfolio.isEmpty
                            ? context.tr('لا توجد أعمال مضافة حاليًا')
                            : context.tr(
                                '{count} عنصر في المعرض',
                                params: {'count': '${member.portfolio.length}'},
                              ),
                      ),
                      const SizedBox(height: 12),
                      if (member.portfolio.isEmpty)
                        _EmptyPortfolioPanel()
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final maxColumns = constraints.maxWidth >= 1100
                                ? 3
                                : constraints.maxWidth >= 720
                                ? 2
                                : 1;
                            final columns = member.portfolio.length < maxColumns
                                ? member.portfolio.length
                                : maxColumns;
                            final aspectRatio = columns == 1 ? 1.85 : 1.24;

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: member.portfolio.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    mainAxisSpacing: 14,
                                    crossAxisSpacing: 14,
                                    childAspectRatio: aspectRatio,
                                  ),
                              itemBuilder: (context, index) {
                                final asset = member.portfolio[index];
                                return ContentAssetPreviewTile(
                                  asset: asset,
                                  borderRadius: 8,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ContentAssetViewerScreen(
                                              asset: asset,
                                            ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      const SizedBox(height: 28),
                      _ProfileSectionHeader(
                        title: context.tr('التعليقات'),
                        subtitle: context.tr(
                          'آراء الزوار والمستخدمين على هذا العضو',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                          color: Colors.white.withValues(alpha: 0.04),
                        ),
                        child: TeamMemberCommentsPanel(
                          memberId: member.id,
                          title: context.tr('أضف رأيك'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final TeamMember member;
  final bool isLiked;
  final Future<void> Function() onLike;
  final VoidCallback onComment;

  const _ProfileHero({
    required this.member,
    required this.isLiked,
    required this.onLike,
    required this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                const Color(0xFFE50914).withValues(alpha: 0.18),
                Colors.white.withValues(alpha: 0.04),
                Colors.black.withValues(alpha: 0.20),
              ],
            ),
            border: Border.all(color: Colors.white12),
          ),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _ProfileDetails(
                        member: member,
                        isLiked: isLiked,
                        onLike: onLike,
                        onComment: onComment,
                      ),
                    ),
                    const SizedBox(width: 24),
                    _ProfilePhotoCard(
                      imageUrl: member.photoUrl,
                      role: member.role,
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: _ProfilePhotoCard(
                        imageUrl: member.photoUrl,
                        role: member.role,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _ProfileDetails(
                      member: member,
                      isLiked: isLiked,
                      onLike: onLike,
                      onComment: onComment,
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _ProfileDetails extends StatelessWidget {
  final TeamMember member;
  final bool isLiked;
  final Future<void> Function() onLike;
  final VoidCallback onComment;

  const _ProfileDetails({
    required this.member,
    required this.isLiked,
    required this.onLike,
    required this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE50914).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: const Color(0xFFE50914).withValues(alpha: 0.34),
            ),
          ),
          child: Text(
            context.tr('ملف عضو الفريق'),
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          member.name,
          style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          member.role,
          style: const TextStyle(
            fontSize: 17,
            color: Colors.white70,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _ProfileStatChip(
              icon: Icons.work_outline,
              label: context.tr(
                '{count} أعمال',
                params: {'count': '${member.portfolio.length}'},
              ),
            ),
            _ProfileStatChip(
              icon: Icons.auto_awesome_outlined,
              label: context.tr(
                '{count} مهارات',
                params: {'count': '${member.skills.length}'},
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TeamMemberMetricChips(member: member),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: () async => onLike(),
              icon: Icon(
                isLiked ? Icons.favorite_rounded : Icons.favorite_border,
              ),
              label: Text(
                isLiked ? context.tr('تم الإعجاب') : context.tr('إعجاب'),
              ),
            ),
            OutlinedButton.icon(
              onPressed: onComment,
              icon: const Icon(Icons.mode_comment_outlined),
              label: Text(context.tr('عرض التعليقات')),
            ),
          ],
        ),
        if (member.bio.trim().isNotEmpty) ...[
          const SizedBox(height: 18),
          _ProfileInfoPanel(
            title: context.tr('نبذة'),
            child: Text(
              member.bio,
              style: const TextStyle(color: Colors.white70, height: 1.8),
            ),
          ),
        ],
        if (member.skills.isNotEmpty) ...[
          const SizedBox(height: 18),
          _ProfileInfoPanel(
            title: context.tr('المهارات'),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: member.skills
                  .map(
                    (skill) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        skill,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ],
      ],
    );
  }
}

class _ProfilePhotoCard extends StatelessWidget {
  final String imageUrl;
  final String role;

  const _ProfilePhotoCard({required this.imageUrl, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 270,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageUrl.trim().isEmpty
                ? Container(
                    color: Colors.white10,
                    child: const Icon(
                      Icons.person_outline,
                      color: Colors.white70,
                      size: 56,
                    ),
                  )
                : AppNetworkImage(
                    url: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: const ColoredBox(color: Colors.white10),
                    errorWidget: const ColoredBox(color: Colors.white10),
                  ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.06),
                    Colors.black.withValues(alpha: 0.68),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.38),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  role,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ProfileSectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFE50914),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.white60)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileInfoPanel extends StatelessWidget {
  final String title;
  final Widget child;

  const _ProfileInfoPanel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ProfileStatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ProfileStatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFE50914)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _EmptyPortfolioPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Colors.white.withValues(alpha: 0.05),
            Colors.black.withValues(alpha: 0.10),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.work_outline, color: Color(0xFFE50914), size: 22),
          const SizedBox(height: 10),
          Text(
            context.tr('لا توجد أعمال مضافة لهذا العضو حاليًا.'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
