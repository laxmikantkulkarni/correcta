// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'providers/camera_provider.dart';
import 'providers/pose_detector_provider.dart';
import 'providers/squat_counter_provider.dart';
import 'providers/tts_provider.dart';
import 'screens/squat_counter_screen.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CameraProvider()),
        ChangeNotifierProvider(create: (_) => PoseDetectorProvider()),
        ChangeNotifierProvider(create: (_) => SquatCounterProvider()),
        ChangeNotifierProvider(create: (_) => TtsProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Squat Counter',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: SquatCounterScreen(cameras: cameras),
      ),
    );
  }
}