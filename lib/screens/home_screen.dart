import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/scheduler.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
      routes: {
        '/': (_) => const HomeScreen(username: 'user'),
        '/aichat': (_) => const Scaffold(body: Center(child: Text('AI Chat'))),
        '/explore': (_) => const Scaffold(body: Center(child: Text('Explore'))),
        '/settings': (_) => const Scaffold(body: Center(child: Text('Settings'))),
        '/profile': (_) => const Scaffold(body: Center(child: Text('Profile'))),
        '/photo_scan': (_) => const Scaffold(body: Center(child: Text('Photo Scan'))),
      },
    );
  }
}

/// ✅ Mouse drag support for web/desktop (ListView/PageView etc.)
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}

/// =========================
/// ✅ Marketplace model data (for Trending popup)
/// =========================
class MarketModel {
  final String name;
  final String author;
  final String description;
  final List<String> tags;
  final String likes;
  final String tagLabel;
  final String glbAssetPath;
  final String posterAssetPath;

  const MarketModel({
    required this.name,
    required this.author,
    required this.description,
    required this.tags,
    required this.likes,
    required this.tagLabel,
    required this.glbAssetPath,
    required this.posterAssetPath,
  });
}

class HomeScreen extends StatefulWidget {
  final String username;

  const HomeScreen({super.key, required this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;
  int _webActiveNavIndex = 0;
  int? _webHoverNavIndex;

  late final ScrollController _scrollController;
  bool _collapsed = false;
  bool _isLoading = true;

  // ===== Use Cases =====
  int _selectedUseCase = 0;

  // ✅ Use ListView controller (no centering)
  late final ScrollController _useCaseScrollController;

  Timer? _useCaseAutoTimer;
  bool _pauseUseCaseAutoScroll = false;
  bool _isUserDraggingUseCases = false;

  Timer? _resumeAutoAfterTap;

  bool _lastIsWeb = false;

  /// ✅ NEW: popup selected model
  MarketModel? _activeMarketModel;

  final List<Map<String, String>> _useCases = const [
    {"id": "film", "title": "Film Production", "asset": "assets/usecases/film.png"},
    {"id": "product", "title": "Product Design", "asset": "assets/usecases/product.png"},
    {"id": "edu", "title": "Education", "asset": "assets/usecases/education.png"},
    {"id": "game", "title": "Game\nDevelopment", "asset": "assets/usecases/game.png"},
    {"id": "print", "title": "3D Printing", "asset": "assets/usecases/printing.png"},
    {"id": "vr", "title": "VR/AR", "asset": "assets/usecases/vr.png"},
    {"id": "interior", "title": "Interior Design", "asset": "assets/usecases/interior.png"},
  ];

  final List<Map<String, dynamic>> _useCaseDetails = const [
    {
      "id": "film",
      "title": "Film Production",
      "subtitle": "Cut costs and accelerate VFX and previs workflows with R2V AI",
      "bullets": ["Fast Previs & Look Dev", "Streamlined VFX Workflow", "Industry-Standard Quality"],
      "cta": "Explore More",
      "ctaRoute": "/explore",
      "preview": "assets/usecase_previews/film.png",
      "accent": Color(0xFF9CA3AF),
    },
    {
      "id": "product",
      "title": "Product Design",
      "subtitle": "Prototype faster with AI-assisted 3D concepts and ready assets.",
      "bullets": ["Rapid Ideation", "Accurate Scale Mockups", "Export-Ready Models"],
      "cta": "Explore More",
      "ctaRoute": "/explore",
      "preview": "assets/usecase_previews/product.png",
      "accent": Color(0xFF38BDF8),
    },
    {
      "id": "edu",
      "title": "Education",
      "subtitle": "Teach 3D concepts interactively with instant models and scans.",
      "bullets": ["Interactive Lessons", "Visual Learning", "Student Projects"],
      "cta": "Explore More",
      "ctaRoute": "/explore",
      "preview": "assets/usecase_previews/education.png",
      "accent": Color(0xFFFDE68A),
    },
    {
      "id": "game",
      "title": "Game Development",
      "subtitle": "Generate and iterate on assets faster for your next game world.",
      "bullets": ["Concept to Asset", "Style Variations", "Faster Iteration"],
      "cta": "Explore More",
      "ctaRoute": "/explore",
      "preview": "assets/usecase_previews/game.png",
      "accent": Color(0xFF22D3EE),
    },
    {
      "id": "print",
      "title": "3D Printing",
      "subtitle": "Scan real objects and convert ideas into printable 3D models.",
      "bullets": ["Scan to STL", "Repair & Optimize", "Print-Ready Output"],
      "cta": "Start Scan",
      "ctaRoute": "/photo_scan",
      "preview": "assets/usecase_previews/printing.png",
      "accent": Color(0xFFA3E635),
    },
    {
      "id": "vr",
      "title": "VR/AR",
      "subtitle": "Build immersive experiences with quick, clean 3D content.",
      "bullets": ["Lightweight Assets", "Realistic Textures", "GLB/FBX Export"],
      "cta": "Explore More",
      "ctaRoute": "/explore",
      "preview": "assets/usecase_previews/vr.png",
      "accent": Color(0xFFC084FC),
    },
    {
      "id": "interior",
      "title": "Interior Design",
      "subtitle": "Create and visualize spaces with furniture and room assets.",
      "bullets": ["Room Mockups", "Asset Library", "Client Presentations"],
      "cta": "Explore More",
      "ctaRoute": "/explore",
      "preview": "assets/usecase_previews/interior.png",
      "accent": Color(0xFFFCA5A5),
    },
  ];

  final List<Map<String, String>> _scanHistory = const [
    {"title": "Sneaker Prototype", "status": "Completed", "time": "2h ago"},
    {"title": "Vintage Chair", "status": "Processing", "time": "10m ago"},
    {"title": "Ceramic Vase", "status": "Failed", "time": "Yesterday"},
  ];

  /// ✅ UPDATED: trending models include GLB/poster paths
  final List<MarketModel> _trending = const [
    MarketModel(
      name: "Porsche 911",
      author: "McLaughlin Rh",
      description: "911 sports car, clean geometry, studio lighting.",
      tags: ["car", "game-ready", "complex", "edges", "symmetric"],
      likes: "1.2k",
      tagLabel: "Trending",
      glbAssetPath: "assets/models/911.glb",
      posterAssetPath: "assets/posters/911.png",
    ),
  ];

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController()..addListener(_onScroll);
    _useCaseScrollController = ScrollController();

    _startUseCaseAutoSwitch();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _onScroll() {
    final dir = _scrollController.position.userScrollDirection;
    if (dir == ScrollDirection.reverse && !_collapsed) {
      setState(() => _collapsed = true);
    } else if (dir == ScrollDirection.forward && _collapsed) {
      setState(() => _collapsed = false);
    }
  }

  // ✅ Auto-switch ONLY selection/details (row does NOT "center" or jump)
  void _startUseCaseAutoSwitch() {
    _useCaseAutoTimer?.cancel();

    _useCaseAutoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      if (_pauseUseCaseAutoScroll) return;
      if (_isUserDraggingUseCases) return;

      // Only auto-switch on "Home"
      if (_lastIsWeb) {
        if (_webActiveNavIndex != 0) return;
      } else {
        if (_selectedTab != 0) return;
      }

      setState(() => _selectedUseCase = (_selectedUseCase + 1) % _useCases.length);
    });
  }

  void _stopUseCaseAutoScroll() {
    _useCaseAutoTimer?.cancel();
    _useCaseAutoTimer = null;
  }

  void _pauseAfterTap() {
    setState(() => _pauseUseCaseAutoScroll = true);
    _resumeAutoAfterTap?.cancel();
    _resumeAutoAfterTap = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _pauseUseCaseAutoScroll = false);
    });
  }

  void _onUseCaseTap(int idx) {
    setState(() => _selectedUseCase = idx);
    _pauseAfterTap();
  }

  @override
  void dispose() {
    _stopUseCaseAutoScroll();
    _resumeAutoAfterTap?.cancel();
    _scrollController.dispose();
    _useCaseScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isWeb = MediaQuery.of(context).size.width >= 900;
    _lastIsWeb = isWeb;

    return Stack(
      children: [
        // ✅ Particle mesh background (like meshy.ai)
        const Positioned.fill(child: MeshyParticleBackground()),

        // ✅ Your app UI above it
        Positioned.fill(
          child: isWeb ? _buildWebHome(context) : _buildMobileHome(context),
        ),

        // ✅ NEW: Trending popup overlay
        if (_activeMarketModel != null)
          Positioned.fill(
            child: _MarketModelPopup(
              model: _activeMarketModel!,
              onClose: () => setState(() => _activeMarketModel = null),
            ),
          ),
      ],
    );
  }

  // =========================
  // WEB
  // =========================
  Widget _buildWebHome(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final double contentWidth = w > 1180 ? 1180 : w;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentWidth),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildWebTopBar(context),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWebHeroSection(context),
                      const SizedBox(height: 34),

                      MouseRegion(
                        onEnter: (_) => setState(() => _pauseUseCaseAutoScroll = true),
                        onExit: (_) => setState(() => _pauseUseCaseAutoScroll = false),
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (n) {
                            if (n is ScrollStartNotification) _isUserDraggingUseCases = true;
                            if (n is ScrollEndNotification) _isUserDraggingUseCases = false;
                            return false;
                          },
                          child: UseCasesRow(
                            items: _useCases,
                            selectedIndex: _selectedUseCase,
                            controller: _useCaseScrollController,
                            onTap: _onUseCaseTap,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ✅ Details: slide from LEFT → RIGHT (swipe right feel)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, anim) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(-0.06, 0),
                              end: Offset.zero,
                            ).animate(anim),
                            child: FadeTransition(opacity: anim, child: child),
                          );
                        },
                        child: UseCaseDetailsSection(
                          key: ValueKey(_useCaseDetails[_selectedUseCase]["id"]),
                          data: _useCaseDetails[_selectedUseCase],
                          onCta: () => Navigator.pushNamed(context, _useCaseDetails[_selectedUseCase]["ctaRoute"]),
                        ),
                      ),

                      const SizedBox(height: 30),
                      _buildWebFeatureRow(),
                      const SizedBox(height: 32),
                      _buildWebTrendingSection(),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebTopBar(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 26, color: Color(0xFFBC70FF)),
              const SizedBox(width: 8),
              const Text(
                "R2V Studio",
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              SizedBox(width: 380, child: _buildWebNavTabs(context)),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle),
                  child: const Icon(Icons.person, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebNavTabs(BuildContext context) {
    final labels = ["Home", "AI Studio", "Marketplace", "Settings"];
    final navCount = labels.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final segmentWidth = totalWidth / navCount;
        const indicatorWidth = 48.0;
        final underlineIndex = (_webHoverNavIndex ?? _webActiveNavIndex).clamp(0, navCount - 1);
        final underlineLeft = underlineIndex * segmentWidth + (segmentWidth - indicatorWidth) / 2;

        return SizedBox(
          height: 34,
          child: Stack(
            children: [
              Row(
                children: List.generate(navCount, (index) {
                  final isActive = _webActiveNavIndex == index;
                  final isHover = _webHoverNavIndex == index;
                  final effectiveActive = isActive || isHover;

                  return MouseRegion(
                    onEnter: (_) => setState(() => _webHoverNavIndex = index),
                    onExit: (_) => setState(() => _webHoverNavIndex = null),
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _webActiveNavIndex = index);
                        switch (index) {
                          case 0:
                            break;
                          case 1:
                            Navigator.pushNamed(context, '/aichat');
                            break;
                          case 2:
                            Navigator.pushNamed(context, '/explore');
                            break;
                          case 3:
                            Navigator.pushNamed(context, '/settings');
                            break;
                        }
                      },
                      child: SizedBox(
                        width: segmentWidth,
                        child: Center(
                          child: _NavTextButton(label: labels[index], isActive: effectiveActive),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                left: underlineLeft,
                bottom: 0,
                child: Container(
                  width: indicatorWidth,
                  height: 2,
                  decoration: BoxDecoration(color: const Color(0xFFBC70FF), borderRadius: BorderRadius.circular(999)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWebHeroSection(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.18),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome back, @${widget.username}",
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Turn your ideas\ninto 3D in seconds.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Use AI prompts, scan objects, or browse ready-made 3D assets.",
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/aichat'),
                      icon: const Icon(Icons.bolt_rounded),
                      label: const Text("Open AI Studio"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8A4FFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/explore'),
                      icon: const Icon(Icons.storefront_rounded),
                      label: const Text("Marketplace"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4895EF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF282A36).withOpacity(0.85),
                  const Color(0xFF161620).withOpacity(0.95),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white.withOpacity(0.16)),
            ),
            child: const Text(
              "“A neon-lit sci-fi car parked in a rainy alley, cinematic lighting.”\n\nPrompt → 3D preview in under 60s.",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWebFeatureRow() {
    return Row(
      children: const [
        Expanded(
          child: _FeatureCard(
            icon: Icons.auto_awesome_rounded,
            title: "AI Text → 3D",
            subtitle: "Generate 3D assets using simple prompts.",
            badge: "AI Studio",
            gradient: [Color(0xFF8A4FFF), Color(0xFFBC70FF)],
          ),
        ),
        SizedBox(width: 18),
        Expanded(
          child: _FeatureCard(
            icon: Icons.storefront_rounded,
            title: "Marketplace",
            subtitle: "Explore ready-made 3D assets.",
            badge: "Market",
            gradient: [Color(0xFF4895EF), Color(0xFF4CC9F0)],
          ),
        ),
        SizedBox(width: 18),
        Expanded(
          child: _FeatureCard(
            icon: Icons.photo_camera_rounded,
            title: "Scan Objects",
            subtitle: "Create 3D models using photogrammetry.",
            badge: "Scan",
            gradient: [Color(0xFFF72585), Color(0xFFBC70FF)],
          ),
        ),
      ],
    );
  }

  Widget _buildWebTrendingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Trending in Marketplace",
          style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),

        /// ✅ UPDATED: Trending cards open popup
        Wrap(
          spacing: 14,
          runSpacing: 12,
          children: _trending
              .map(
                (m) => _TrendingCard(
                  name: m.name,
                  likes: m.likes,
                  tag: m.tagLabel,
                  onTap: () => setState(() => _activeMarketModel = m),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  // =========================
  // MOBILE
  // =========================
  Widget _buildMobileHome(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final double contentWidth = w > 480 ? 480.0 : w;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(_collapsed ? 50 : 70),
        child: Container(
          color: Colors.transparent,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + (_collapsed ? 0 : 6),
            left: 14,
            right: 14,
            bottom: 6,
          ),
          child: Row(
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: const Color(0xFFBC70FF), size: _collapsed ? 20 : 24),
                  const SizedBox(width: 6),
                  Text(
                    "R2V",
                    style: TextStyle(color: Colors.white, fontSize: _collapsed ? 17 : 20, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: Container(
                  width: _collapsed ? 32 : 38,
                  height: _collapsed ? 32 : 38,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.person, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(22, _collapsed ? 95 : 120, 22, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentWidth),
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMobileTabs(),
                  const SizedBox(height: 20),
                  if (_selectedTab == 0)
                    _isLoading ? const _HomeSkeleton() : _buildHomeTabMobile(context)
                  else if (_selectedTab == 1)
                    _isLoading ? const _AiSkeleton() : _buildAiTab(context)
                  else if (_selectedTab == 2)
                    _isLoading ? const _PhotogrammetrySkeleton() : _buildPhotogrammetryTab(context)
                  else
                    _isLoading ? const _MarketplaceSkeleton() : _buildMarketplaceTab(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileTabs() {
    final labels = ["Home", "AI Studio", "Photogrammetry", "Market"];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final bool selected = _selectedTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: selected
                      ? const LinearGradient(
                          colors: [Color(0xFFF72585), Color(0xFFBC70FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                ),
                child: Center(
                  child: Text(
                    labels[index],
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white.withOpacity(0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHomeTabMobile(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.22),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Welcome back, @${widget.username}", style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 6),
              const Text(
                "All your tools in one place.",
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              const Text(
                "Jump into AI Studio, start a new photogrammetry scan,\nor explore trending marketplace assets.",
                style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const _SectionHeader(title: "Use Cases", subtitle: "Pick a category"),
        const SizedBox(height: 200),
        NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n is ScrollStartNotification) _isUserDraggingUseCases = true;
            if (n is ScrollEndNotification) _isUserDraggingUseCases = false;
            return false;
          },
          child: UseCasesRow(
            items: _useCases,
            selectedIndex: _selectedUseCase,
            controller: _useCaseScrollController,
            onTap: _onUseCaseTap,
          ),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) {
            return SlideTransition(
              position: Tween<Offset>(begin: const Offset(-0.06, 0), end: Offset.zero).animate(anim),
              child: FadeTransition(opacity: anim, child: child),
            );
          },
          child: UseCaseDetailsSectionMobile(
            key: ValueKey(_useCaseDetails[_selectedUseCase]["id"]),
            data: _useCaseDetails[_selectedUseCase],
            onCta: () => Navigator.pushNamed(context, _useCaseDetails[_selectedUseCase]["ctaRoute"]),
          ),
        ),
        const SizedBox(height: 22),
      ],
    );
  }

  Widget _buildAiTab(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("AI Studio", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Text("Transform text prompts into detailed 3D concept art.",
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13.5)),
        const SizedBox(height: 18),
        ElevatedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/aichat'),
          icon: const Icon(Icons.bolt_rounded),
          label: const Text("Open AI Studio"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8A4FFF),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotogrammetryTab(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/photo_scan'),
          icon: const Icon(Icons.photo_camera_rounded),
          label: const Text("Start New Scan"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF72585),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: _scanHistory
              .map((scan) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ScanHistoryCard(title: scan["title"]!, status: scan["status"]!, time: scan["time"]!),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildMarketplaceTab(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/explore'),
          icon: const Icon(Icons.storefront_rounded),
          label: const Text("Open Marketplace"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4895EF),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
      ],
    );
  }
}

// =========================
// ✅ Particle Mesh Background (meshy.ai vibe)
// =========================
class MeshyParticleBackground extends StatelessWidget {
  const MeshyParticleBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MeshyBgCore();
  }
}

class _MeshyBgCore extends StatefulWidget {
  const _MeshyBgCore();

  @override
  State<_MeshyBgCore> createState() => _MeshyBgCoreState();
}

class _MeshyBgCoreState extends State<_MeshyBgCore> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final Random _rng = Random(42);

  Size _size = Size.zero;
  Offset _mouse = Offset.zero;
  bool _hasMouse = false;

  late List<_Particle> _ps;
  double _t = 0;

  @override
  void initState() {
    super.initState();
    _ps = <_Particle>[];
    _ticker = createTicker((elapsed) {
      _t = elapsed.inMilliseconds / 1000.0;
      if (!mounted) return;
      if (_size == Size.zero) return;

      // move particles
      final dt = 1 / 60;
      for (final p in _ps) {
        p.pos = p.pos + p.vel * dt;
        // bounce edges
        if (p.pos.dx < 0 || p.pos.dx > _size.width) p.vel = Offset(-p.vel.dx, p.vel.dy);
        if (p.pos.dy < 0 || p.pos.dy > _size.height) p.vel = Offset(p.vel.dx, -p.vel.dy);
        p.pos = Offset(p.pos.dx.clamp(0.0, _size.width), p.pos.dy.clamp(0.0, _size.height));
      }

      setState(() {});
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _ensureParticles(Size s) {
    if (s == Size.zero) return;

    // particle count depends on screen area (keep it smooth)
    final area = s.width * s.height;
    int target = (area / 18000).round(); // tune density
    target = target.clamp(35, 95);

    if (_ps.length == target) return;

    _ps = List.generate(target, (i) {
      final pos = Offset(_rng.nextDouble() * s.width, _rng.nextDouble() * s.height);
      final speed = 8 + _rng.nextDouble() * 18; // slow vibe
      final ang = _rng.nextDouble() * pi * 2;
      final vel = Offset(cos(ang), sin(ang)) * speed;
      final r = 1.2 + _rng.nextDouble() * 1.9;
      return _Particle(pos: pos, vel: vel, radius: r);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final s = Size(c.maxWidth, c.maxHeight);
      if (_size != s) {
        _size = s;
        _ensureParticles(s);
      }

      return MouseRegion(
        onHover: (e) {
          _hasMouse = true;
          _mouse = e.localPosition;
        },
        onExit: (_) {
          _hasMouse = false;
        },
        child: CustomPaint(
          painter: _MeshPainter(
            particles: _ps,
            time: _t,
            size: s,
            mouse: _mouse,
            hasMouse: _hasMouse,
          ),
        ),
      );
    });
  }
}

class _Particle {
  Offset pos;
  Offset vel;
  final double radius;

  _Particle({required this.pos, required this.vel, required this.radius});
}

class _MeshPainter extends CustomPainter {
  final List<_Particle> particles;
  final double time;
  final Size size;
  final Offset mouse;
  final bool hasMouse;

  _MeshPainter({
    required this.particles,
    required this.time,
    required this.size,
    required this.mouse,
    required this.hasMouse,
  });

  @override
  void paint(Canvas canvas, Size _) {
    // Base gradient background (dark + subtle color)
    final rect = Offset.zero & size;

    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF0F1118),
          const Color(0xFF141625),
          const Color(0xFF0B0D14),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, bg);

    // Soft glowing blobs (very subtle)
    void glowBlob(Offset c, double r, Color col, double a) {
      final p = Paint()
        ..color = col.withOpacity(a)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 90);
      canvas.drawCircle(c, r, p);
    }

    final center = Offset(size.width * 0.55, size.height * 0.35);
    final wobble = Offset(sin(time * 0.5) * 40, cos(time * 0.45) * 30);

    glowBlob(center + wobble, 280, const Color(0xFF8A4FFF), 0.18);
    glowBlob(
      Offset(size.width * 0.25, size.height * 0.70) +
          Offset(cos(time * 0.35) * 35, sin(time * 0.32) * 28),
      240,
      const Color(0xFF4895EF),
      0.14,
    );

    // Parallax (mouse)
    Offset parallax = Offset.zero;
    if (hasMouse) {
      final dx = (mouse.dx / max(1.0, size.width) - 0.5) * 18;
      final dy = (mouse.dy / max(1.0, size.height) - 0.5) * 18;
      parallax = Offset(dx, dy);
    }

    // Mesh connections
    final connectDist = min(size.width, size.height) * 0.15; // approx radius
    final connectDist2 = connectDist * connectDist;

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw lines
    for (int i = 0; i < particles.length; i++) {
      final a = particles[i];
      final ap = a.pos + parallax * 0.25;

      for (int j = i + 1; j < particles.length; j++) {
        final b = particles[j];
        final bp = b.pos + parallax * 0.25;

        final dx = ap.dx - bp.dx;
        final dy = ap.dy - bp.dy;
        final d2 = dx * dx + dy * dy;

        if (d2 < connectDist2) {
          final t = 1.0 - (sqrt(d2) / connectDist);
          linePaint.color = Colors.white.withOpacity(0.06 * t);
          canvas.drawLine(ap, bp, linePaint);
        }
      }
    }

    // Draw particles
    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      final pos = p.pos + parallax * 0.6;
      dotPaint.color = Colors.white.withOpacity(0.12);
      canvas.drawCircle(pos, p.radius, dotPaint);
    }

    // Vignette
    final vignette = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.15,
        colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
        stops: const [0.55, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, vignette);
  }

  @override
  bool shouldRepaint(covariant _MeshPainter oldDelegate) => true;
}

// =========================
// SECTION HEADER
// =========================
class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13)),
      ],
    );
  }
}

// =========================
// ✅ Use Cases Row (LEFT aligned; no centering)
// =========================
class UseCasesRow extends StatelessWidget {
  final List<Map<String, String>> items;
  final int selectedIndex;
  final ScrollController controller;
  final void Function(int index) onTap;

  const UseCasesRow({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isWide = c.maxWidth >= 900;
        final cardWidth = isWide ? 190.0 : 170.0;
        final spacing = isWide ? 16.0 : 12.0;
        final side = isWide ? 30.0 : 10.0;

        return SizedBox(
          height: isWide ? 178 : 165,
          child: ListView.separated(
            controller: controller,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: side),
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => SizedBox(width: spacing),
            itemBuilder: (context, i) {
              final m = items[i];
              final title = m["title"] ?? "";
              final asset = m["asset"];
              final active = i == selectedIndex;

              return _UseCaseTile(
                title: title,
                asset: asset,
                isActive: active,
                width: cardWidth,
                onTap: () => onTap(i),
              );
            },
          ),
        );
      },
    );
  }
}

class _UseCaseTile extends StatefulWidget {
  final String title;
  final String? asset;
  final bool isActive;
  final double width;
  final VoidCallback onTap;

  const _UseCaseTile({
    required this.title,
    required this.asset,
    required this.isActive,
    required this.width,
    required this.onTap,
  });

  @override
  State<_UseCaseTile> createState() => _UseCaseTileState();
}

class _UseCaseTileState extends State<_UseCaseTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final baseColors = _gradientFor(widget.title);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: widget.width,
          padding: const EdgeInsets.only(top: 8),
          transform: Matrix4.identity()..translate(0.0, (_hover || widget.isActive) ? -5.0 : 0.0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Align(
                alignment: Alignment.bottomCenter,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      height: 105,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: baseColors,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: widget.isActive ? Colors.white.withOpacity(0.28) : Colors.white.withOpacity(0.12),
                          width: widget.isActive ? 1.4 : 1,
                        ),
                        boxShadow: [
                          if (widget.isActive)
                            BoxShadow(
                              blurRadius: 28,
                              color: Colors.white.withOpacity(0.10),
                              offset: const Offset(0, 10),
                            ),
                          BoxShadow(
                            blurRadius: 18,
                            color: Colors.black.withOpacity((_hover || widget.isActive) ? 0.40 : 0.25),
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: widget.isActive ? Colors.white : Colors.white.withOpacity(0.92),
                              fontWeight: FontWeight.w800,
                              fontSize: 16.5,
                              height: 1.1,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 72,
                child: SizedBox(
                  height: 92,
                  child: (widget.asset == null)
                      ? const Icon(Icons.category, color: Colors.white70, size: 54)
                      : Image.asset(
                          widget.asset!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(Icons.category, color: Colors.white70, size: 54),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _gradientFor(String title) {
    final t = title.replaceAll('\n', ' ').toLowerCase();
    switch (t) {
      case 'film production':
        return [const Color(0xFF9CA3AF).withOpacity(.62), const Color(0xFF111827).withOpacity(.28)];
      case 'product design':
        return [const Color(0xFF38BDF8).withOpacity(.78), const Color(0xFF2563EB).withOpacity(.34)];
      case 'education':
        return [const Color(0xFFFDE68A).withOpacity(.70), const Color(0xFFB45309).withOpacity(.28)];
      case 'game development':
        return [const Color(0xFF22D3EE).withOpacity(.74), const Color(0xFF0EA5E9).withOpacity(.30)];
      case '3d printing':
        return [const Color(0xFFA3E635).withOpacity(.70), const Color(0xFF16A34A).withOpacity(.28)];
      case 'vr/ar':
        return [const Color(0xFFC084FC).withOpacity(.72), const Color(0xFFFB7185).withOpacity(.28)];
      case 'interior design':
        return [const Color(0xFFFCA5A5).withOpacity(.68), const Color(0xFFF59E0B).withOpacity(.24)];
      default:
        return [Colors.white.withOpacity(.18), Colors.white.withOpacity(.06)];
    }
  }
}

// =========================
// Use Case Details (WEB)
// =========================
class UseCaseDetailsSection extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onCta;

  const UseCaseDetailsSection({
    super.key,
    required this.data,
    required this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = (data["accent"] as Color?) ?? const Color(0xFFBC70FF);
    final bullets = (data["bullets"] as List?)?.cast<String>() ?? const <String>[];

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.22),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data["title"] ?? "",
                  style: const TextStyle(color: Colors.white, fontSize: 44, height: 1.05, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                Text(
                  data["subtitle"] ?? "",
                  style: TextStyle(color: Colors.white.withOpacity(0.78), fontSize: 15, height: 1.45),
                ),
                const SizedBox(height: 22),
                for (final b in bullets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.20),
                            shape: BoxShape.circle,
                            border: Border.all(color: accent.withOpacity(0.60), width: 1),
                          ),
                          child: Icon(Icons.check, size: 14, color: accent),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            b,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: onCta,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(data["cta"] ?? "Explore More"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent.withOpacity(0.18),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    side: BorderSide(color: accent.withOpacity(0.55), width: 1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 22),
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: 360,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  border: Border.all(color: Colors.white.withOpacity(0.10)),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        data["preview"] ?? "",
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Center(child: Icon(Icons.image_outlined, color: Colors.white.withOpacity(0.5), size: 48)),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                            colors: [Colors.black.withOpacity(0.30), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================
// Use Case Details (MOBILE)
// =========================
class UseCaseDetailsSectionMobile extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onCta;

  const UseCaseDetailsSectionMobile({
    super.key,
    required this.data,
    required this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = (data["accent"] as Color?) ?? const Color(0xFFBC70FF);
    final bullets = (data["bullets"] as List?)?.cast<String>() ?? const <String>[];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.20),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data["title"] ?? "",
            style: const TextStyle(color: Colors.white, fontSize: 26, height: 1.1, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            data["subtitle"] ?? "",
            style: TextStyle(color: Colors.white.withOpacity(0.78), fontSize: 13.5, height: 1.4),
          ),
          const SizedBox(height: 12),
          for (final b in bullets.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.18),
                      shape: BoxShape.circle,
                      border: Border.all(color: accent.withOpacity(0.55), width: 1),
                    ),
                    child: Icon(Icons.check, size: 12, color: accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      b,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      data["preview"] ?? "",
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Center(child: Icon(Icons.image_outlined, color: Colors.white.withOpacity(0.5), size: 42)),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                          colors: [Colors.black.withOpacity(0.28), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onCta,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(data["cta"] ?? "Explore More"),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent.withOpacity(0.18),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              side: BorderSide(color: accent.withOpacity(0.55), width: 1),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================
// Skeletons
// =========================
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _ShimmerBox(height: 130, radius: 26),
        SizedBox(height: 18),
        _ShimmerBox(height: 90, radius: 20),
        SizedBox(height: 10),
        _ShimmerBox(height: 90, radius: 20),
        SizedBox(height: 26),
      ],
    );
  }
}

class _AiSkeleton extends StatelessWidget {
  const _AiSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _ShimmerBox(height: 80, radius: 22),
        SizedBox(height: 14),
        _ShimmerBox(height: 120, radius: 22),
        SizedBox(height: 18),
        _ShimmerBox(height: 52, radius: 18),
      ],
    );
  }
}

class _PhotogrammetrySkeleton extends StatelessWidget {
  const _PhotogrammetrySkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _ShimmerBox(height: 150, radius: 26),
        SizedBox(height: 18),
        _ShimmerBox(height: 70, radius: 18),
        SizedBox(height: 10),
        _ShimmerBox(height: 70, radius: 18),
      ],
    );
  }
}

class _MarketplaceSkeleton extends StatelessWidget {
  const _MarketplaceSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _ShimmerBox(height: 140, radius: 26),
        SizedBox(height: 18),
        _ShimmerBox(height: 70, radius: 18),
        SizedBox(height: 10),
        _ShimmerBox(height: 70, radius: 18),
      ],
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double height;
  final double radius;

  const _ShimmerBox({required this.height, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(radius)),
    );
  }
}

// =========================
// Small UI pieces
// =========================
class _NavTextButton extends StatelessWidget {
  final String label;
  final bool isActive;

  const _NavTextButton({required this.label, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 120),
      style: TextStyle(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        fontSize: 13.5,
      ),
      child: Text(label),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final List<Color> gradient;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(badge, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}

/// ✅ UPDATED: clickable Trending card
class _TrendingCard extends StatelessWidget {
  final String name;
  final String likes;
  final String tag;
  final VoidCallback onTap;

  const _TrendingCard({
    required this.name,
    required this.likes,
    required this.tag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF191924),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: const Color(0xFF8A4FFF), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.extension_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(tag, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                ],
              ),
            ),
            Row(
              children: [
                const Icon(Icons.favorite_border_rounded, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Text(likes, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanHistoryCard extends StatelessWidget {
  final String title;
  final String status;
  final String time;

  const _ScanHistoryCard({required this.title, required this.status, required this.time});

  Color _statusColor() {
    switch (status) {
      case "Completed":
        return const Color(0xFF4CAF50);
      case "Processing":
        return const Color(0xFFFFC107);
      case "Failed":
        return const Color(0xFFF44336);
      default:
        return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sc = _statusColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF191924),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.photo_camera_rounded, color: Colors.white70, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(time, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: sc.withOpacity(0.16),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: sc.withOpacity(0.7), width: 0.8),
            ),
            child: Text(
              status,
              style: TextStyle(color: sc, fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// =========================
/// ✅ POPUP (same page) with ModelViewer + details
/// =========================
class _MarketModelPopup extends StatefulWidget {
  final MarketModel model;
  final VoidCallback onClose;

  const _MarketModelPopup({required this.model, required this.onClose});

  @override
  State<_MarketModelPopup> createState() => _MarketModelPopupState();
}

class _MarketModelPopupState extends State<_MarketModelPopup> {
  int tab = 0; // 0 geometry, 1 material
  bool shaded = true;
  bool pbr = true;
  String resolution = "2K";

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWeb = size.width >= 900;

    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withOpacity(0.60),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // do not close when clicking inside
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWeb ? 1160 : size.width - 18,
                maxHeight: isWeb ? 680 : size.height * 0.86,
              ),
              child: Material(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(28),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Column(
                    children: [
                      _header(),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: isWeb ? _webLayout() : _mobileLayout(),
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

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.90),
        border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.08))),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.06), shape: BoxShape.circle),
            child: Icon(Icons.person, color: Colors.black.withOpacity(0.55)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.model.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
          _circleBtn(Icons.link),
          const SizedBox(width: 8),
          _circleBtn(Icons.favorite_border),
          const SizedBox(width: 8),
          _circleBtn(Icons.close, onTap: widget.onClose),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: Colors.black.withOpacity(0.65)),
      ),
    );
  }

  Widget _webLayout() {
    return Row(
      children: [
        Expanded(flex: 6, child: _viewer()),
        const SizedBox(width: 14),
        Expanded(flex: 5, child: _rightPanel()),
      ],
    );
  }

  Widget _mobileLayout() {
    return Column(
      children: [
        Expanded(flex: 6, child: _viewer()),
        const SizedBox(height: 12),
        Expanded(flex: 5, child: _rightPanel()),
      ],
    );
  }

  Widget _viewer() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        color: Colors.black.withOpacity(0.06),
        child: ModelViewer(
          src: widget.model.glbAssetPath,
          poster: widget.model.posterAssetPath,
          autoRotate: true,
          cameraControls: true,
          ar: false,
          backgroundColor: Colors.transparent,
          shadowIntensity: 1,
        ),
      ),
    );
  }

  Widget _rightPanel() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        color: Colors.black.withOpacity(0.04),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _pillTab("Geometry", tab == 0, () => setState(() => tab = 0)),
                const SizedBox(width: 8),
                _pillTab("Material", tab == 1, () => setState(() => tab = 1)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                  ),
                  child: const Text(
                    "Gen-2",
                    style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
              ),
              child: Text(
                widget.model.description,
                style: TextStyle(color: Colors.black.withOpacity(0.72), height: 1.3),
              ),
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.model.tags.map(_tagChip).toList(),
            ),

            const SizedBox(height: 14),

            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  color: Colors.white.withOpacity(0.70),
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tab == 0 ? "Pack • Geometry" : "Pack • Material",
                          style: TextStyle(color: Colors.black.withOpacity(0.75), fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 12),
                        if (tab == 0) ...[
                          _checkRow("Base Model", true, (_) {}),
                          _checkRow("LOD", false, (_) {}),
                          const SizedBox(height: 10),
                          _formatRow(),
                        ] else ...[
                          _checkRow("Shaded", shaded, (v) => setState(() => shaded = v)),
                          _checkRow("PBR", pbr, (v) => setState(() => pbr = v)),
                          const SizedBox(height: 12),
                          Text(
                            "Resolution",
                            style: TextStyle(color: Colors.black.withOpacity(0.70), fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _resBtn("2K"),
                              const SizedBox(width: 8),
                              _resBtn("4K"),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.send),
                    label: const Text("Send"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black.withOpacity(0.75),
                      side: BorderSide(color: Colors.black.withOpacity(0.12)),
                      backgroundColor: Colors.white.withOpacity(0.86),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("Download", style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillTab(String text, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFEDE9FE) : Colors.white.withOpacity(0.70),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.black.withOpacity(0.08)),
        ),
        child: Text(
          text,
          style: TextStyle(color: Colors.black.withOpacity(0.75), fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _tagChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFFE),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Text(text, style: TextStyle(color: Colors.black.withOpacity(0.75), fontWeight: FontWeight.w800)),
    );
  }

  Widget _checkRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: (v) => onChanged(v ?? false), visualDensity: VisualDensity.compact),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: Colors.black.withOpacity(0.75), fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _formatRow() {
    final formats = [".obj", ".fbx", ".glb", ".usdz", ".stl"];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: formats
          .map(
            (f) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
              ),
              child: Text(
                f,
                style: TextStyle(color: Colors.black.withOpacity(0.75), fontWeight: FontWeight.w900),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _resBtn(String label) {
    final selected = resolution == label;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => resolution = label),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEDE9FE) : Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withOpacity(0.08)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(color: Colors.black.withOpacity(0.75), fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }
}
