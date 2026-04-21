import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/media.dart';
import '../providers/auth_provider.dart';
import '../providers/media_provider.dart';
import '../providers/response_provider.dart';
import '../config/company_info.dart';
import '../widgets/app_network_image.dart';
import 'admin/admin_dashboard.dart';
import 'media_detail_screen.dart';
import 'story_view_screen.dart';

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
  bool _isArabic = true;
  _HomeThemeMode _themeMode = _HomeThemeMode.dark;
  bool _didPrefillContactForm = false;
  final List<_SupportChatMessage> _supportChatMessages = [
    const _SupportChatMessage(
      'أهلًا بك في دعم Media House Edge. أنا المساعد الآلي، اكتب طلبك وسأساعدك إلى أن يستلم أحد من خدمة العملاء المحادثة.',
      false,
    ),
  ];

  final List<_StoryCategory> _categories = const [
    _StoryCategory('all', 'الكل', Icons.auto_awesome),
    _StoryCategory('film', 'تصوير', Icons.movie_creation_outlined),
    _StoryCategory('montage', 'مونتاج', Icons.content_cut),
    _StoryCategory('advertisement', 'إعلانات', Icons.campaign_outlined),
  ];

  final List<_ServiceItem> _services = const [
    _ServiceItem('إنتاج فيديو', 'تصوير وإخراج بمظهر سينمائي', Icons.videocam_outlined),
    _ServiceItem('مونتاج', 'قص، تلوين، ومؤثرات خفيفة', Icons.tune_outlined),
    _ServiceItem('إعلانات', 'بانرات وحملات للسوشيال ميديا', Icons.ads_click_outlined),
    _ServiceItem('هوية بصرية', 'تصميم محتوى ثابت ومتحرك', Icons.palette_outlined),
  ];

  TextDirection get _textDirection =>
      _isArabic ? TextDirection.rtl : TextDirection.ltr;

  bool get _useLightTheme {
    if (_themeMode == _HomeThemeMode.light) return true;
    if (_themeMode == _HomeThemeMode.dark) return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.light;
  }

  Color get _pageBackground => _useLightTheme ? Colors.white : Colors.black;
  Color get _primaryText => _useLightTheme ? Colors.black : Colors.white;
  Color get _glassBorder =>
      _useLightTheme ? Colors.black.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.12);

  String _copy(String ar, String en) => _isArabic ? ar : en;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _loadMedia();
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

  void _loadMedia() {
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
    if (_selectedCategory == 'all') {
      mediaProvider.fetchMedia();
    } else {
      mediaProvider.fetchMedia(category: _selectedCategory);
    }
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
      await Provider.of<ResponseProvider>(context, listen: false).submitResponse(
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
        const SnackBar(content: Text('تم إرسال رسالتك بنجاح')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر الإرسال: $error')),
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
                                  fontWeight: FontWeight.w900,
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
                      title: _copy('التحدث مع خدمة العملاء', 'Chat with support'),
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
                          fontWeight: FontWeight.w900,
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
                            return _copy('اكتب بريد صحيح', 'Enter a valid email');
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
                              onPressed: () => _sendSupportMessage(dialogContext),
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
                  constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
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
                                  fontWeight: FontWeight.w900,
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
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
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
                                  fillColor: Colors.black.withValues(alpha: 0.18),
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
                              onPressed: () => _sendSupportChatMessage(setModalState),
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
      await Provider.of<ResponseProvider>(context, listen: false).submitResponse(
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

    Provider.of<ResponseProvider>(context, listen: false).submitResponse(
      clientName: _supportNameController.text.trim().isEmpty
          ? 'Support chat user'
          : _supportNameController.text.trim(),
      clientEmail: _supportEmailController.text.trim().contains('@')
          ? _supportEmailController.text.trim()
          : 'support-chat@mediahouse.local',
      message: 'Support chat: $text',
      rating: 5,
    ).catchError((_) {});
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
                    user?.username.isNotEmpty == true ? user!.username : 'الحساب',
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await authProvider.logout();
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('تسجيل الخروج'),
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
    final mediaList = mediaProvider.mediaList;
    final adMedia = mediaList
        .where((media) => media.category == 'advertisement')
        .take(6)
        .toList();
    _syncAdItemCount(adMedia.isEmpty ? 3 : adMedia.length);
    final videoMedia = mediaList.where((media) => media.isVideo).take(8).toList();
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
          textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Cairo'),
        ),
        child: Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: _pageBackground,
      appBar: _buildAppBar(authProvider),
      floatingActionButton: FloatingActionButton(
        onPressed: _openSupportDialog,
        backgroundColor: const Color(0xFFE50914),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                        _buildVideoBackdropArea(videoMedia, mediaProvider.isLoading),
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
    return AppBar(
      toolbarHeight: 50,
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 16,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: (_useLightTheme ? Colors.white : Colors.black)
                  .withValues(alpha: 0.56),
              border: Border(
                bottom: BorderSide(color: _glassBorder),
              ),
            ),
          ),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: 28,
            height: 28,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          Text(
            'Media House Edge',
            style: TextStyle(
              color: _primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      actions: [
        _AppIconButton(
          icon: Icons.translate,
          onPressed: () => setState(() => _isArabic = !_isArabic),
        ),
        _AppIconButton(
          icon: _themeMode == _HomeThemeMode.light
              ? Icons.light_mode_outlined
              : _themeMode == _HomeThemeMode.dark
                  ? Icons.dark_mode_outlined
                  : Icons.brightness_auto_outlined,
          onPressed: _cycleThemeMode,
        ),
        if (authProvider.isAdmin)
          _AppIconButton(
            icon: Icons.dashboard_outlined,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminDashboard()),
              );
            },
          ),
        if (!authProvider.isAuthenticated)
          _AppIconButton(
            icon: Icons.login,
            onPressed: () => Navigator.pushNamed(context, '/login'),
          )
        else
          _AppIconButton(
            icon: Icons.account_circle_outlined,
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
                          (light ? Colors.black : Colors.white)
                              .withValues(alpha: 0.08),
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
    final title = _copy('إنتاج محتوى يبان بقوة', 'Content that lands strong');
    final subtitle = _copy(
      'تصوير، مونتاج، إعلانات، ومحتوى متحرك بخط بصري واضح.',
      'Film, editing, ads, and motion content with a clear visual line.',
    );
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: _primaryText,
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(color: _primaryText.withValues(alpha: 0.70), fontSize: 15),
        ),
      ],
    );
    final metrics = Row(
      children: [
        _MetricTile('24/7', _copy('دعم', 'Support')),
        const SizedBox(width: 10),
        _MetricTile('HD', _copy('إخراج', 'Output')),
        const SizedBox(width: 10),
        _MetricTile('Fast', _copy('تنفيذ', 'Delivery')),
      ],
    );

    return _GlassPanel(
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 720;
          if (!isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleBlock,
                const SizedBox(height: 16),
                metrics,
              ],
            );
          }
          return Flex(
            direction: isWide ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: isWide ? 2 : 0,
                child: titleBlock,
              ),
              if (isWide) const SizedBox(width: 18) else const SizedBox(height: 16),
              Expanded(flex: isWide ? 1 : 0, child: metrics),
            ],
          );
        },
      ),
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
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (stories.isEmpty)
          Text(
            _copy(
              'لا توجد حالات مضافة الآن',
              'No stories added yet',
            ),
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
                  imageUrl:
                      media.isVideo ? media.thumbnail : (media.thumbnail ?? media.url),
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
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category.value;
          return InkWell(
            borderRadius: BorderRadius.circular(48),
            onTap: () {
              setState(() => _selectedCategory = category.value);
              _loadMedia();
            },
            child: SizedBox(
              width: 76,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.34),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFE50914) : Colors.white30,
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFFE50914)
                                    .withValues(alpha: 0.28),
                                blurRadius: 16,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(category.icon, color: Colors.white, size: 27),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _copy(category.label, category.value.toUpperCase()),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: _primaryText, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdCarousel(List<Media> adMedia) {
    final itemCount = adMedia.isEmpty ? 3 : adMedia.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('إعلانات متحركة', 'اسحب يمين وشمال'),
        const SizedBox(height: 12),
        SizedBox(
          height: 230,
          child: PageView.builder(
            controller: _adPageController,
            itemCount: itemCount,
            itemBuilder: (context, index) {
              final media = adMedia.isEmpty ? null : adMedia[index];
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: 12),
                child: _AdBanner(media: media, index: index),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('الخدمات', 'حلول سريعة للمحتوى'),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 900
                ? 4
                : constraints.maxWidth > 560
                    ? 2
                    : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _services.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: columns == 1 ? 3.8 : 2.4,
              ),
              itemBuilder: (context, index) {
                final service = _services[index];
                return _GlassPanel(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      _IconBox(icon: service.icon),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              service.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildVideoBackdropArea(List<Media> videos, bool isLoading) {
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
              const Text(
                'مساحة الفيديوهات المتغيرة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'المعاينات لا تعمل تلقائيًا للحفاظ على سرعة الصفحة. افتح أي عنصر لتشغيله.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 160,
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFFE50914)),
                      )
                    : videos.isEmpty
                        ? const _EmptyState(
                            icon: Icons.play_circle_outline,
                            text: 'أضف فيديوهات من لوحة الإدارة لتظهر هنا',
                          )
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: videos.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              return _MediaPreview(media: videos[index]);
                            },
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('أعمال حديثة', 'صور وفيديوهات'),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE50914)),
                )
              : selectedMedia.isEmpty
                  ? const _EmptyState(
                      icon: Icons.photo_library_outlined,
                      text: 'لا توجد أعمال متاحة الآن',
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: selectedMedia.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return _MediaPreview(media: selectedMedia[index]);
                      },
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
                    fontWeight: FontWeight.w800,
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
              final items = <Widget>[
                item(
                  Icons.badge_outlined,
                  _copy('السجل التجاري', 'Commercial register'),
                  CompanyInfo.commercialRegister,
                ),
                item(
                  Icons.verified_outlined,
                  _copy('الرقم الضريبي', 'Tax number'),
                  CompanyInfo.taxNumber,
                ),
                item(
                  Icons.location_on_outlined,
                  _copy('العنوان', 'Address'),
                  _copy(CompanyInfo.addressAr, CompanyInfo.addressEn),
                ),
                item(
                  Icons.phone_outlined,
                  _copy('الهاتف', 'Phone'),
                  CompanyInfo.phone,
                ),
                item(
                  Icons.email_outlined,
                  _copy('البريد', 'Email'),
                  CompanyInfo.email,
                ),
                item(
                  Icons.public_outlined,
                  _copy('الموقع', 'Website'),
                  CompanyInfo.website,
                ),
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
          Text(
            '© ${DateTime.now().year} ${CompanyInfo.nameEn}',
            style: TextStyle(
              color: isLight
                  ? Colors.black.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.55),
              fontSize: 12,
            ),
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
                        label: 'الاسم',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'اكتب الاسم';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _GlassTextField(
                        controller: _emailController,
                        label: 'البريد الإلكتروني',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || !value.contains('@')) {
                            return 'اكتب بريد صحيح';
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
                        label: 'الاسم',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'اكتب الاسم';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: isWide ? 12 : 0, height: isWide ? 0 : 12),
                    Expanded(
                      child: _GlassTextField(
                        controller: _emailController,
                        label: 'البريد الإلكتروني',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || !value.contains('@')) {
                            return 'اكتب بريد صحيح';
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
              label: 'رسالتك',
              icon: Icons.chat_bubble_outline,
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'اكتب الرسالة';
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
                label: Text(_isSending ? 'جاري الإرسال' : 'إرسال'),
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
  final String label;
  final IconData icon;

  const _StoryCategory(this.value, this.label, this.icon);
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
  final VoidCallback onPressed;

  const _AppIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final foreground =
        Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white;
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: foreground, size: 22),
      splashRadius: 22,
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
                      fontWeight: FontWeight.w800,
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
    final textColor = isUser ? Colors.white : (isLight ? Colors.black : Colors.white);

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
          child: Icon(icon, color: Colors.white.withValues(alpha: 0.92), size: 26),
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
                          AppNetworkImage(
                            url: imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: fallback(),
                            errorWidget: fallback(),
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
  final String value;
  final String label;

  const _MetricTile(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Expanded(
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: isLight
              ? Colors.white.withValues(alpha: 0.50)
              : Colors.black.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isLight
                ? Colors.black.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                color: isLight ? Colors.black : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: isLight ? Colors.black54 : Colors.white60),
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
                  fontWeight: FontWeight.w900,
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

  const _AdBanner({required this.media, required this.index});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (media?.thumbnail != null || media?.url != null)
            AppNetworkImage(
              url: media?.thumbnail ?? media!.url,
              fit: BoxFit.cover,
              placeholder: _fallbackBackground(),
              errorWidget: _fallbackBackground(),
            )
          else
            _fallbackBackground(),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.84),
                ],
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
                  media?.title ?? _fallbackTitles[index % _fallbackTitles.length],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  media?.description ?? 'إعلان متحرك بخط أحمر وأسود وواجهة زجاجية.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackBackground() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE50914).withValues(alpha: 0.86),
            Colors.black,
          ],
        ),
      ),
    );
  }

  static const _fallbackTitles = [
    'حملة إعلانية جديدة',
    'مونتاج سريع للسوشيال',
    'تصوير منتجات وفيديوهات',
  ];
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
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MediaDetailScreen(media: media)),
        );
      },
      child: SizedBox(
        width: 230,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppNetworkImage(
                url: media.thumbnail ?? media.url,
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
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.86),
                    ],
                  ),
                ),
              ),
              if (media.isVideo)
                const Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 46,
                  ),
                ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 10,
                child: Text(
                  media.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
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
