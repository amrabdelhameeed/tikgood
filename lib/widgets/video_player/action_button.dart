// ── TikTokActionButton ────────────────────────────────────────────────────────
// No background container. Pure icon + label, exactly like TikTok.

import 'package:flutter/material.dart';

class TikTokActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool mirrorHorizontal;
  final double iconSize;
  final Color iconColor;

  const TikTokActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.mirrorHorizontal = false,
    this.iconSize = 34,
    this.iconColor = Colors.white,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform(
            alignment: Alignment.center,
            transform: mirrorHorizontal
                ? (Matrix4.identity()..scale(-1.0, 1.0))
                : Matrix4.identity(),
            child: Icon(
              icon,
              color: iconColor,
              size: iconSize,
              shadows: const [
                Shadow(
                    color: Colors.black38, blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1,
                shadows: [Shadow(color: Colors.black45, blurRadius: 6)],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
