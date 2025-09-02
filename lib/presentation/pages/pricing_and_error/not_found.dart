import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nepika/core/widgets/back_button.dart';
import 'package:nepika/core/config/constants/routes.dart';

class NotFound extends StatelessWidget {
  const NotFound({super.key});

  void _navigateTo(BuildContext context, String route) {
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              CustomBackButton(),

              // Expanded(
              //   child: Column(
              //     children: [

              //     ],
              //   ),
              // ),
              Spacer(),
              Center(
                child: Image.asset(
                  'assets/images/404_not_found_image.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 50),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Home Link
                  GestureDetector(
                    onTap: () => _navigateTo(context, AppRoutes.dashboardHome),
                    child: Text(
                      'Home',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),

                  // Vertical Divider
                  Container(
                    width: 1,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                    color: Theme.of(context).dividerColor,
                  ),

                  // Scan Link
                  GestureDetector(
                    onTap: () => _navigateTo(context, AppRoutes.cameraScanGuidence),
                    child: Text(
                      'Scan',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                ],
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
