import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FullScreenGalleryScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String? title;

  const FullScreenGalleryScreen({
    Key? key,
    required this.images,
    this.initialIndex = 0,
    this.title,
  }) : super(key: key);

  @override
  State<FullScreenGalleryScreen> createState() => _FullScreenGalleryScreenState();
}

class _FullScreenGalleryScreenState extends State<FullScreenGalleryScreen> {
  late PageController _pageController;
  late ScrollController _thumbController;
  late int _currentIndex;
  final Map<int, TransformationController> _transformControllers = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.images.isEmpty ? 0 : widget.images.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
    _thumbController = ScrollController();
    
    // Set immersive black system UI
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToThumbnail(_currentIndex);
    });
  }

  @override
  void dispose() {
    for (var controller in _transformControllers.values) {
      controller.dispose();
    }
    _pageController.dispose();
    _thumbController.dispose();
    super.dispose();
  }

  TransformationController _getController(int index) {
    return _transformControllers.putIfAbsent(index, () => TransformationController());
  }

  void _handleDoubleTap(int index, TapDownDetails details) {
    final controller = _getController(index);
    if (controller.value != Matrix4.identity()) {
      // Reset zoom to 1.0
      controller.value = Matrix4.identity();
    } else {
      // Zoom 2.5x centered at tap position
      final position = details.localPosition;
      final zoomed = Matrix4.identity()
        ..translate(-position.dx * 1.5, -position.dy * 1.5)
        ..scale(2.5);
      controller.value = zoomed;
    }
    setState(() {});
  }

  void _scrollToThumbnail(int index) {
    if (!_thumbController.hasClients || widget.images.length <= 1) return;
    const itemWidth = 64.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final targetOffset = (index * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
    _thumbController.animateTo(
      targetOffset.clamp(0.0, _thumbController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    // Reset previous image zoom
    if (_transformControllers.containsKey(_currentIndex)) {
      _transformControllers[_currentIndex]!.value = Matrix4.identity();
    }
    setState(() {
      _currentIndex = index;
    });
    _scrollToThumbnail(index);
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.black,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Stack(
          children: [
            // 1. Center Image PageView with Double Tap & Pinch to Zoom
            PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: images.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final controller = _getController(index);
                final imageUrl = images[index];

                return GestureDetector(
                  onDoubleTapDown: (details) => _handleDoubleTap(index, details),
                  onDoubleTap: () {},
                  child: Center(
                    child: InteractiveViewer(
                      transformationController: controller,
                      minScale: 1.0,
                      maxScale: 4.5,
                      clipBehavior: Clip.none,
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF0075FF),
                            strokeWidth: 2.5,
                          ),
                        ),
                        errorWidget: (_, __, ___) => Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.broken_image_rounded, color: Colors.white54, size: 56),
                              SizedBox(height: 12),
                              Text('Unable to display image', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // 2. Top Bar: Close Button & Counter Badge
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Close (X) Button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),

                      // Image Counter Badge (e.g. 1 / 5)
                      if (images.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                          child: Text(
                            '${_currentIndex + 1} / ${images.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                      // Placeholder for balance
                      const SizedBox(width: 40, height: 40),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Bottom Thumbnail Strip (if multiple images)
            if (images.length > 1)
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 74,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.90),
                          Colors.black.withOpacity(0.0),
                        ],
                      ),
                    ),
                    child: Center(
                      child: ListView.builder(
                        controller: _thumbController,
                        scrollDirection: Axis.horizontal,
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          final isSelected = index == _currentIndex;
                          final thumbUrl = images[index];

                          return GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOutCubic,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: isSelected ? 56 : 48,
                              height: isSelected ? 56 : 48,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF0075FF) : Colors.white24,
                                  width: isSelected ? 2.5 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF0075FF).withOpacity(0.4),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: CachedNetworkImage(
                                imageUrl: thumbUrl,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                  color: const Color(0xFF1E293B),
                                  child: const Icon(Icons.broken_image, color: Colors.white38, size: 20),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
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
