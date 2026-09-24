import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/haptics.dart';
import '../../core/app_assets.dart';
import '../../core/audio_manager.dart';

class BasePopupDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final double width;
  final double height;
  final bool useAlternatePanel;

  const BasePopupDialog({
    super.key,
    required this.title,
    required this.content,
    this.width = 560,
    this.height = 340,
    this.useAlternatePanel = true,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    double width = 560,
    double height = 340,
    bool useAlternatePanel = true,
  }) {
    Haptics.light();
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (context, anim1, anim2) {
        return BasePopupDialog(
          title: title,
          content: content,
          width: width,
          height: height,
          useAlternatePanel: useAlternatePanel,
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 6 * anim1.value,
            sigmaY: 6 * anim1.value,
          ),
          child: ScaleTransition(
            scale: curve,
            child: FadeTransition(opacity: anim1, child: child),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keep the popup full size when a keyboard opens over it (e.g. the name
    // editor); resizing it caused bottom overflow in landscape.
    return MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: _buildDialog(context),
    );
  }

  Widget _buildDialog(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // 1. Ornate Asian Casino Popup Frame
            Positioned.fill(
              child: Image.asset(
                useAlternatePanel
                    ? AppAssets.panelPopup2
                    : AppAssets.panelPopup,
                fit: BoxFit.fill,
              ),
            ),

            // 2. Crown Floating Title Plaque (Crowning the top arch)
            Positioned(
              top: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF6A0D25),
                      Color(0xFF8E1438),
                      Color(0xFF6A0D25),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFFD700),
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                    const BoxShadow(
                      color: Color(0x66FFD700),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFFFF9C4),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        offset: Offset(1, 2),
                        blurRadius: 3,
                      ),
                      Shadow(
                        color: Color(0xFF4A000E),
                        offset: Offset(-1, -1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Inner Usable Content Area (Guaranteed within purple interior)
            Positioned(
              top: 48,
              bottom: 44, // Safe clearance from bottom gold border (44dp)
              left: 54, // Safe clearance from left gold border (54dp)
              right: 54, // Safe clearance from right gold border (54dp)
              child: content,
            ),

            // 4. Ornate Red/Gold Close Button (Sitting on the top-right corner)
            Positioned(
              top: -6,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  Haptics.selection();
                  AudioManager.instance.playSelectClick();
                  Navigator.of(context).pop();
                },
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Image.asset(AppAssets.btnClose, fit: BoxFit.contain),
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
