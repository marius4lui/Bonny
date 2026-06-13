import 'package:flutter/material.dart';

class ReducedMotionWrapper extends StatelessWidget {
  const ReducedMotionWrapper({
    super.key,
    required this.child,
    this.reducedMotionChild,
  });

  final Widget child;
  final Widget? reducedMotionChild;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return reducedMotionChild ?? child;
    }
    return child;
  }
}
