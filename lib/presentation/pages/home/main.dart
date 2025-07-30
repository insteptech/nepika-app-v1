// import 'package:flutter/material.dart';
// import 'package:nepika/core/constants/routes.dart';
// import 'package:nepika/presentation/pages/dashboard/add_routine.dart';
// import 'package:nepika/presentation/pages/dashboard/dashboard_page.dart';
// import 'package:nepika/presentation/pages/dashboard/edit_routine.dart';
// import 'package:nepika/presentation/pages/dashboard/daily_routine_page.dart';
// import 'package:nepika/presentation/pages/first_scan/camera_scan_screen.dart';
// import 'widgets/dashboard_navbar.dart';

// class Dashboard extends StatefulWidget {
//   const Dashboard({super.key});

//   @override
//   State<Dashboard> createState() => _DashboardState();
// }

// class _DashboardState extends State<Dashboard> {
//   final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
//   int _selectedIndex = 0;

//   // Match tabs to route names
//   final List<String> _routes = [
//     AppRoutes.dashboardHome,
//     AppRoutes.dashboardExplore,
//     AppRoutes.dashboardScan,
//     AppRoutes.dashboardProfile,
//     AppRoutes.dashboardSettings,
//   ];

//   void _onTabSelected(int index) {
//     setState(() {
//       _selectedIndex = index;
//       _navigatorKey.currentState!.pushNamedAndRemoveUntil(
//         _routes[index],
//         (route) => false,
//       );
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Navigator(
//         key: _navigatorKey,
//         initialRoute: AppRoutes.dashboardHome,
//         onGenerateRoute: (settings) {
//           switch (settings.name) {
//             case AppRoutes.dashboardHome:
//               return MaterialPageRoute(
//                 builder: (_) => DashboardPage(
//                   token: '',
//                   onFaceScanTap: () {
//                     Navigator.of(context).pushNamed(AppRoutes.cameraScan);
//                   },
//                 ),
//               );
//             case AppRoutes.dashboardScan:
//               return MaterialPageRoute(builder: (_) => const CameraScanScreen());
//             case AppRoutes.dashboardTodaysRoutine:
//               return MaterialPageRoute(builder: (_) => const TodaysRoutine());
//             case AppRoutes.dashboardEditRoutine:
//               return MaterialPageRoute(builder: (_) => const EditRoutine());
//             case AppRoutes.dashboardAddRoutine:
//               return MaterialPageRoute(builder: (_) => const AddRoutine());
//             default:
//               return MaterialPageRoute(
//                 builder: (_) => const Center(child: Text('Dashboard screen not found')),
//               );
//           }
//         },
//       ),
//       bottomNavigationBar: DashboardNavBar(
//         selectedIndex: _selectedIndex,
//         onTabSelected: _onTabSelected,
//       ),
//     );
//   }
// }
