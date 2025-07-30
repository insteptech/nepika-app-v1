// import 'package:flutter/material.dart';

// class ColorPalette extends StatelessWidget {
//   const ColorPalette({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppTheme.backgroundColor,
//       appBar: AppBar(
//         backgroundColor: AppTheme.backgroundColor,
//         title: const Text('Color Palette'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: GridView.count(
//           crossAxisCount: 2,
//           crossAxisSpacing: 16,
//           mainAxisSpacing: 16,
//           children: [
//             _buildColorCard('Primary', AppTheme.primaryColor),
//             _buildColorCard('Primary Light', AppTheme.primaryLight),
//             _buildColorCard('Primary Dark', AppTheme.primaryDark),
//             _buildColorCard('Secondary', AppTheme.secondaryColor),
//             _buildColorCard('Background', AppTheme.backgroundColor),
//             _buildColorCard('Surface', AppTheme.surfaceColor),
//             _buildColorCard('Error', AppTheme.errorColor),
//             _buildColorCard('Success', AppTheme.successColor),
//             _buildColorCard('Warning', AppTheme.warningColor),
//             _buildColorCard('Info', AppTheme.infoColor),
//             _buildColorCard('Text Primary', AppTheme.textPrimary),
//             _buildColorCard('Text Secondary', AppTheme.textSecondary),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildColorCard(String name, Color color) {
//     return Container(
//       decoration: BoxDecoration(
//         color: color,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey[300]!),
//       ),
//       child: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               name,
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: _getContrastColor(color),
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
//               style: TextStyle(
//                 fontSize: 12,
//                 color: _getContrastColor(color),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Color _getContrastColor(Color background) {
//     // Calculate brightness
//     double brightness = (background.red * 299 + background.green * 587 + background.blue * 114) / 1000;
//     return brightness > 128 ? Colors.black : Colors.white;
//   }
// }