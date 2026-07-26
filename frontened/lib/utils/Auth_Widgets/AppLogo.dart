
import 'package:flutter/material.dart';


class AppLogo extends StatelessWidget {
  final double width;

  const AppLogo({super.key, this.width = 170});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/images/logo.jpeg',
        width: width,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}