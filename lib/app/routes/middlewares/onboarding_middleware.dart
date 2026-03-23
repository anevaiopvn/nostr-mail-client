import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../services/storage_service.dart';
import '../app_routes.dart';

class OnboardingMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // If user is already on onboarding, don't redirect
    if (route == AppRoutes.onboarding) return null;

    final storage = Get.find<StorageService>();
    if (!storage.hasSeenOnboarding) {
      return const RouteSettings(name: AppRoutes.onboarding);
    }
    return null;
  }
}
