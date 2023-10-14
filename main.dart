import 'package:custom_video_player/customVideoPlayer.dart';
import 'package:flutter/material.dart';
// import 'package:dart_vlc/dart_vlc.dart';
import 'package:media_kit/media_kit.dart';

void main() async {
  // DartVLC.initialize();
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(
        useMaterial3: true,
      ),
      home: Scaffold(
        body: MyScreen(),
      ),
    );
  }
}
