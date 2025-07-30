
import 'package:flutter/material.dart';
import 'package:nepika/core/constants/theme.dart';

class GreetingSection extends StatelessWidget {
  final Map<String, dynamic> user;
  const GreetingSection({required this.user});

  @override
  Widget build(BuildContext context) {
    final String userName = user['name']?.toString().trim() ?? '';

    final String greeting = user['greeting'] ?? '';

    final String? avatarUrl = user['avatarUrl'];
    print(user);
    final ImageProvider avatarImage =
        (avatarUrl != null && avatarUrl.trim().isNotEmpty)
        ? NetworkImage(avatarUrl)
        : const AssetImage('assets/icons/user_icon.png');

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hey, ${userName.isNotEmpty ? userName : 'User'}',
              style: Theme.of(context).textTheme.displaySmall,
            ),

            Text(
              greeting.isNotEmpty ? greeting : 'welcome back!',
              style: Theme.of(context).textTheme.bodyLarge!.secondary(context),

            ),
          ],
        ),
        const Spacer(),
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey[200],
          backgroundImage: avatarImage,
        ),
      ],
    );
  }
}

