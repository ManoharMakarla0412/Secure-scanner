import 'dart:ui';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:securescan/widgets/bottom_nav_shell.dart';
import 'package:securescan/themes.dart';
import 'package:securescan/widgets/banner_ad_widget.dart';
import 'package:securescan/services/language_service.dart';
import 'package:securescan/l10n/app_localizations.dart';
import 'package:securescan/features/onboarding.screens/initial_permissions_screen.dart';

class AppEntry extends StatelessWidget {
  const AppEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.copyright,
      theme: SecureScanTheme.lightTheme,
      darkTheme: SecureScanTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const OnboardingScreen(),
    );
  }
}

/// ------------------------------
/// Onboarding Section
/// ------------------------------

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
  }


  // Ad loading handled by BannerAdWidget

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage(int itemCount) {
    if (_currentPage < itemCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const InitialPermissionsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context)!;

    final onboardingData = [
      {
        'title': l10n.onboarding1Title,
        'subtitle': l10n.onboarding1Subtitle,
        'image': 'assets/1.png',
      },
      {
        'title': l10n.onboarding2Title,
        'subtitle': l10n.onboarding2Subtitle,
        'image': 'assets/2.png',
      },
      {
        'title': l10n.onboarding3Title,
        'subtitle': l10n.onboarding3Subtitle,
        'image': 'assets/3.png',
      },
      {
        'title': l10n.selectLanguage,
        'subtitle': l10n.selectLanguageSubtitle,
        'image': '',
      },
    ];

    const adHeight = 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // MAIN ONBOARDING CONTENT
            Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (value) {
                      setState(() => _currentPage = value);
                    },
                    itemCount: onboardingData.length,
                    itemBuilder: (context, index) {
                      final data = onboardingData[index];
                      final isLastPage = index == onboardingData.length - 1;

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Graphic Placeholder or Language Selection
                          if (!isLastPage)
                            Container(
                              width: double.infinity,
                              height: 400,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: Image.asset(data['image']!).image,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            )
                          else
                            _buildLanguageOptions(context),

                          // Apply left padding ONLY to text section
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['title']!,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF000000),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                Text(
                                  data['subtitle']!,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.black54,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // leave space equal to bottom banner + adHeight so content won't be hidden
                SizedBox(height: 120 + adHeight),
              ],
            ),

            // 🌐 Language Selection Dropdown - Positioned at top right
            // Removed the top-right language selection dropdown

            // 🔵 Bottom Banner + Controls — positioned ABOVE the ad
            Positioned(
              left: 0,
              right: 0,
              bottom: adHeight, // sits above the ad
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF006EFF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 30.0, vertical: 22),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Page Indicator Dots
                    Row(
                      children: List.generate(
                        onboardingData.length,
                            (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          width: _currentPage == index ? 18 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(
                                _currentPage == index ? 1 : 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),

                    // Next / Get Started Button
                    InkWell(
                      onTap: () => _nextPage(onboardingData.length),
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _currentPage == onboardingData.length - 1
                                  ? l10n.getStarted
                                  : l10n.next,
                              style: textTheme.labelLarge?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: SecureScanTheme.accentBlue,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: SecureScanTheme.accentBlue,
                              size: 22,
                            ),
                          ],
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
      bottomNavigationBar: const SafeArea(child: BannerAdWidget()),
    );
  }

  Widget _buildLanguageOptions(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 400,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: supportedLanguages.map((lang) {
          return ValueListenableBuilder<Locale>(
            valueListenable: LanguageController.instance.localeNotifier,
            builder: (context, locale, _) {
              final isSelected = locale.languageCode == lang.code;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: InkWell(
                  onTap: () {
                    LanguageController.instance.setLanguage(lang.code);
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF006EFF).withOpacity(0.1)
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF006EFF) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(lang.flag, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? const Color(0xFF006EFF)
                                      : Colors.black87,
                                ),
                              ),
                              Text(
                                lang.nativeName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isSelected
                                      ? const Color(0xFF006EFF).withOpacity(0.7)
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: Color(0xFF006EFF)),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}