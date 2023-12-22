import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  const MyApp({Key? key, required this.camera}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CameraScreen(camera: camera),
    );
  }
}

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraScreen({Key? key, required this.camera}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late XFile? _videoFile;
  bool isRecording = false;
  late int selectedTimeInSeconds;
  late int remainingTimeInSeconds;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();
    selectedTimeInSeconds = 10; // Default recording time (in seconds)
    remainingTimeInSeconds = selectedTimeInSeconds;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

 void startRecording() async {
  try {
    await _controller.startVideoRecording();
    setState(() {
      isRecording = true;
      timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          remainingTimeInSeconds--;
          if (remainingTimeInSeconds <= 0) {
            stopRecording();
          }
        });
      });
    });
  } catch (e) {
    print('Error starting recording: $e');
  }
}
  void stopRecording() async {
    timer.cancel();
    await _controller.stopVideoRecording();
    setState(() {
      isRecording = false;
      remainingTimeInSeconds = selectedTimeInSeconds;
    });
  }

  Future<void> _recordButtonPressed() async {
    if (!isRecording) {
      startRecording();
    } else {
      stopRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reel Recording'),
      ),
      body: FutureBuilder(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(_controller),
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    onPressed: _recordButtonPressed,
                    style: ElevatedButton.styleFrom(
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(24),
                      primary: isRecording ? Colors.red : Colors.blue,
                    ),
                    child: Text(
                      isRecording ? 'Stop' : 'Record',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (!isRecording) {
            await showDialog(
              context: context,
              builder: (context) => _buildTimeSelectionDialog(context),
            );
          }
        },
        child: Icon(Icons.timer),
      ),
    );
  }

  Widget _buildTimeSelectionDialog(BuildContext context) {
    return AlertDialog(
      title: Text('Select Recording Time'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text('10 seconds'),
            onTap: () {
              setState(() {
                selectedTimeInSeconds = 10;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('30 seconds'),
            onTap: () {
              setState(() {
                selectedTimeInSeconds = 30;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('60 seconds'),
            onTap: () {
              setState(() {
                selectedTimeInSeconds = 60;
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}