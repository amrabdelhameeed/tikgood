import 'dart:async';
import 'package:flutter/material.dart';

class TikTokLoadingAnimation extends StatefulWidget {
  const TikTokLoadingAnimation({super.key});

  @override
  State<TikTokLoadingAnimation> createState() => _TikTokLoadingAnimationState();
}

class _TikTokLoadingAnimationState extends State<TikTokLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  late Animation<double> _animationTranslateForward;
  late Animation<double> _animationGrowForward;
  late Animation<double> _animationReduceForward;

  late Animation<double> _animationTranslateBackward;
  late Animation<double> _animationGrowBackward;
  late Animation<double> _animationReduceBackward;

  late Animation<double> _translateInnerBall;
  late StreamController<bool> _innerBallStreamController;

  Sink<bool> get _innerBallSink => _innerBallStreamController.sink;
  Stream<bool> get _innerBallStream => _innerBallStreamController.stream;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 375),
    );

    // Forward path: Move 20 pixels to the right
    _animationTranslateForward = Tween<double>(begin: 0.0, end: 20.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationGrowForward = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.0, 0.50, curve: Curves.easeInOut)),
    );

    _animationReduceForward = Tween<double>(begin: 1.1, end: 1.0).animate(
      CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.50, 1.0, curve: Curves.easeInOut)),
    );

    // Backward path: Move from 20 pixels back to 0
    _animationTranslateBackward = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationGrowBackward = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.0, 0.50, curve: Curves.easeInOut)),
    );

    _animationReduceBackward = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.50, 1.0, curve: Curves.easeInOut)),
    );

    // The inner overlap ball movement
    _translateInnerBall = Tween<double>(begin: 15.0, end: -30.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _innerBallStreamController = StreamController<bool>.broadcast();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _innerBallStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The "Black Hole" ball that creates the overlap effect
    var innerBall = ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: AnimatedBuilder(
          animation: _translateInnerBall,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_translateInnerBall.value, 0.0),
              child: child,
            );
          },
          child: Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF252525),
            ),
          ),
        ),
      ),
    );

    return Center(
      child: Container(
        // Set the size of the "Stage" large enough so no clipping occurs
        width: 80,
        height: 40,
        alignment: Alignment.center,
        child: Flow(
          delegate: TikTokLoadingAnimationDelegate(
            animationController: _animationController,
            animationTranslateForward: _animationTranslateForward,
            animationGrowForward: _animationGrowForward,
            animationReduceForward: _animationReduceForward,
            animationTranslateBackward: _animationTranslateBackward,
            animationGrowBackward: _animationGrowBackward,
            animationReduceBackward: _animationReduceBackward,
            innerBallSink: _innerBallSink,
          ),
          children: [
            _buildBall(const Color(0xFF37ffec), innerBall, true),
            _buildBall(const Color(0xFFf21458), innerBall, false),
          ],
        ),
      ),
    );
  }

  Widget _buildBall(Color color, Widget innerBall, bool isFirst) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: StreamBuilder<bool>(
        initialData: true,
        stream: _innerBallStream,
        builder: (context, snapshot) {
          final isVisible =
              isFirst ? (snapshot.data ?? true) : !(snapshot.data ?? true);
          return Visibility(
            visible: isVisible,
            child: innerBall,
          );
        },
      ),
    );
  }
}

class TikTokLoadingAnimationDelegate extends FlowDelegate {
  final AnimationController animationController;
  final Animation<double> animationTranslateForward;
  final Animation<double> animationGrowForward;
  final Animation<double> animationReduceForward;
  final Animation<double> animationTranslateBackward;
  final Animation<double> animationGrowBackward;
  final Animation<double> animationReduceBackward;
  final Sink<bool> innerBallSink;

  int firstBallIndex = 0;
  int secondBallIndex = 1;
  bool showInnerBallOnForwardBall = true;

  TikTokLoadingAnimationDelegate({
    required this.animationController,
    required this.animationTranslateForward,
    required this.animationGrowForward,
    required this.animationReduceForward,
    required this.animationTranslateBackward,
    required this.animationGrowBackward,
    required this.animationReduceBackward,
    required this.innerBallSink,
  }) : super(repaint: animationController) {
    animationController.forward();
    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        animationController.reset();
        animationController.forward();
        _reverseChildren();
        _showInnerBallOnForwardBall();
      }
    });
  }

  void _reverseChildren() {
    var tmp = firstBallIndex;
    firstBallIndex = secondBallIndex;
    secondBallIndex = tmp;
  }

  void _showInnerBallOnForwardBall() {
    innerBallSink.add(showInnerBallOnForwardBall);
    showInnerBallOnForwardBall = !showInnerBallOnForwardBall;
  }

  @override
  void paintChildren(FlowPaintingContext context) {
    // STARTING POINT OFFSET: This centers the balls in the 80x40 box
    // Width of stage (80) - Max movement (20) - Ball width (20) / 2 = 20
    const double offsetX = 20.0;
    const double offsetY = 10.0;

    // Paint the ball moving backward (Left)
    context.paintChild(
      firstBallIndex,
      transform: Matrix4.identity()
        ..translate(offsetX + animationTranslateBackward.value, offsetY)
        ..scale(animationGrowBackward.value)
        ..scale(animationReduceBackward.value),
    );

    // Paint the ball moving forward (Right)
    context.paintChild(
      secondBallIndex,
      transform: Matrix4.identity()
        ..translate(offsetX + animationTranslateForward.value, offsetY)
        ..scale(animationGrowForward.value)
        ..scale(animationReduceForward.value),
    );
  }

  @override
  bool shouldRepaint(TikTokLoadingAnimationDelegate oldDelegate) => false;
}
