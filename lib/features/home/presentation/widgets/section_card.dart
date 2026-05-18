import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.backgroundColor = Colors.white,
    this.borderRadius = 10,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        // boxShadow: const [
        //   BoxShadow(
        //     color: Color(0x12000000),
        //     blurRadius: 18,
        //     offset: Offset(0, 10),
        //   ),
        // ],
      ),
      child: child,
    );
  }
}
