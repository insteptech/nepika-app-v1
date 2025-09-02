import 'package:flutter/material.dart';

class SomethingWentWrong extends StatefulWidget {
  const SomethingWentWrong({super.key});

  @override
  State<SomethingWentWrong> createState() => _SomethingWentWrongState();
}

class _SomethingWentWrongState extends State<SomethingWentWrong> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          SizedBox(height: 10),
          Text(
            "Something went wrong",
            style: TextStyle(fontSize: 16, color: Colors.red),
          ),
          SizedBox(height: 10),
          Text(
            "Unable to load the data. Please try again later.",
            style: TextStyle(fontSize: 14, color: Colors.red.withValues(alpha:  0.7)),
          ),
        ],
      ),
    );
  }
}
