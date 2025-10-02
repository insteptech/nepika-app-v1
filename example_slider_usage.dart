import 'package:flutter/material.dart';
import 'lib/features/onboarding/widgets/slider_button.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Slider Button Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SliderButtonDemo(),
    );
  }
}

class SliderButtonDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Slider Button Examples'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Basic slider button matching Figma design
            SliderButton(
              text: "Slide to continue",
              onSlideComplete: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Slider completed!')),
                );
              },
            ),
            
            SizedBox(height: 30),
            
            // Custom styled slider button
            SliderButton(
              text: "Slide to submit",
              width: 300,
              height: 50,
              backgroundColor: Colors.green,
              textColor: Colors.white,
              sliderColor: Colors.white,
              icon: Icons.check,
              onSlideComplete: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Form submitted!')),
                );
              },
            ),
            
            SizedBox(height: 30),
            
            // Another variant
            SliderButton(
              text: "Slide to unlock",
              width: 280,
              backgroundColor: Colors.purple,
              icon: Icons.lock_open,
              onSlideComplete: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Unlocked!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}