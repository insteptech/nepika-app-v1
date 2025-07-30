// import 'dart:async';
// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:dr_genie/core/constants/api_service.dart';
// import 'package:dr_genie/core/providers/health_data_provider.dart';
// import 'package:dr_genie/core/providers/user_provider.dart';
// import 'package:dr_genie/core/widgets/display_health_data.dart';
// import 'package:dr_genie/features/reports/health_dashboard.dart';
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:dr_genie/core/widgets/scan_animation.dart';
// import 'package:provider/provider.dart';

// class FaceScanScreen extends StatefulWidget {
//   final Map<String, dynamic>? combinedData;
//   const FaceScanScreen({Key? key, this.combinedData}) : super(key: key);
//   @override
//   _FaceScanScreenState createState() => _FaceScanScreenState();
// }

// class _FaceScanScreenState extends State<FaceScanScreen> {
//   Map<String, dynamic>? combinedData;
//  final ApiService _apiService = ApiService();
//   double _progress = 0.0;
//   Timer? _timer;
//   CameraController? _cameraController;
//   Future<void>? _initializeCameraFuture;
//   CameraDescription? _currentCamera;

//   bool _isUploading = false;
//   bool _scanningComplete = false;
//   late int _captureInterval;
//   Map<String, dynamic> heartRate = {"value": "--", "tag": "--"};
//   Map<String, dynamic> bloodGlucose = {"value": "--", "tag": "--"};
//   Map<String, dynamic> spo2 = {"value": "--", "tag": "--"};
//   Map<String, dynamic> hrv = {"value": "--", "tag": "--"};
//   Map<String, dynamic> mood = {"value": "--", "tag": "--"};
//   Map<String, dynamic> fatigue = {"value": "--", "tag": "--"};
//   Map<String, dynamic> bloodPressure = {"value": "--", "tag": "--"};
//   Map<String, dynamic> overallHealth = {"value": "--", "tag": "--"};

//   @override
//   void initState() {
//     super.initState();
//     _initializeCameras();
//     _captureInterval = 500; // Set capture interval (500ms)
//     _startScanProgress();
//   }

//   // Initialize cameras
//   Future<void> _initializeCameras() async {
//     try {
//       final cameras = await availableCameras();
//       if (cameras.isNotEmpty) {
//         _currentCamera = cameras.firstWhere(
//             (camera) => camera.lensDirection == CameraLensDirection.front,
//             orElse: () => cameras.first);

//         _cameraController = CameraController(
//           _currentCamera!,
//           ResolutionPreset.medium,
//         );
//         _initializeCameraFuture = _cameraController?.initialize();
//         await _initializeCameraFuture;

//         // Set the flash mode to off
//         await _cameraController?.setFlashMode(FlashMode.off);

//         setState(() {});
//       } else {
//         _showErrorSnackBar("No cameras available");
//       }
//     } catch (e) {
//       print(e);
//       _showErrorSnackBar("Error initializing cameras: $e");
//     }
//   }

//   // Capture frames periodically
//   void _startCapturingFrames() {
//     if (_cameraController == null || !_cameraController!.value.isInitialized) {
//       _showErrorSnackBar("Camera is not initialized");
//       return;
//     }

//     Future.delayed(Duration(milliseconds: _captureInterval), () async {
//       try {
//         final XFile imageFile = await _cameraController!.takePicture();
//         Uint8List imageBytes = await imageFile.readAsBytes();
//         String base64Image = base64Encode(imageBytes);
//         String dataUrl = 'data:image/jpeg;base64,' + base64Image;
//         await _uploadFrame(dataUrl);
//       } catch (e) {
//         print(e);
//         _showErrorSnackBar("Error capturing frame: $e");
//       }
//     });
//   }

  

// Future<void> _uploadFrame(String image) async {
//   setState(() {
//     _isUploading = true;
//   });
  
//   final userProvider = Provider.of<UserDetailsProvider>(context, listen: false);
//   String age = userProvider.age.toString();
//   String weight = userProvider.weight.toString();
//   String height = userProvider.height.toString();
//   print("data$age,$height,$weight");
//   try {
//     final responseData = await _apiService.uploadFrame(
//       image: image,
//       age: age,
//       weight: weight,
//       height: height,
//     );
//     // Process the response
//     print("Response Data: $responseData");
//     setState(() {
//       heartRate = display_health_data(responseData, 'heart_rate', 'bpm', defaultText: "--");
//       bloodGlucose = display_health_data(responseData, 'blood_glucose', 'mmol/dl', defaultText: "--");
//       spo2 = display_health_data(responseData, 'spo2', '%', defaultText: "--");
//       hrv = display_health_data(responseData, 'hrv', 'seconds', defaultText: "--");
//       mood = display_health_data(responseData, 'mood', '', defaultText: "--");
//       fatigue = display_health_data(responseData, 'fatigue', '', defaultText: "--");
//       bloodPressure = display_health_data(responseData, 'blood_pressure', 'mmHg', defaultText: "--");
//       overallHealth = display_health_data(responseData, 'overall_health', '', defaultText: "--");
//     });

//     // Save the health data to the provider
//     final healthDataProvider = context.read<HealthDataProvider>();
//     healthDataProvider.setHealthData({
//       "heartRate": heartRate,
//       "bloodGlucose": bloodGlucose,
//       "spo2": spo2,
//       "hrv": hrv,
//       "mood": mood,
//       "fatigue": fatigue,
//       "bloodPressure": bloodPressure,
//       "overallHealth": overallHealth,
//     });

//     // Navigate if all data is valid
//     if (_isAllDataValid()) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => HealthDashboard(apiResponse: {
//             "heartRate": heartRate,
//             "bloodGlucose": bloodGlucose,
//             "spo2": spo2,
//             "hrv": hrv,
//             "mood": mood,
//             "fatigue": fatigue,
//             "bloodPressure": bloodPressure,
//             "overallHealth": overallHealth,
//           }),
//         ),
//       );
//     } else {
//       _startCapturingFrames();
//     }
//   } catch (e) {
//     print("Error: $e");
//     _showErrorSnackBar("Error uploading frame: $e");
//   } finally {
//     setState(() {
//       _isUploading = false;
//     });
//   }
// }

//  bool _isAllDataValid() {
//     return heartRate.isNotEmpty &&
//         !heartRate["value"].contains("--") &&
//         bloodGlucose.isNotEmpty &&
//         !bloodGlucose["value"].contains("--") &&
//         spo2.isNotEmpty &&
//         !spo2["value"].contains("--") &&
//         hrv.isNotEmpty &&
//         !hrv["value"].contains("--") &&
//         mood.isNotEmpty &&
//         !mood["value"].contains("--") &&
//         fatigue.isNotEmpty &&
//         !fatigue["value"].contains("--") &&
//         bloodPressure.isNotEmpty &&
//         !bloodPressure["value"].contains("--") &&
//         overallHealth.isNotEmpty &&
//         !overallHealth["value"].contains("--");
//   }

//   // Start progress animation
//   void _startScanProgress() {
//     _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
//       if (_progress < 1) {
//         setState(() {
//           _progress += 0.05;
//         });
//       } else {
//         _timer?.cancel();
//         _startCapturingFrames(); // Start capturing frames after progress completes
//       }
//     });
//   }

//   // Show error snack bar
//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: Colors.red),
//     );
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     _cameraController?.dispose();
//     super.dispose();
//   }

//   void _defaultFun() {}

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF004352),
//       body: Stack(
//         children: [
//           // Custom AppBar
//           Positioned(
//             top: 50,
//             left: 20,
//             child: Row(
//               children: [
//                 Image.asset(
//                   'assets/images/Layer_3x.png',
//                   height: 24,
//                   width: 24,
//                 ),
//                 const SizedBox(width: 8),
//                 const Text(
//                   'DrGenieAI',
//                   style: TextStyle(
//                     color: Color(0xFF00F8BC),
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Positioned(
//             top: 45,
//             right: 20,
//             child: IconButton(
//               icon: const Icon(Icons.close, color: Colors.white, size: 30),
//               onPressed: () => Navigator.pop(context),
//             ),
//           ),
//           Center(
//             child: Container(
//               padding: const EdgeInsets.all(5),
//               child: FutureBuilder<void>(
//                 future: _initializeCameraFuture,
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.done) {
//                     return Container(
//                       width: 300,
//                       height: 400,
//                       child: Stack(
//                         alignment: Alignment.center,
//                         children: [
//                           CameraPreview(_cameraController!),
//                           Positioned.fill(
//                             child: ScannerAnimation(),
//                           ),
//                         ],
//                       ),
//                     );
//                   } else if (snapshot.hasError) {
//                     return Text(
//                       'Error: ${snapshot.error}',
//                       style: const TextStyle(color: Colors.white),
//                     );
//                   } else {
//                     return const CircularProgressIndicator(
//                       color: Colors.white,
//                     );
//                   }
//                 },
//               ),
//             ),
//           ),
//           Positioned(
//             bottom: 20,
//             left: 20,
//             right: 20,
//             child: SizedBox(
//               width: double
//                   .infinity, // Takes the full width of the Positioned area
//               child: ElevatedButton(
//                 onPressed: _isUploading ? _defaultFun : _startCapturingFrames,
//                 child: Text(
//                     !_scanningComplete ? "Processing..." : "Start Face Scan",
//                     style: TextStyle(color: Color(0xFF004352))),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
