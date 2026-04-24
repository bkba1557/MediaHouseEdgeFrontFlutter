import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../models/about_page_content.dart';
import '../providers/about_provider.dart';
import '../widgets/content_asset_preview_tile.dart';
import 'content_asset_viewer_screen.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AboutProvider>().fetchAboutPage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('من نحن'))),
      body: Consumer<AboutProvider>(
        builder: (context, provider, _) {
          final page = provider.page;
          final sections = [...page.sections]
            ..sort((a, b) => a.order.compareTo(b.order));

          return RefreshIndicator(
            onRefresh: provider.fetchAboutPage,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AboutHero(page: page),
                        const SizedBox(height: 26),
                        if (provider.isLoading && page.sections.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(
                                color: Color(0xFFE50914),
                              ),
                            ),
                          )
                        else if (sections.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white12),
                              color: Colors.white.withValues(alpha: 0.04),
                            ),
                            child: Text(
                              context.tr(
                                'لا يوجد محتوى مضاف في صفحة من نحن حتى الآن.',
                              ),
                            ),
                          )
                        else
                          ...sections.map(
                            (section) => Padding(
                              padding: const EdgeInsets.only(bottom: 22),
                              child: _AboutSectionCard(section: section),
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
      ),
    );
  }
}

class _AboutHero extends StatelessWidget {
  final AboutPageContent page;

  const _AboutHero({required this.page});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            const Color(0xFFE50914).withValues(alpha: 0.16),
            Colors.white.withValues(alpha: 0.05),
            Colors.black.withValues(alpha: 0.20),
          ],
        ),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            page.heroTitle.trim().isEmpty
                ? context.tr('من نحن')
                : page.heroTitle,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
          ),
          if (page.heroSubtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              page.heroSubtitle,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (page.intro.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              page.intro,
              style: const TextStyle(color: Colors.white70, height: 1.7),
            ),
          ],
        ],
      ),
    );
  }
}

class _AboutSectionCard extends StatelessWidget {
  final AboutSection section;

  const _AboutSectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1100
        ? 3
        : width >= 700
        ? 2
        : 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          if (section.body.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              section.body,
              style: const TextStyle(color: Colors.white70, height: 1.7),
            ),
          ],
          if (section.media.isNotEmpty) ...[
            const SizedBox(height: 18),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: section.media.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.24,
              ),
              itemBuilder: (context, index) {
                final asset = section.media[index];
                return ContentAssetPreviewTile(
                  asset: asset,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ContentAssetViewerScreen(asset: asset),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
