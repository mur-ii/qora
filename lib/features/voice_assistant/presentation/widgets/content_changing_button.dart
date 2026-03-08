import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

enum ContentChangingButtonState { connecting, connected, notConnect }

class ContentChangingButton extends StatelessWidget {
  final ContentChangingButtonState state;
  final VoidCallback? onPressed;

  const ContentChangingButton({super.key, required this.state, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _getBackgroundColor(),
        foregroundColor: AppColors.surfaceWhite,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 4,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state == ContentChangingButtonState.connecting)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.surfaceWhite,
                ),
              ),
            )
          else
            Icon(_getIcon(), size: 24),
          const SizedBox(width: 12),
          Text(
            _getText(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (state) {
      case ContentChangingButtonState.connecting:
        return AppColors.primaryOrange;
      case ContentChangingButtonState.connected:
        return AppColors.error;
      case ContentChangingButtonState.notConnect:
        return AppColors.brandGreen;
    }
  }

  IconData _getIcon() {
    switch (state) {
      case ContentChangingButtonState.connecting:
        return Icons.sync;
      case ContentChangingButtonState.connected:
        return Icons.stop;
      case ContentChangingButtonState.notConnect:
        return Icons.mic;
    }
  }

  String _getText() {
    switch (state) {
      case ContentChangingButtonState.connecting:
        return 'Connecting...';
      case ContentChangingButtonState.connected:
        return 'Stop';
      case ContentChangingButtonState.notConnect:
        return 'Start Voice Assistant';
    }
  }
}
