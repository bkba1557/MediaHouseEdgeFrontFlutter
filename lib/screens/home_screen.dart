import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/media.dart';
import '../models/team_member.dart';
import '../localization/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/about_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/media_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/response_provider.dart';
import '../providers/team_provider.dart';
import '../config/company_info.dart';
import '../widgets/app_network_image.dart';
import '../widgets/auto_play_video_preview.dart';
import '../widgets/team_member_engagement_widgets.dart';
import 'admin/admin_dashboard.dart';
import 'about_screen.dart';
import 'media_detail_screen.dart';
import 'service_feed_screen.dart';
import 'story_view_screen.dart';
import 'team_member_profile_screen.dart';
import 'user_profile_screen.dart';
import 'video_player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _HomeThemeMode { system, light, dark }

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  final _adPageController = PageController(viewportFraction: 0.86);
  final _contactKey = GlobalKey();
  final _formKey = GlobalKey<FormState>();
  final _supportMessageFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  final _supportNameController = TextEditingController();
  final _supportEmailController = TextEditingController();
  final _supportMessageController = TextEditingController();
  final _supportChatController = TextEditingController();

  late final AnimationController _backgroundController;
  Timer? _adTimer;
  String _selectedCategory = 'all';
  bool _isSending = false;
  int _adItemCount = 3;
  _HomeThemeMode _themeMode = _HomeThemeMode.dark;
  bool _didPrefillContactForm = false;
  final List<_SupportChatMessage> _supportChatMessages = [
    const _SupportChatMessage(
      'أهلًا بك في دعم Media House Edge. أنا المساعد الآلي، اكتب طلبك وسأساعدك إلى أن يستلم أحد من خدمة العملاء المحادثة.',
      false,
    ),
  ];

  final List<_StoryCategory> _categories = const [
    _StoryCategory('all', 'الكل', 'All', Icons.auto_awesome_rounded),
    _StoryCategory('film', 'تصوير', 'Filming', Icons.movie_creation_outlined),
    _StoryCategory('montage', 'مونتاچ', 'Editing', Icons.content_cut_rounded),
    _StoryCategory(
      'advertisement',
      'إعلانات تجارية',
      'Commercial Ads',
      Icons.campaign_outlined,
    ),
  ];

  final List<_ServiceItem> _services = const [
    _ServiceItem('مسلسلات وافلام', 'تلفزيونية ومنصات', Icons.tv_sharp),
    _ServiceItem('تصوير إعلانات', 'تجارية ودعائية', Icons.videocam_outlined),
    _ServiceItem('بودكاست ', 'برامج صوتية متنوعة', Icons.podcasts_outlined),
    _ServiceItem('ڤيديو كليب', 'فيديوهات غنائية', Icons.music_video_outlined),
    _ServiceItem('إنتاج فني', 'تصميم وإنتاج عمل فني', Icons.attach_file),
    _ServiceItem(
      'إنتاج وتوزيع المنصات',
      ' بيع وتوزيع وتسويق الاعمال بالمنصات',
      Icons.money_outlined,
    ),
    _ServiceItem(
      'مونتاچ ',
      'VFX , Color Correction , Visual Effects',
      Icons.tune_outlined,
    ),
    _ServiceItem(
      'إعلانات تجارية',
      'تلفزيونية وسوشيال ميديا وغيرها',
      Icons.ads_click_outlined,
    ),
    _ServiceItem(
      'حفلات عالمية',
      ' تغطية حفلات ومهرجانات عالمية',
      Icons.public_outlined,
    ),
    _ServiceItem(
      'تغطية إعلامية',
      'تغطية إعلامية للأحداث والفعاليات',
      Icons.mic_external_on_outlined,
    ),
    _ServiceItem(
      'تسجيلات صوتية',
      ' تسجيل صوتي بجودة عالية للاستوديوهات والمنتجين',
      Icons.mic_external_on_outlined,
    ),
    _ServiceItem(
      'إعلانات بشراكة حكومية',
      ' إنتاج إعلانات بالتعاون مع جهات حكومية',
      Icons.handshake_outlined,
    ),
    _ServiceItem(
      'تعاقدات فنانين',
      'إدارة وحجز وتنسيق التعاقدات الفنية',
      Icons.assignment_ind_outlined,
    ),
    _ServiceItem(
      'كواليس التصوير',
      'توثيق خلف الكاميرا ولحظات ما وراء المشهد',
      Icons.photo_camera_back_outlined,
    ),
    _ServiceItem(
      'DJ\'s Booking',
      'حجز وتعاقدات فنانيين DJ\'s العالميين والحفلات الموسيقية العالمية',
      Icons.queue_music_outlined,
    ),
    _ServiceItem(
      'أعمال مع مؤسسات دولية',
      'تنفيذ وإنتاج مشاريع مشتركة مع جهات ومؤسسات دولية',
      Icons.apartment_outlined,
    ),
  ];

  final List<String> _serviceKeys = const [
    'series_movies',
    'ads_shooting',
    'podcast',
    'video_clip',
    'art_production',
    'platform_distribution',
    'montage',
    'commercial_ads',
    'global_events',
    'media_coverage',
    'audio_recordings',
    'gov_partnership_ads',
    'artist_contracts',
    'behind_the_scenes',
    'dj_booking',
    'international_institutions',
  ];

  TextDirection get _textDirection =>
      AppLocalizations.isRtlLocale(Localizations.localeOf(context))
      ? TextDirection.rtl
      : TextDirection.ltr;

  bool get _useLightTheme {
    if (_themeMode == _HomeThemeMode.light) return true;
    if (_themeMode == _HomeThemeMode.dark) return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.light;
  }

  Color get _pageBackground => _useLightTheme ? Colors.white : Colors.black;
  Color get _primaryText => _useLightTheme ? Colors.black : Colors.white;
  Color get _glassBorder => _useLightTheme
      ? Colors.black.withValues(alpha: 0.10)
      : Colors.white.withValues(alpha: 0.12);

  String _copy(String ar, String en) => context.tr(ar, fallback: en);

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadMedia();
    });
    _startAdTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrefillContactForm) return;

    final user = Provider.of<AuthProvider>(context).user;
    if (user == null) return;

    if (_supportNameController.text.isEmpty) {
      _supportNameController.text = user.username;
    }
    if (_supportEmailController.text.isEmpty) {
      _supportEmailController.text = user.email;
    }
    _didPrefillContactForm = true;
  }

  Future<void> _loadMedia() async {
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
    final teamProvider = Provider.of<TeamProvider>(context, listen: false);
    final aboutProvider = Provider.of<AboutProvider>(context, listen: false);

    await Future.wait([
      if (_selectedCategory == 'all')
        mediaProvider.fetchMedia()
      else
        mediaProvider.fetchMedia(category: _selectedCategory),
      teamProvider.fetchTeamMembers(),
      aboutProvider.fetchAboutPage(),
    ]);
  }

  void _startAdTimer() {
    _adTimer?.cancel();
    _adTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_adItemCount <= 1) return;
      if (!_adPageController.hasClients) return;
      final currentPage = (_adPageController.page ?? 0).round();
      final nextPage = currentPage >= _adItemCount - 1 ? 0 : currentPage + 1;
      _adPageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _syncAdItemCount(int itemCount) {
    if (_adItemCount == itemCount) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _adItemCount = itemCount;
    });
  }

  Future<void> _submitContact() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);
    try {
      await Provider.of<ResponseProvider>(
        context,
        listen: false,
      ).submitResponse(
        clientName: _nameController.text.trim(),
        clientEmail: _emailController.text.trim(),
        message: _messageController.text.trim(),
        rating: 5,
      );

      _nameController.clear();
      _emailController.clear();
      _messageController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('تم إرسال رسالتك بنجاح'))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('تعذر الإرسال: {error}', params: {'error': '$error'}),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToContact() {
    final contactContext = _contactKey.currentContext;
    if (contactContext == null) return;
    Scrollable.ensureVisible(
      contactContext,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
    );
  }

  void _openSupportDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: _textDirection,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _GlassPanel(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const _IconBox(icon: Icons.support_agent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _copy('الدعم الفني', 'Support'),
                                style: TextStyle(
                                  color: _primaryText,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                _copy(
                                  'اختر طريقة التواصل المناسبة',
                                  'Choose how you want to contact us',
                                ),
                                style: TextStyle(
                                  color: _primaryText.withValues(alpha: 0.65),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: Icon(Icons.close, color: _primaryText),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _SupportOptionTile(
                      icon: Icons.edit_note_outlined,
                      title: _copy('تسجيل رسالة', 'Leave a message'),
                      subtitle: _copy(
                        'اكتب طلبك وسيظهر لفريق الدعم',
                        'Send a request to the support team',
                      ),
                      onTap: () {
                        Navigator.pop(dialogContext);
                        _openSupportMessageDialog();
                      },
                    ),
                    const SizedBox(height: 10),
                    _SupportOptionTile(
                      icon: Icons.mark_unread_chat_alt_outlined,
                      title: _copy(
                        'التحدث مع خدمة العملاء',
                        'Chat with support',
                      ),
                      subtitle: _copy(
                        'المساعد الآلي يرد حتى يستلم الدعم المحادثة',
                        'The bot replies until a support agent joins',
                      ),
                      onTap: () {
                        Navigator.pop(dialogContext);
                        _openSupportChatDialog();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openSupportMessageDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: _textDirection,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: _GlassPanel(
                padding: const EdgeInsets.all(18),
                child: Form(
                  key: _supportMessageFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _copy('تسجيل رسالة للدعم', 'Leave a support message'),
                        style: TextStyle(
                          color: _primaryText,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _GlassTextField(
                        controller: _supportNameController,
                        label: _copy('الاسم', 'Name'),
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return _copy('اكتب الاسم', 'Enter your name');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _GlassTextField(
                        controller: _supportEmailController,
                        label: _copy('البريد الإلكتروني', 'Email'),
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || !value.contains('@')) {
                            return _copy(
                              'اكتب بريد صحيح',
                              'Enter a valid email',
                            );
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _GlassTextField(
                        controller: _supportMessageController,
                        label: _copy('رسالتك', 'Message'),
                        icon: Icons.chat_bubble_outline,
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return _copy('اكتب الرسالة', 'Enter your message');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: Text(_copy('إلغاء', 'Cancel')),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _sendSupportMessage(dialogContext),
                              icon: const Icon(Icons.send_outlined),
                              label: Text(_copy('إرسال', 'Send')),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openSupportChatDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Directionality(
              textDirection: _textDirection,
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(horizontal: 14),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 480,
                    maxHeight: 620,
                  ),
                  child: _GlassPanel(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const _IconBox(icon: Icons.support_agent),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _copy('محادثة خدمة العملاء', 'Support chat'),
                                style: TextStyle(
                                  color: _primaryText,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              icon: Icon(Icons.close, color: _primaryText),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _supportChatMessages.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final message = _supportChatMessages[index];
                              return _SupportChatBubble(message: message);
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _supportChatController,
                                minLines: 1,
                                maxLines: 3,
                                style: TextStyle(color: _primaryText),
                                decoration: InputDecoration(
                                  hintText: _copy(
                                    'اكتب رسالتك...',
                                    'Type your message...',
                                  ),
                                  hintStyle: TextStyle(
                                    color: _primaryText.withValues(alpha: 0.45),
                                  ),
                                  filled: true,
                                  fillColor: Colors.black.withValues(
                                    alpha: 0.18,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFE50914),
                              ),
                              onPressed: () =>
                                  _sendSupportChatMessage(setModalState),
                              icon: const Icon(Icons.send, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _sendSupportMessage(BuildContext dialogContext) async {
    if (!_supportMessageFormKey.currentState!.validate()) return;
    final navigator = Navigator.of(dialogContext);

    try {
      await Provider.of<ResponseProvider>(
        context,
        listen: false,
      ).submitResponse(
        clientName: _supportNameController.text.trim(),
        clientEmail: _supportEmailController.text.trim(),
        message: 'Support message: ${_supportMessageController.text.trim()}',
        rating: 5,
      );

      _supportMessageController.clear();
      if (!mounted) return;
      navigator.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_copy('تم تسجيل رسالتك للدعم', 'Message sent'))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_copy('تعذر إرسال الرسالة', 'Send failed'))),
      );
    }
  }

  void _sendSupportChatMessage(StateSetter setModalState) {
    final text = _supportChatController.text.trim();
    if (text.isEmpty) return;

    setModalState(() {
      _supportChatMessages.add(_SupportChatMessage(text, true));
      _supportChatMessages.add(
        _SupportChatMessage(
          _copy(
            'وصلت رسالتك. سأحاول مساعدتك الآن، وتم تحويل المحادثة لفريق خدمة العملاء للرد عليك عند توفر أحدهم.',
            'Your message is received. I will help now, and the support team has been notified to join when available.',
          ),
          false,
        ),
      );
      _supportChatController.clear();
    });

    Provider.of<ResponseProvider>(context, listen: false)
        .submitResponse(
          clientName: _supportNameController.text.trim().isEmpty
              ? 'Support chat user'
              : _supportNameController.text.trim(),
          clientEmail: _supportEmailController.text.trim().contains('@')
              ? _supportEmailController.text.trim()
              : 'support-chat@mediahouse.local',
          message: 'Support chat: $text',
          rating: 5,
        )
        .catchError((_) {});
  }

  void _cycleThemeMode() {
    setState(() {
      _themeMode = switch (_themeMode) {
        _HomeThemeMode.dark => _HomeThemeMode.light,
        _HomeThemeMode.light => _HomeThemeMode.system,
        _HomeThemeMode.system => _HomeThemeMode.dark,
      };
    });
  }

  Future<void> _openLanguageSheet() async {
    final localeProvider = context.read<LocaleProvider>();
    final currentCode = localeProvider.locale.languageCode;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final maxSheetHeight = MediaQuery.sizeOf(sheetContext).height * 0.78;

        return _GlassPanel(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: maxSheetHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sheetContext.tr('لغة التطبيق'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sheetContext.tr('اختر لغة الواجهة'),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: AppLocalizations.languageOptions.map((
                            option,
                          ) {
                            final selected =
                                option.locale.languageCode == currentCode;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () async {
                                  await localeProvider.setLocale(option.locale);
                                  if (sheetContext.mounted) {
                                    Navigator.pop(sheetContext);
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? const Color(
                                            0xFFE50914,
                                          ).withValues(alpha: 0.18)
                                        : Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selected
                                          ? const Color(0xFFE50914)
                                          : Colors.white.withValues(
                                              alpha: 0.08,
                                            ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        selected
                                            ? Icons.check_circle_rounded
                                            : Icons.language_rounded,
                                        color: selected
                                            ? const Color(0xFFE50914)
                                            : Colors.white70,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              option.nativeName,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            Text(
                                              option.englishName,
                                              style: const TextStyle(
                                                color: Colors.white60,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openAccountSheet(AuthProvider authProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final user = authProvider.user;
        return _GlassPanel(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.account_circle,
                    color: Colors.white,
                    size: 42,
                  ),
                  title: Text(
                    user?.username.isNotEmpty == true
                        ? user!.username
                        : sheetContext.tr('الحساب'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    user?.email.isNotEmpty == true ? user!.email : '',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                if (user != null && !user.isGuest) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _AccountTierChip(label: user.tierLabel),
                  ),
                ],
                const SizedBox(height: 12),
                if (user != null && !user.isGuest) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserProfileScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.assignment_ind_outlined),
                      label: const Text('طلباتي وعقودي'),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await authProvider.logout();
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                    icon: const Icon(Icons.logout),
                    label: Text(sheetContext.tr('تسجيل الخروج')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE50914),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final mediaProvider = Provider.of<MediaProvider>(context);
    final teamProvider = Provider.of<TeamProvider>(context);
    final mediaList = mediaProvider.mediaList;
    final teamMembers = teamProvider.members;
    final adMedia = mediaList
        .where((media) => media.category == 'advertisement')
        .take(6)
        .toList();
    _syncAdItemCount(adMedia.isEmpty ? 3 : adMedia.length);
    final videoMedia = mediaList
        .where((media) => media.isVideo)
        .take(8)
        .toList();
    final dailyStories = mediaList
        .where(
          (media) =>
              media.category == 'story' &&
              DateTime.now().difference(media.createdAt).inHours < 24,
        )
        .take(12)
        .toList();

    return Directionality(
      textDirection: _textDirection,
      child: Theme(
        data: Theme.of(context).copyWith(
          brightness: _useLightTheme ? Brightness.light : Brightness.dark,
          scaffoldBackgroundColor: _pageBackground,
        ),
        child: Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: _pageBackground,
          appBar: _buildAppBar(authProvider),
          floatingActionButton: FloatingActionButton(
            onPressed: _openSupportDialog,
            backgroundColor: const Color(0xFFE50914),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.support_agent),
          ),
          body: Stack(
            children: [
              _buildAnimatedBackground(),
              SafeArea(
                child: RefreshIndicator(
                  color: const Color(0xFFE50914),
                  onRefresh: () async => _loadMedia(),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDailyStories(dailyStories),
                            const SizedBox(height: 18),
                            _buildTopStrip(),
                            const SizedBox(height: 18),
                            _buildStories(),
                            const SizedBox(height: 22),
                            _buildAdCarousel(adMedia),
                            const SizedBox(height: 28),
                            _buildServices(),
                            const SizedBox(height: 28),
                            _buildTeamSection(
                              teamMembers,
                              teamProvider.isLoading,
                              teamProvider.error,
                            ),
                            const SizedBox(height: 28),
                            _buildVideoBackdropArea(
                              videoMedia,
                              mediaProvider.isLoading,
                            ),
                            const SizedBox(height: 28),
                            _buildPortfolio(mediaList, mediaProvider.isLoading),
                            const SizedBox(height: 28),
                            _buildFooter(),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AuthProvider authProvider) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWideWeb = kIsWeb && screenWidth >= 720;
    final localeCode = context.watch<LocaleProvider>().locale.languageCode;
    final unreadCount = context.watch<NotificationProvider>().unreadCount;
    final toolbarHeight = isWideWeb ? 78.0 : 66.0;
    final logoBadgeSize = isWideWeb ? 62.0 : 52.0;
    final logoPadding = isWideWeb ? 2.0 : 3.0;
    final titleFontSize = isWideWeb ? 20.0 : 17.0;
    final titleGap = isWideWeb ? 14.0 : 12.0;

    return AppBar(
      toolbarHeight: toolbarHeight,
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 16,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: (_useLightTheme ? Colors.white : Colors.black).withValues(
                alpha: 0.56,
              ),
              border: Border(bottom: BorderSide(color: _glassBorder)),
            ),
          ),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: logoBadgeSize,
            height: logoBadgeSize,
            padding: EdgeInsets.all(logoPadding),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.78),
                width: isWideWeb ? 1.6 : 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: isWideWeb ? 22 : 18,
                  offset: Offset(0, isWideWeb ? 9 : 7),
                ),
                BoxShadow(
                  color: Color(0x26FFFFFF),
                  blurRadius: isWideWeb ? 26 : 22,
                  spreadRadius: isWideWeb ? 2.0 : 1.5,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
            ),
          ),
          SizedBox(width: titleGap),
          Text(
            context.tr('Media House Edge'),
            style: TextStyle(
              color: _primaryText,
              fontSize: titleFontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      actions: [
        _AppIconButton(
          icon: Icons.info_outline_rounded,
          tooltip: context.tr('عن التطبيق'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            );
          },
        ),
        _AppIconButton(
          icon: Icons.language_rounded,
          tooltip: context.tr('لغة التطبيق'),
          isActive: localeCode != 'ar',
          onPressed: _openLanguageSheet,
        ),
        _AppIconButton(
          icon: _themeMode == _HomeThemeMode.light
              ? Icons.light_mode_rounded
              : _themeMode == _HomeThemeMode.dark
              ? Icons.dark_mode_rounded
              : Icons.brightness_auto_rounded,
          tooltip: context.tr('المظهر'),
          isActive: _themeMode != _HomeThemeMode.dark,
          onPressed: _cycleThemeMode,
        ),
        if (authProvider.isAuthenticated &&
            !(authProvider.user?.isGuest ?? true))
          _AppIconButton(
            icon: Icons.notifications_none_rounded,
            tooltip: 'Notifications',
            badgeCount: unreadCount,
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
        if (authProvider.isAdmin)
          _AppIconButton(
            icon: Icons.dashboard_customize_outlined,
            tooltip: context.tr('لوحة التحكم'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminDashboard()),
              );
            },
          ),
        if (!authProvider.isAuthenticated)
          _AppIconButton(
            icon: Icons.login_rounded,
            tooltip: context.tr('الدخول'),
            onPressed: () => Navigator.pushNamed(context, '/login'),
          )
        else
          _AppIconButton(
            icon: Icons.account_circle_outlined,
            tooltip: context.tr('الحساب'),
            onPressed: () => _openAccountSheet(authProvider),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        final value = _backgroundController.value;
        final phase = value * 2 * math.pi;
        final light = _useLightTheme;
        final driftX = math.sin(phase) * 0.38;
        final driftY = math.cos(phase * 0.92) * 0.34;
        final begin = Alignment(-1.0 + driftX, -1.0 + driftY);
        final end = Alignment(1.0 - driftX, 1.0 - driftY);

        final cMixA = 0.5 + 0.5 * math.sin(phase * 0.55);
        final cMixB = 0.5 + 0.5 * math.cos(phase * 0.62);

        final gradientColors = light
            ? [
                Color.lerp(
                  const Color(0xFFFFFFFF),
                  const Color(0xFFFFF6F7),
                  cMixA,
                )!,
                Color.lerp(
                  const Color(0xFFFFEEF0),
                  const Color(0xFFFFE2E6),
                  cMixB,
                )!,
                Color.lerp(
                  const Color(0xFFF4F4F4),
                  const Color(0xFFFFFFFF),
                  cMixA,
                )!,
              ]
            : [
                Color.lerp(
                  const Color(0xFF060606),
                  const Color(0xFF090909),
                  cMixA,
                )!,
                Color.lerp(
                  const Color(0xFF210306),
                  const Color(0xFF2B050A),
                  cMixB,
                )!,
                Color.lerp(
                  const Color(0xFF0B0B0B),
                  const Color(0xFF050505),
                  cMixA,
                )!,
              ];

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: begin,
              end: end,
              colors: gradientColors,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: _buildBackgroundBlobs(light: light, phase: phase),
                ),
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: 0.16 + (value * 0.08),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          (light ? Colors.black : Colors.white).withValues(
                            alpha: 0.08,
                          ),
                          Colors.transparent,
                          const Color(0xFFE50914).withValues(alpha: 0.18),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackgroundBlobs({required bool light, required double phase}) {
    final red = const Color(0xFFE50914);
    final white = Colors.white;
    final a1 = 0.06 + (0.02 * (0.5 + 0.5 * math.sin(phase * 0.9)));
    final a2 = 0.05 + (0.02 * (0.5 + 0.5 * math.cos(phase * 0.75)));

    Widget blob({
      required double size,
      required double left,
      required double top,
      required Color color,
      required double alpha,
      required double blur,
    }) {
      return Positioned(
        left: left,
        top: top,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: SizedBox(
            width: size,
            height: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: alpha),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return ClipRect(
      child: Stack(
        children: [
          blob(
            size: 620,
            left: -260 + (math.sin(phase * 0.55) * 160),
            top: -320 + (math.cos(phase * 0.48) * 190),
            color: red,
            alpha: light ? a1 : (a1 + 0.02),
            blur: 54,
          ),
          blob(
            size: 560,
            left: 420 + (math.cos(phase * 0.44) * 220),
            top: 260 + (math.sin(phase * 0.52) * 200),
            color: red,
            alpha: light ? (a2 + 0.01) : (a2 + 0.03),
            blur: 50,
          ),
          if (!light)
            blob(
              size: 480,
              left: 120 + (math.sin(phase * 0.38) * 210),
              top: 520 + (math.cos(phase * 0.41) * 180),
              color: white,
              alpha: 0.04 + (0.02 * (0.5 + 0.5 * math.sin(phase * 0.7))),
              blur: 44,
            ),
        ],
      ),
    );
  }

  Widget _buildTopStrip() {
    final title = _copy(
      'خدمات إنتاج سينمائية متكاملة',
      'Content that lands strong',
    );
    final subtitle = _copy(
      'مسلسلات وافلام , تصوير إعلانات , بودكاست , ڤيديو كليب , إنتاج فني , إنتاج وتوزيع منصات , مونتاچ , إخراج سينمائي ',
      'Film, editing, ads, and motion content with a clear visual line.',
    );
    final titleBlock = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFE50914),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE50914).withValues(alpha: 0.32),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.movie_creation_outlined,
            color: Colors.white,
            size: 27,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(title),
                style: TextStyle(
                  color: _primaryText,
                  fontSize: 28,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr(subtitle),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _primaryText.withValues(alpha: 0.72),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
    final metrics = Row(
      children: [
        _MetricTile(
          value: '24/7',
          label: _copy('دعم', 'Support'),
          icon: Icons.support_agent_outlined,
        ),
        const SizedBox(width: 10),
        _MetricTile(
          label: _copy('إخراج', 'Output'),
          icon: Icons.video_camera_back_outlined,
        ),
        const SizedBox(width: 10),
        _MetricTile(
          label: _copy('تنفيذ', 'Delivery'),
          icon: Icons.task_alt_outlined,
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLight = Theme.of(context).brightness == Brightness.light;
        final isWide = constraints.maxWidth > 780;
        final metricsWidth = math
            .min(420.0, constraints.maxWidth * 0.36)
            .clamp(330.0, 420.0)
            .toDouble();

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isLight ? 0.08 : 0.28),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  color: isLight
                      ? Colors.white.withValues(alpha: 0.78)
                      : const Color(0xFF19070B).withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isLight
                        ? Colors.black.withValues(alpha: 0.10)
                        : Colors.white.withValues(alpha: 0.14),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: isLight
                        ? [
                            const Color(0xFFE50914).withValues(alpha: 0.08),
                            Colors.white.withValues(alpha: 0.80),
                            Colors.white.withValues(alpha: 0.62),
                          ]
                        : [
                            const Color(0xFFE50914).withValues(alpha: 0.16),
                            const Color(0xFF241015).withValues(alpha: 0.90),
                            Colors.black.withValues(alpha: 0.28),
                          ],
                  ),
                ),
                child: Stack(
                  children: [
                    PositionedDirectional(
                      start: 0,
                      top: 0,
                      bottom: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFFE50914),
                              const Color(0xFFE50914).withValues(alpha: 0.18),
                            ],
                          ),
                        ),
                        child: const SizedBox(width: 4),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        24,
                        20,
                        22,
                        20,
                      ),
                      child: isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(child: titleBlock),
                                const SizedBox(width: 24),
                                SizedBox(width: metricsWidth, child: metrics),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                titleBlock,
                                const SizedBox(height: 18),
                                metrics,
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDailyStories(List<Media> stories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_stories_outlined, color: _primaryText, size: 18),
            const SizedBox(width: 8),
            Text(
              _copy(' الحالات الجديده ', ' '),
              style: TextStyle(
                color: _primaryText,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (stories.isEmpty)
          Text(
            _copy('لا توجد حالات مضافة الآن', 'No stories added yet'),
            style: TextStyle(color: _primaryText.withValues(alpha: 0.58)),
          )
        else
          SizedBox(
            height: 94,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: stories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final media = stories[index];
                return _DailyStoryCircle(
                  label: media.title,
                  imageUrl: media.previewImageUrl,
                  icon: media.isVideo ? Icons.play_arrow : Icons.image_outlined,
                  borderColor: const Color(0xFFE50914),
                  textColor: _primaryText,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StoryViewScreen(media: media),
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildStories() {
    final isLight = _useLightTheme;

    return SizedBox(
      height: 114,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.only(start: 4, end: 4),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category.value;

          return AnimatedScale(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            scale: isSelected ? 1 : 0.98,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                setState(() => _selectedCategory = category.value);
                _loadMedia();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 96,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(
                          0xFFE50914,
                        ).withValues(alpha: isLight ? 0.10 : 0.16)
                      : (isLight
                            ? Colors.black.withValues(alpha: 0.035)
                            : Colors.white.withValues(alpha: 0.028)),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFE50914) : _glassBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFFE50914,
                            ).withValues(alpha: 0.16),
                            blurRadius: 20,
                            offset: const Offset(0, 12),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? const Color(0xFFE50914)
                            : (isLight
                                  ? Colors.white
                                  : Colors.black.withValues(alpha: 0.24)),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFE50914)
                              : _glassBorder,
                        ),
                      ),
                      child: Icon(
                        category.icon,
                        color: isSelected ? Colors.white : _primaryText,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _copy(category.labelAr, category.labelEn),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _primaryText,
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdCarousel(List<Media> adMedia) {
    final itemCount = adMedia.isEmpty ? 3 : adMedia.length;
    final isLight = _useLightTheme;
    final badgeLabel = _copy(
      adMedia.isEmpty ? 'معرض إعلاني' : '${adMedia.length} إعلان',
      adMedia.isEmpty ? 'Ad Showcase' : '${adMedia.length} Ads',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(child: _SectionTitle('إعلانات', 'اسحب للتصفح')),
            Container(
              padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 8),
              decoration: BoxDecoration(
                color: isLight
                    ? Colors.black.withValues(alpha: 0.05)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _glassBorder),
              ),
              child: Text(
                badgeLabel,
                style: TextStyle(
                  color: _primaryText.withValues(alpha: 0.82),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isLight
                ? Colors.black.withValues(alpha: 0.025)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _glassBorder),
          ),
          child: SizedBox(
            height: 236,
            child: adMedia.length == 1
                ? _AdBanner(media: adMedia.first, index: 0)
                : Directionality(
                    textDirection: TextDirection.ltr,
                    child: PageView.builder(
                      controller: _adPageController,
                      itemCount: itemCount,
                      itemBuilder: (context, index) {
                        final media = adMedia.isEmpty ? null : adMedia[index];
                        return _AdBanner(media: media, index: index);
                      },
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildServices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('الخدمات', 'خدمات سينمائية متكاملة'),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 900
                ? 4
                : constraints.maxWidth > 560
                ? 2
                : 1;
            final ratio = columns == 1
                ? 3.55
                : columns == 2
                ? 2.65
                : 2.45;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _services.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: ratio,
              ),
              itemBuilder: (context, index) {
                final service = _services[index];
                final serviceKey = index >= 0 && index < _serviceKeys.length
                    ? _serviceKeys[index]
                    : 'film';
                return _ServiceCard(
                  service: service,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider(
                          create: (_) => MediaProvider(),
                          child: ServiceFeedScreen(
                            serviceKey: serviceKey,
                            serviceTitle: service.title,
                            serviceSubtitle: service.subtitle,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildTeamSection(
    List<TeamMember> members,
    bool isLoading,
    String? error,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('فريق العمل', 'ملفات تعريف وأعمال أعضاء الفريق'),
        const SizedBox(height: 12),
        if (isLoading && members.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 26),
              child: CircularProgressIndicator(color: Color(0xFFE50914)),
            ),
          )
        else if (error != null && members.isEmpty)
          _GlassPanel(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _copy(
                    'تعذر تحميل فريق العمل.',
                    'Failed to load the team section.',
                  ),
                  style: TextStyle(
                    color: _primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  style: TextStyle(color: _primaryText.withValues(alpha: 0.72)),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () =>
                      context.read<TeamProvider>().fetchTeamMembers(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(_copy('إعادة المحاولة', 'Retry')),
                ),
              ],
            ),
          )
        else if (members.isEmpty)
          _GlassPanel(
            padding: const EdgeInsets.all(18),
            child: Text(
              _copy(
                'أضف أعضاء الفريق من لوحة التحكم ليظهروا هنا.',
                'Add team members from the dashboard to show them here.',
              ),
              style: TextStyle(color: _primaryText.withValues(alpha: 0.74)),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              const gridSpacing = 14.0;
              final columns = constraints.maxWidth > 980
                  ? 4
                  : constraints.maxWidth > 680
                  ? 2
                  : 1;
              final cardWidth =
                  (constraints.maxWidth - (gridSpacing * (columns - 1))) /
                  columns;
              final targetHeight = columns == 1
                  ? (cardWidth < 360 ? 384.0 : 360.0)
                  : columns == 2
                  ? 360.0
                  : 340.0;
              final ratio = cardWidth / targetHeight;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: members.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: gridSpacing,
                  crossAxisSpacing: gridSpacing,
                  childAspectRatio: ratio,
                ),
                itemBuilder: (context, index) {
                  final member = members[index];
                  final authUserId = context.read<AuthProvider>().user?.id;
                  return _TeamMemberSpotlightCard(
                    member: member,
                    isLiked: context.read<TeamProvider>().isMemberLiked(
                      member.id,
                    ),
                    onLike: () async {
                      try {
                        await context.read<TeamProvider>().toggleMemberLike(
                          memberId: member.id,
                          userId: authUserId,
                        );
                      } catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('تعذر تحديث الإعجاب: $error')),
                        );
                      }
                    },
                    onComment: () {
                      showTeamMemberCommentsSheet(context, member: member);
                    },
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TeamMemberProfileScreen(member: member),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildVideoBackdropArea(List<Media> videos, bool isLoading) {
    final railHeight = MediaQuery.sizeOf(context).width < 600 ? 178.0 : 188.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('خلفيات فيديو', 'معاينات متعددة وخفيفة'),
        const SizedBox(height: 12),
        _GlassPanel(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مساحة الفيديوهات المتغيرة',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'افتح أي عنصر لتشغيله',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE50914).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0xFFE50914).withValues(alpha: 0.34),
                      ),
                    ),
                    child: Text(
                      '${videos.length} ${_copy('فيديو', 'Videos')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: SizedBox(
                  height: railHeight,
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFE50914),
                          ),
                        )
                      : videos.isEmpty
                      ? const _EmptyState(
                          icon: Icons.play_circle_outline,
                          text: 'أضف فيديوهات من لوحة الإدارة لتظهر هنا',
                        )
                      : Directionality(
                          textDirection: _textDirection,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsetsDirectional.only(
                              start: 2,
                              end: 2,
                            ),
                            itemCount: videos.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              return _MediaPreview(media: videos[index]);
                            },
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolio(List<Media> mediaList, bool isLoading) {
    final selectedMedia = mediaList.take(8).toList();
    final railHeight = MediaQuery.sizeOf(context).width < 600 ? 198.0 : 208.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('أعمال حديثة', 'صور وفيديوهات'),
        const SizedBox(height: 12),
        _GlassPanel(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'معرض الأعمال',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'أحدث الصور والفيديوهات المضافة.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      '${selectedMedia.length} ${_copy('عنصر', 'Items')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: SizedBox(
                  height: railHeight,
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFE50914),
                          ),
                        )
                      : selectedMedia.isEmpty
                      ? const _EmptyState(
                          icon: Icons.photo_library_outlined,
                          text: 'لا توجد أعمال متاحة الآن',
                        )
                      : Directionality(
                          textDirection: _textDirection,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsetsDirectional.only(
                              start: 2,
                              end: 2,
                            ),
                            itemCount: selectedMedia.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              return _MediaPreview(media: selectedMedia[index]);
                            },
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final isLight = _useLightTheme;
    final valueStyle = TextStyle(
      color: isLight ? Colors.black87 : Colors.white.withValues(alpha: 0.86),
      fontSize: 12,
      height: 1.35,
    );

    Widget item(IconData icon, String label, String value) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE50914).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE50914)),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isLight
                        ? Colors.black.withValues(alpha: 0.72)
                        : Colors.white.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(value, style: valueStyle),
              ],
            ),
          ),
        ],
      );
    }

    bool hasReviewSafeValue(String value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return false;

      const obviousPlaceholders = {
        '0000000000',
        '+966 00 000 0000',
        '+966000000000',
      };

      return !obviousPlaceholders.contains(trimmed);
    }

    return _GlassPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            _copy('بيانات الشركة', 'Company Info'),
            _copy('السجلات والتواصل', 'Records & Contact'),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 880;
              final companyAddress = _copy(
                CompanyInfo.addressAr,
                CompanyInfo.addressEn,
              );
              final items = <Widget>[
                if (hasReviewSafeValue(CompanyInfo.commercialRegister))
                  item(
                    Icons.badge_outlined,
                    _copy('السجل التجاري', 'Commercial register'),
                    CompanyInfo.commercialRegister,
                  ),
                if (hasReviewSafeValue(CompanyInfo.taxNumber))
                  item(
                    Icons.verified_outlined,
                    _copy('الرقم الضريبي', 'Tax number'),
                    CompanyInfo.taxNumber,
                  ),
                if (hasReviewSafeValue(companyAddress))
                  item(
                    Icons.location_on_outlined,
                    _copy('العنوان', 'Address'),
                    companyAddress,
                  ),
                if (hasReviewSafeValue(CompanyInfo.phone))
                  item(
                    Icons.phone_outlined,
                    _copy('الهاتف', 'Phone'),
                    CompanyInfo.phone,
                  ),
                if (hasReviewSafeValue(CompanyInfo.email))
                  item(
                    Icons.email_outlined,
                    _copy('البريد', 'Email'),
                    CompanyInfo.email,
                  ),
                if (hasReviewSafeValue(CompanyInfo.website))
                  item(
                    Icons.public_outlined,
                    _copy('الموقع', 'Website'),
                    CompanyInfo.website,
                  ),
                if (hasReviewSafeValue(CompanyInfo.whatsapp))
                  item(
                    Icons.chat_outlined,
                    _copy('واتساب', 'WhatsApp'),
                    CompanyInfo.whatsapp,
                  ),
              ];

              return Wrap(
                runSpacing: 14,
                spacing: 18,
                children: [
                  for (final child in items)
                    SizedBox(
                      width: isWide
                          ? (constraints.maxWidth / 3) - 18
                          : constraints.maxWidth,
                      child: child,
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            width: double.infinity,
            color: Colors.white.withValues(alpha: isLight ? 0.35 : 0.10),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 680;
              final mutedColor = isLight
                  ? Colors.black.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.55);

              final developerCredit = Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 14, 10),
                  decoration: BoxDecoration(
                    color: isLight
                        ? Colors.white.withValues(alpha: 0.72)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(
                        0xFFE50914,
                      ).withValues(alpha: isLight ? 0.20 : 0.32),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFE50914,
                          ).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.code_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _copy(
                              CompanyInfo.developerCreditAr,
                              CompanyInfo.developerCreditEn,
                            ),
                            style: TextStyle(
                              color: mutedColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          SelectableText(
                            _copy(
                              CompanyInfo.developerNameAr,
                              CompanyInfo.developerNameEn,
                            ),
                            style: TextStyle(
                              color: isLight
                                  ? Colors.black87
                                  : Colors.white.withValues(alpha: 0.92),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );

              final copyright = Text(
                '© ${DateTime.now().year} ${CompanyInfo.nameEn}',
                style: TextStyle(color: mutedColor, fontSize: 12),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    developerCredit,
                    const SizedBox(height: 12),
                    copyright,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: developerCredit),
                  const SizedBox(width: 16),
                  copyright,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactForm(AuthProvider authProvider) {
    return _GlassPanel(
      key: _contactKey,
      padding: const EdgeInsets.all(18),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('تواصل معنا', 'اكتب طلبك وسنرد عليك'),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 720;
                if (!isWide) {
                  return Column(
                    children: [
                      _GlassTextField(
                        controller: _nameController,
                        label: context.tr('الاسم'),
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return context.tr('اكتب الاسم');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _GlassTextField(
                        controller: _emailController,
                        label: context.tr('البريد الإلكتروني'),
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || !value.contains('@')) {
                            return context.tr('اكتب بريد صحيح');
                          }
                          return null;
                        },
                      ),
                    ],
                  );
                }
                return Flex(
                  direction: isWide ? Axis.horizontal : Axis.vertical,
                  children: [
                    Expanded(
                      child: _GlassTextField(
                        controller: _nameController,
                        label: context.tr('الاسم'),
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return context.tr('اكتب الاسم');
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: isWide ? 12 : 0, height: isWide ? 0 : 12),
                    Expanded(
                      child: _GlassTextField(
                        controller: _emailController,
                        label: context.tr('البريد الإلكتروني'),
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || !value.contains('@')) {
                            return context.tr('اكتب بريد صحيح');
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            _GlassTextField(
              controller: _messageController,
              label: context.tr('رسالتك'),
              icon: Icons.chat_bubble_outline,
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.tr('اكتب الرسالة');
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _submitContact,
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(
                  _isSending ? context.tr('جاري الإرسال') : context.tr('إرسال'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _adTimer?.cancel();
    _adPageController.dispose();
    _scrollController.dispose();
    _backgroundController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    _supportNameController.dispose();
    _supportEmailController.dispose();
    _supportMessageController.dispose();
    _supportChatController.dispose();
    super.dispose();
  }
}

class _StoryCategory {
  final String value;
  final String labelAr;
  final String labelEn;
  final IconData icon;

  const _StoryCategory(this.value, this.labelAr, this.labelEn, this.icon);
}

class _ServiceItem {
  final String title;
  final String subtitle;
  final IconData icon;

  const _ServiceItem(this.title, this.subtitle, this.icon);
}

class _SupportChatMessage {
  final String text;
  final bool isUser;

  const _SupportChatMessage(this.text, this.isUser);
}

class _GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  const _GlassPanel({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: isLight
                  ? Colors.white.withValues(alpha: 0.72)
                  : Colors.white.withValues(alpha: 0.075),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isLight
                    ? Colors.black.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _AppIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isActive;
  final int badgeCount;

  const _AppIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final foreground = isLight ? Colors.black87 : Colors.white;

    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onPressed,
            child: Ink(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: isActive
                    ? const Color(0xFFE50914).withValues(alpha: 0.18)
                    : (isLight ? Colors.white : Colors.black).withValues(
                        alpha: 0.18,
                      ),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFFE50914)
                      : Colors.white.withValues(alpha: isLight ? 0.14 : 0.10),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Center(
                      child: Icon(
                        icon,
                        color: isActive ? const Color(0xFFE50914) : foreground,
                        size: 20,
                      ),
                    ),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        constraints: const BoxConstraints(minWidth: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE50914),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountTierChip extends StatelessWidget {
  final String label;

  const _AccountTierChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (label) {
      'VIP' => (Colors.amberAccent, Icons.workspace_premium_outlined),
      'Key Account' => (Colors.lightBlueAccent, Icons.business_center_outlined),
      _ => (Colors.white70, Icons.verified_user_outlined),
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

class _SupportOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SupportOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final titleColor = isLight ? Colors.black : Colors.white;
    final subtitleColor = isLight ? Colors.black54 : Colors.white70;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isLight
              ? Colors.white.withValues(alpha: 0.56)
              : Colors.black.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isLight
                ? Colors.black.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          children: [
            _IconBox(icon: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: subtitleColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: subtitleColor),
          ],
        ),
      ),
    );
  }
}

class _SupportChatBubble extends StatelessWidget {
  final _SupportChatMessage message;

  const _SupportChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final alignment = isUser ? Alignment.centerLeft : Alignment.centerRight;
    final backgroundColor = isUser
        ? const Color(0xFFE50914)
        : isLight
        ? Colors.white.withValues(alpha: 0.78)
        : Colors.black.withValues(alpha: 0.34);
    final textColor = isUser
        ? Colors.white
        : (isLight ? Colors.black : Colors.white);

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isUser
                  ? const Color(0xFFE50914)
                  : Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: Text(message.text, style: TextStyle(color: textColor)),
        ),
      ),
    );
  }
}

class _DailyStoryCircle extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final IconData icon;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;

  const _DailyStoryCircle({
    required this.label,
    required this.icon,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    Widget fallback() {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black.withValues(alpha: 0.72),
              const Color(0xFFE50914).withValues(alpha: 0.18),
              Colors.black.withValues(alpha: 0.85),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.92),
            size: 26,
          ),
        ),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(48),
      onTap: onTap,
      child: SizedBox(
        width: 78,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 2.6),
              ),
              child: ClipOval(
                child: imageUrl == null
                    ? fallback()
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          Positioned.fill(
                            child: AppNetworkImage(
                              url: imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: fallback(),
                              errorWidget: fallback(),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE50914),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: textColor, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String? value;
  final String label;
  final IconData icon;

  const _MetricTile({this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final titleColor = isLight ? Colors.black : Colors.white;
    final subtleColor = isLight ? Colors.black54 : Colors.white70;
    const accentColor = Color(0xFFE50914);

    return Expanded(
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isLight
                ? [
                    Colors.white.withValues(alpha: 0.88),
                    Colors.white.withValues(alpha: 0.56),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.11),
                    Colors.black.withValues(alpha: 0.20),
                  ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isLight
                ? accentColor.withValues(alpha: 0.20)
                : Colors.white.withValues(alpha: 0.14),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 27,
              child: Center(
                child: (value != null && value!.isNotEmpty)
                    ? FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, color: accentColor, size: 17),
                            const SizedBox(width: 6),
                            Text(
                              value!,
                              style: TextStyle(
                                color: titleColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Icon(icon, color: accentColor, size: 25),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: subtleColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle(this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final titleColor = isLight ? Colors.black : Colors.white;
    final subtitleColor = isLight ? Colors.black54 : Colors.white60;
    return Row(
      children: [
        Container(width: 4, height: 30, color: const Color(0xFFE50914)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(color: subtitleColor, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdBanner extends StatelessWidget {
  final Media? media;
  final int index;

  const _AdBanner({required this.media, required this.index, super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        width: double.infinity,
        height: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _fallbackBackground(),

              if (media?.isVideo == true)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AutoPlayVideoPreview(
                      url: Uri.parse(media!.url),
                      fit: BoxFit.cover,
                      placeholder: media!.previewImageUrl != null
                          ? AppNetworkImage(
                              url: media!.previewImageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: _fallbackBackground(),
                              errorWidget: _fallbackBackground(),
                            )
                          : _fallbackBackground(),
                      errorWidget: media!.previewImageUrl != null
                          ? AppNetworkImage(
                              url: media!.previewImageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: _fallbackBackground(),
                              errorWidget: _fallbackBackground(),
                            )
                          : _fallbackBackground(),
                    ),
                  ),
                )
              else if (media?.previewImageUrl != null)
                Positioned.fill(
                  child: AppNetworkImage(
                    url: media!.previewImageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: _fallbackBackground(),
                    errorWidget: _fallbackBackground(),
                  ),
                ),

              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color.fromRGBO(0, 0, 0, 0.84)],
                  ),
                ),
              ),

              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      media?.title ??
                          _fallbackTitles[index % _fallbackTitles.length],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      media?.description ??
                          'إعلان متحرك بهوية بصرية سينمائية ولمسات عرض حديثة.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackBackground() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE50914), Colors.black],
        ),
      ),
    );
  }

  static const _fallbackTitles = [
    'حملة إعلانية جديدة',
    'مونتاچ سريع للسوشيال',
    'تصوير منتجات وفيديوهات',
  ];
}

class _ServiceCard extends StatefulWidget {
  final _ServiceItem service;
  final VoidCallback onTap;

  const _ServiceCard({required this.service, required this.onTap});

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final titleColor = isLight ? Colors.black : Colors.white;
    final subtitleColor = isLight ? Colors.black54 : Colors.white70;
    const accentColor = Color(0xFFE50914);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isLight ? 0.08 : 0.26),
              blurRadius: _isHovered ? 24 : 16,
              offset: Offset(0, _isHovered ? 14 : 9),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                child: Ink(
                  decoration: BoxDecoration(
                    color: isLight
                        ? Colors.white.withValues(alpha: 0.76)
                        : const Color(0xFF241015).withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isHovered
                          ? accentColor.withValues(alpha: 0.68)
                          : isLight
                          ? Colors.black.withValues(alpha: 0.10)
                          : Colors.white.withValues(alpha: 0.13),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: isLight
                          ? [
                              Colors.white.withValues(alpha: 0.92),
                              accentColor.withValues(alpha: 0.05),
                              Colors.white.withValues(alpha: 0.62),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.08),
                              accentColor.withValues(
                                alpha: _isHovered ? 0.15 : 0.08,
                              ),
                              Colors.black.withValues(alpha: 0.20),
                            ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      PositionedDirectional(
                        start: 0,
                        top: 0,
                        bottom: 0,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: _isHovered ? 5 : 3,
                          color: accentColor.withValues(
                            alpha: _isHovered ? 0.92 : 0.56,
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        end: 12,
                        bottom: -28,
                        child: Icon(
                          widget.service.icon,
                          size: 92,
                          color: accentColor.withValues(alpha: 0.055),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          18,
                          16,
                          16,
                          16,
                        ),
                        child: Row(
                          children: [
                            _ServiceIconBadge(
                              icon: widget.service.icon,
                              isHovered: _isHovered,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr(widget.service.title),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: titleColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      height: 1.15,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    context.tr(widget.service.subtitle),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: subtitleColor,
                                      fontSize: 12,
                                      height: 1.45,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            AnimatedOpacity(
                              opacity: _isHovered ? 1 : 0.62,
                              duration: const Duration(milliseconds: 180),
                              child: Icon(
                                isRtl
                                    ? Icons.arrow_back_ios_new
                                    : Icons.arrow_forward_ios,
                                color: _isHovered
                                    ? accentColor
                                    : subtitleColor.withValues(alpha: 0.78),
                                size: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceIconBadge extends StatelessWidget {
  final IconData icon;
  final bool isHovered;

  const _ServiceIconBadge({required this.icon, required this.isHovered});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFE50914);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isHovered ? 0.24 : 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accentColor.withValues(alpha: isHovered ? 1 : 0.78),
        ),
        boxShadow: [
          if (isHovered)
            BoxShadow(
              color: accentColor.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

class _TeamMemberSpotlightCard extends StatelessWidget {
  final TeamMember member;
  final bool isLiked;
  final VoidCallback onTap;
  final Future<void> Function() onLike;
  final VoidCallback onComment;

  const _TeamMemberSpotlightCard({
    required this.member,
    required this.isLiked,
    required this.onTap,
    required this.onLike,
    required this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final titleColor = isLight ? Colors.black : Colors.white;
    final subtitleColor = isLight ? Colors.black54 : Colors.white70;
    const compactButtonTextStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
    );

    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: isLight
                  ? Colors.white.withValues(alpha: 0.68)
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isLight
                    ? Colors.black.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.12),
              ),
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  const Color(
                    0xFFE50914,
                  ).withValues(alpha: isLight ? 0.07 : 0.12),
                  Colors.transparent,
                  Colors.black.withValues(alpha: isLight ? 0.02 : 0.08),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 60,
                          height: 60,
                          child: member.photoUrl.trim().isEmpty
                              ? Container(
                                  color: Colors.white10,
                                  child: const Icon(
                                    Icons.person_outline,
                                    color: Colors.white70,
                                  ),
                                )
                              : AppNetworkImage(
                                  url: member.photoUrl,
                                  fit: BoxFit.cover,
                                  placeholder: const ColoredBox(
                                    color: Colors.white10,
                                  ),
                                  errorWidget: const ColoredBox(
                                    color: Colors.white10,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: titleColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              member.role,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFE50914,
                                ).withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${member.portfolio.length} ${member.portfolio.length == 1 ? 'عمل' : 'أعمال'}',
                                style: TextStyle(
                                  color: titleColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: subtitleColor,
                        size: 14,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TeamMemberMetricChips(member: member, dense: true),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      primary: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (member.bio.trim().isNotEmpty)
                            Text(
                              member.bio,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 12.5,
                                height: 1.45,
                              ),
                            ),
                          if (member.bio.trim().isNotEmpty &&
                              member.skills.isNotEmpty)
                            const SizedBox(height: 12),
                          if (member.skills.isNotEmpty)
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: member.skills
                                  .take(2)
                                  .map(
                                    (skill) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.06,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: Colors.white12,
                                        ),
                                      ),
                                      child: Text(
                                        skill,
                                        style: TextStyle(
                                          color: titleColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                          if (member.certifications.isNotEmpty) ...[
                            if (member.skills.isNotEmpty)
                              const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: member.certifications
                                  .take(2)
                                  .map(
                                    (asset) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFE50914,
                                        ).withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: const Color(
                                            0xFFE50914,
                                          ).withValues(alpha: 0.35),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            asset.isVideo
                                                ? Icons.play_circle_outline
                                                : Icons
                                                      .workspace_premium_outlined,
                                            size: 12,
                                            color: titleColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            asset.title,
                                            style: TextStyle(
                                              color: titleColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async => onLike(),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 11,
                            ),
                            textStyle: compactButtonTextStyle,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: Icon(
                            isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border,
                            size: 16,
                          ),
                          label: Text(
                            isLiked ? 'تم الإعجاب' : 'إعجاب',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onComment,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 11,
                            ),
                            textStyle: compactButtonTextStyle,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(
                            Icons.mode_comment_outlined,
                            size: 16,
                          ),
                          label: Text(
                            'التعليقات',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: titleColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;

  const _IconBox({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFE50914).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE50914)),
      ),
      child: Icon(icon, color: Colors.white),
    );
  }
}

class _MediaPreview extends StatelessWidget {
  final Media media;

  const _MediaPreview({required this.media});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final cardWidth = screenWidth < 600
        ? ((screenWidth - 44) / 2).clamp(136.0, 190.0)
        : screenWidth < 900
        ? 210.0
        : 230.0;

    return SizedBox(
      width: cardWidth,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            if (media.isVideo) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoPlayerScreen(media: media),
                ),
              );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MediaDetailScreen(media: media),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  blurRadius: 20,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: Colors.black),
                  if (media.isVideo)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AutoPlayVideoPreview(
                          url: Uri.parse(media.url),
                          fit: BoxFit.cover,
                          placeholder: media.previewImageUrl != null
                              ? AppNetworkImage(
                                  url: media.previewImageUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: Container(color: Colors.white10),
                                  errorWidget: Container(
                                    color: Colors.white10,
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : Container(color: Colors.white10),
                          errorWidget: media.previewImageUrl != null
                              ? AppNetworkImage(
                                  url: media.previewImageUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: Container(color: Colors.white10),
                                  errorWidget: Container(
                                    color: Colors.white10,
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : Container(color: Colors.white10),
                        ),
                      ),
                    )
                  else if (media.previewImageUrl != null)
                    Positioned.fill(
                      child: AppNetworkImage(
                        url: media.previewImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: Container(color: Colors.white10),
                        errorWidget: Container(
                          color: Colors.white10,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.08),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.92),
                        ],
                        stops: const [0.0, 0.35, 1.0],
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    top: 10,
                    start: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.34),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Icon(
                        media.isVideo
                            ? Icons.play_arrow_rounded
                            : Icons.image_outlined,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  if (media.isVideo)
                    Container(
                      margin: const EdgeInsets.all(12),
                      alignment: Alignment.center,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.90),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.28),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Color(0xFFE50914),
                          size: 30,
                        ),
                      ),
                    ),
                  PositionedDirectional(
                    start: 10,
                    end: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.42),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        media.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: isRtl ? TextAlign.right : TextAlign.left,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white54, size: 38),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(color: Colors.white60)),
        ],
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _GlassTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textColor = isLight ? Colors.black : Colors.white;
    final mutedColor = isLight ? Colors.black54 : Colors.white70;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: mutedColor),
        prefixIcon: Icon(icon, color: mutedColor),
        filled: true,
        fillColor: isLight
            ? Colors.white.withValues(alpha: 0.42)
            : Colors.black.withValues(alpha: 0.24),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isLight
                ? Colors.black.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.16),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE50914), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE50914)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE50914), width: 1.5),
        ),
      ),
    );
  }
}
