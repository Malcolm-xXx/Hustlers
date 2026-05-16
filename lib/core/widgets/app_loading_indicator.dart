import 'package:flutter/material.dart';

import 'app_loader.dart';

/// Full-screen centered loading indicator.
/// For screen-level overlays use [LoadingOverlay] instead.
class AppLoadingIndicator extends StatelessWidget {
  final String? message;

  const AppLoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(child: AppLoader(message: message));
  }
}
