import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/app_cubit.dart';
import '../core/constants/app_assets.dart';
import '../core/localization/app_localizations.dart';

class WalkthroughScreen extends StatefulWidget {
  const WalkthroughScreen({Key? key}) : super(key: key);

  @override
  State<WalkthroughScreen> createState() => _WalkthroughScreenState();
}

class _WalkthroughScreenState extends State<WalkthroughScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<_WalkPageData> _buildPages(AppLocalizations l) => [
        _WalkPageData(
          title: l.walkthroughTitleOne,
          description: l.walkthroughDescOne,
          imagePath: AppAssets.walkthroughImageOne,
          backgroundColor: const Color(0xFFF7F8FA),
        ),
        _WalkPageData(
          title: l.walkthroughTitleTwo,
          description: l.walkthroughDescTwo,
          imagePath: AppAssets.walkthroughImageTwo,
          backgroundColor: const Color(0xFFF7F8FA),
        ),
        _WalkPageData(
          title: l.walkthroughTitleThree,
          description: l.walkthroughDescThree,
          imagePath: AppAssets.walkthroughImageThree,
          backgroundColor: const Color(0xFFF7F8FA),
        ),
      ];

  void _onNext() {
    final pages = _buildPages(AppLocalizations.of(context));
    if (_currentPage < pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      context.read<AppCubit>().showAuth();
    }
  }

  void _onSkip() {
    context.read<AppCubit>().showAuth();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pages = _buildPages(l);
    final currentIndex = _currentPage.clamp(0, pages.length - 1);
    final currentPage = pages[currentIndex];
    return Scaffold(
      backgroundColor: currentPage.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: pages.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                final page = pages[index];
                return _buildPage(page);
              },
            ),

            Positioned(
              top: 20,
              right: 20,
              child: TextButton(
                onPressed: _onSkip,
                child: Text(
                  l.skip,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 40,
              left: 30,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                      (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 10,
                    width: _currentPage == index ? 22 : 10,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? const Color(0xFF2E3A59)
                          : const Color(0xFFD0D3D8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 20,
              right: 25,
              child: GestureDetector(
                onTap: _onNext,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(2, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_WalkPageData page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            page.imagePath,
            width: 300,
            height: 340,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 50),

          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              page.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF707070),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalkPageData {
  final String title;
  final String description;
  final String imagePath;
  final Color backgroundColor;

  _WalkPageData({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.backgroundColor,
  });
}
