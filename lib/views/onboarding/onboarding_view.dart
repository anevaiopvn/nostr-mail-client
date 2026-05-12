import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:introduction_screen/introduction_screen.dart';

import '../../app/routes/app_routes.dart';
import '../../services/storage_service.dart';

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  Future<void> _onDone() async {
    final storage = Get.find<StorageService>();
    await storage.saveSetting('has_seen_onboarding', true);
    Get.offAllNamed(AppRoutes.login);
  }

  PageDecoration _getPageDecoration(BuildContext context) {
    return PageDecoration(
      titleTextStyle: TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.primary,
      ),
      bodyTextStyle: const TextStyle(fontSize: 18.0),
      bodyPadding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Theme.of(context).colorScheme.surface,
      imagePadding: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: IntroductionScreen(
          pages: [
            PageViewModel(
              title: "Welcome to Nmail",
              body:
                  "Discover a decentralized email experience that puts you in control. A new way to communicate, centered around you.",
              image: Center(
                child: Image.asset(
                  'icons/original_transparent_3x.png',
                  width: 100,
                  height: 100,
                ),
              ),
              decoration: _getPageDecoration(context),
            ),
            PageViewModel(
              title: "A Network Without Masters",
              body:
                  "Your messages flow through a global network of independent servers. No single company owns your inbox.",
              image: Center(
                child: Icon(
                  Icons.hub_outlined,
                  size: 100,
                  color: colorScheme.primary,
                ),
              ),
              decoration: _getPageDecoration(context),
            ),
            PageViewModel(
              title: "Freedom of Choice",
              body:
                  "You are never locked into a single provider. Switch bridges or relays at any time without ever losing your identity or contacts.",
              image: Center(
                child: Icon(
                  Icons.swap_horiz_rounded,
                  size: 100,
                  color: colorScheme.primary,
                ),
              ),
              decoration: _getPageDecoration(context),
            ),
            PageViewModel(
              title: "One Identity for Everything",
              body:
                  "Use your account to send emails, follow profiles, or use other apps. It's one permanent identity that works across many different applications.",
              image: Center(
                child: Icon(
                  Icons.apps_rounded,
                  size: 100,
                  color: colorScheme.primary,
                ),
              ),
              decoration: _getPageDecoration(context),
            ),
            PageViewModel(
              title: "Built for the Future",
              body:
                  "Benefit from a modern architecture designed for privacy. Nmail helps you transition smoothly to a more secure and resilient way of communicating.",
              image: Center(
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 100,
                  color: colorScheme.primary,
                ),
              ),
              decoration: _getPageDecoration(context),
            ),
          ],
          onDone: _onDone,
          onSkip: _onDone,
          showSkipButton: true,
          skip: const Text(
            'Skip',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          next: const Icon(Icons.arrow_forward),
          nextSemantic: 'Next',
          done: const Text(
            'Done',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          dotsDecorator: DotsDecorator(
            activeSize: const Size(22.0, 10.0),
            activeColor: colorScheme.primary,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
            activeShape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(25.0)),
            ),
          ),
        ),
      ),
    );
  }
}
