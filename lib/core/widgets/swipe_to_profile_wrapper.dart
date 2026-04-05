import 'package:flutter/material.dart';

class SwipeToProfileWrapper extends StatefulWidget {
  final Widget child;
  final WidgetBuilder overlayBuilder;

  const SwipeToProfileWrapper({
    required this.child,
    required this.overlayBuilder,
    super.key,
  });

  @override
  State<SwipeToProfileWrapper> createState() => _SwipeToProfileWrapperState();
}

class _SwipeToProfileWrapperState extends State<SwipeToProfileWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _slideAnim;

  OverlayEntry? _overlayEntry;
  double _dragProgress = 0.0;
  bool _isOpen = false;

  // Requirements Constants
  static const double _openThreshold = 0.20;
  static const double _closeThreshold = 0.40;
  static const double _velocityThreshold = 300.0;
  static const int _animDuration = 220;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _animDuration),
    );
    _slideAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.addListener(_updateOverlay);
  }

  @override
  void dispose() {
    _removeOverlay();
    _ctrl.removeListener(_updateOverlay);
    _ctrl.dispose();
    super.dispose();
  }

  void _updateOverlay() {
    _overlayEntry?.markNeedsBuild();
  }

  void _insertOverlay() {
    if (_overlayEntry != null) return;
    _overlayEntry = OverlayEntry(builder: _buildOverlayContent);
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildOverlayContent(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final slideValue = _slideAnim.value;

    // We animate the width from 92% to 100% as the slide completes
    // This removes the "left space" when the page is fully open.
    final currentWidth = screenW * (0.92 + (0.08 * slideValue));

    return Stack(
      fit: StackFit.expand,
      children: [
        // Scrim
        IgnorePointer(
          ignoring: slideValue == 0,
          child: GestureDetector(
            onTap: _close,
            child: Opacity(
              opacity: (slideValue * 0.45).clamp(0.0, 0.45),
              child: const ColoredBox(color: Colors.black),
            ),
          ),
        ),

        // Sliding Panel
        Transform.translate(
          // Offset logic: At slideValue 1.0, offset is 0 (Full Screen)
          // At slideValue 0.1, it peeks from the right.
          offset: Offset(screenW * (1.0 - slideValue), 0),
          child: GestureDetector(
            onTap: () {},
            onHorizontalDragUpdate: (details) {
              if (details.delta.dx > 0) {
                setState(() {
                  // Use screenW here for consistent closing drag
                  _dragProgress = (_dragProgress - details.delta.dx / screenW)
                      .clamp(0.0, 1.0);
                });
                _ctrl.value = _dragProgress;
                _updateOverlay();
              }
            },
            onHorizontalDragEnd: _onHorizontalDragEnd,
            child: SizedBox(
              width: currentWidth,
              child: Material(
                elevation: 16,
                color: Colors.black,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    widget.overlayBuilder(context),
                    // Back button
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 8,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 20),
                        onPressed: _close,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    final delta = -details.delta.dx;
    final screenW = MediaQuery.of(context).size.width;

    if (delta > 0 && _overlayEntry == null) _insertOverlay();

    setState(() {
      _dragProgress = (_dragProgress + delta / screenW).clamp(0.0, 1.0);
    });
    _ctrl.value = _dragProgress;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = -details.velocity.pixelsPerSecond.dx;

    if (!_isOpen) {
      if (_dragProgress > _openThreshold || velocity > _velocityThreshold) {
        _isOpen = true;
        _ctrl.animateTo(1.0, curve: Curves.easeOutCubic);
      } else {
        _ctrl.animateTo(0.0, curve: Curves.easeInCubic).then((_) {
          _removeOverlay();
          setState(() => _dragProgress = 0.0);
        });
      }
    } else {
      if (_dragProgress < _closeThreshold || velocity < -_velocityThreshold) {
        _isOpen = false;
        _ctrl.animateTo(0.0, curve: Curves.easeOutCubic).then((_) {
          _removeOverlay();
          setState(() => _dragProgress = 0.0);
        });
      } else {
        _ctrl.animateTo(1.0, curve: Curves.easeInCubic);
      }
    }
  }

  void _close() {
    _isOpen = false;
    _ctrl.animateTo(0.0, curve: Curves.easeOutCubic).then((_) {
      _removeOverlay();
      setState(() => _dragProgress = 0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: AnimatedBuilder(
        animation: _slideAnim,
        builder: (_, child) => Transform.translate(
          // 25% Parallax Shift
          offset: Offset(
              -MediaQuery.of(context).size.width * 0.25 * _slideAnim.value, 0),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
