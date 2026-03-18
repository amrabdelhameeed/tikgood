import 'package:flutter/material.dart';
import '../../features/home/presentation/bloc/app_state.dart';

class TopNavigation extends StatelessWidget {
  final AppState state;
  final VoidCallback onLivePressed;
  final VoidCallback onFollowingTabPressed;
  final VoidCallback onForYouTabPressed;
  final VoidCallback onFullscreenPressed;

  const TopNavigation({
    required this.state,
    required this.onLivePressed,
    required this.onFollowingTabPressed,
    required this.onForYouTabPressed,
    required this.onFullscreenPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Hide top navigation in PIP mode
    if (state.isInPipMode) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        left: 12,
        right: 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.4),
            Colors.transparent,
          ],
        ),
      ),
      child: SizedBox(
        height: 50,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // TikTok "LIVE" Icon
            GestureDetector(
              onTap: onLivePressed,
              child: const Icon(Icons.live_tv_rounded,
                  color: Colors.white, size: 24),
            ),

            // Tab Center
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTabButton('Following', 0),
                const SizedBox(width: 20), // Spacing between tabs
                _buildTabButton('For You', 1),
              ],
            ),

            // Fullscreen Icon
            GestureDetector(
              onTap: onFullscreenPressed,
              child:
                  const Icon(Icons.fullscreen, color: Colors.white, size: 30),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isActive = (index == 0 && state.isFollowingTab) ||
        (index == 1 && !state.isFollowingTab);

    return GestureDetector(
      onTap: index == 0 ? onFollowingTabPressed : onForYouTabPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white60,
              fontSize: 17,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              shadows: const [
                Shadow(
                    offset: Offset(0, 1), blurRadius: 2, color: Colors.black26),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Active Indicator (The TikTok Red Dot or Line)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isActive ? 18 : 0,
            height: 2.5,
            decoration: BoxDecoration(
              color: Colors.white, // Or Color(0xFFFE2C55) for the red vibe
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
