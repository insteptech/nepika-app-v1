import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class NotFound extends StatelessWidget {
  const NotFound({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Container(
            color: Colors.white,
            child: Image.asset(
              'assets/images/404_not_found_image.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
