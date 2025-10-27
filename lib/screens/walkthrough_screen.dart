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
          backgroundColor: const Color(0xFFF4F6FB),
        ),
        _WalkPageData(
          title: l.walkthroughTitleTwo,
          description: l.walkthroughDescTwo,
          imagePath: AppAssets.walkthroughImageTwo,
          backgroundColor: const Color(0xFFF4F6FB),
        ),
        _WalkPageData(
          title: l.walkthroughTitleThree,
          description: l.walkthroughDescThree,
          imagePath: AppAssets.walkthroughImageThree,
          backgroundColor: const Color(0xFFF4F6FB),
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
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.padding.bottom;
    final pages = _buildPages(l);
    final currentIndex = _currentPage.clamp(0, pages.length - 1);
    final currentPage = pages[currentIndex];
    return Scaffold(
      backgroundColor: currentPage.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(
                bottom: 120 + bottomInset,
              ),
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return _buildPage(page);
                },
                physics: const BouncingScrollPhysics(),
              ),
            ),

            Positioned(
              top: 16,
              right: 16,
              child: TextButton(
                onPressed: _onSkip,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF8E9BB4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,

                  ),
                ),
                child: Text(l.skip,style: TextStyle(color: Colors.black,fontWeight: FontWeight.w400,fontSize: 16),),
              ),
            ),

            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _onNext,
                child: Padding(
                  padding: EdgeInsets.only(
                    right: 4,
                    bottom: bottomInset,
                  ),
                  child: Image.asset(
                    AppAssets.walkthroughNextArrow,
                    width: 90,
                  ),
                ),
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 44 + bottomInset,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: _currentPage == index ? 12 : 10,
                          width: _currentPage == index ? 12 : 10,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? const Color(0xFF2F80ED)
                                : const Color(0xFFD6DEFF),
                            shape: BoxShape.circle,
                            boxShadow: _currentPage == index
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF2F80ED).withOpacity(0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_WalkPageData page) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageHeight = (constraints.maxHeight * 0.55).clamp(260.0, 360.0);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: imageHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFE7EEFF),
                      Color(0xFFF6F8FF),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1C60E0).withOpacity(0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Image.asset(
                    page.imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 44),
              Text(
                page.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2E55),
                  height: 1.32,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                page.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6F7A93),
                  height: 1.6,
                ),
              ),
            ],
          ),
        );
      },
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
