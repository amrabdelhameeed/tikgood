import 'package:flutter/material.dart';

class TikTokHeartButton extends StatefulWidget {
  final IconData icon;
  final double iconSize;
  final bool liked;
  final ValueChanged<bool>? onDoubleTap;

  const TikTokHeartButton({
    super.key,
    required this.icon,
    this.iconSize = 30,
    this.liked = false,
    this.onDoubleTap,
  });

  @override
  State<TikTokHeartButton> createState() => TikTokHeartButtonState();
}

class TikTokHeartButtonState extends State<TikTokHeartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  bool _liked = false;

  @override
  void initState() {
    super.initState();
    _liked = widget.liked;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _scaleAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.5),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.5, end: 1.0),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(TikTokHeartButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.liked != oldWidget.liked) {
      setState(() {
        _liked = widget.liked;
      });
      if (widget.liked) {
        _controller.forward(from: 0);
      }
    }
  }

  void onTap() {
    setState(() {
      _liked = !_liked;
    });
    widget.onDoubleTap?.call(_liked);
    _controller.forward(from: 0);
  }

  /// Triggers the like animation from external source (e.g., double-tap on video)
  void triggerLike() {
    if (!_liked) {
      setState(() {
        _liked = true;
      });
      widget.onDoubleTap?.call(true);
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Icon(
          widget.icon,
          size: widget.iconSize,
          color: _liked ? Colors.red : Colors.white,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
