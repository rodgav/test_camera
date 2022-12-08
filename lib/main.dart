import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

late List<CameraDescription> _cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CameraView(),
    );
  }
}

class CameraView extends StatefulWidget {
  const CameraView({Key? key}) : super(key: key);

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  late CameraController controller;
  String? filePath;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    controller = CameraController(_cameras[1], ResolutionPreset.max);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            print('User denied camera access.');
            break;
          default:
            print('Handle other errors.');
            break;
        }
      }
    });
  }

  /*@override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      onNewCameraSelected(cameraController.description);
    }
  }*/

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight - 80,
                  child: CameraPreview(controller),
                ),
                SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight - 80,
                    child: const Image(
                      image: AssetImage('assets/images/marco.png'),
                      fit: BoxFit.fill,
                    ))
              ],
            );
          },
        ),
      ),
      bottomSheet: Container(
        color: Colors.black87,
        height: 80,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
                onPressed: () {
                  if (filePath != null) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ImagePreview(filePath!)));
                  }
                },
                icon: const Icon(
                  Icons.image,
                  color: Colors.white,
                  size: 30,
                )),
            IconButton(
                onPressed: () async {
                  final xFile = await controller.takePicture();
                  ui.Image? originalImage =
                      ui.decodeImage(await xFile.readAsBytes());
                  final imageWidth = originalImage?.width;
                  final imageHeight = originalImage?.height;
                  print('imageWidth $imageWidth --- imageHeight $imageHeight');
                  final byteData =
                      await rootBundle.load('assets/images/marco.png');
                  Uint8List audioUint8List = byteData.buffer.asUint8List(
                      byteData.offsetInBytes, byteData.lengthInBytes);
                  List<int> audioListInt = audioUint8List.cast<int>();
                  ui.Image? twoImage = ui.decodeImage(audioListInt);
                  final image2Width = twoImage?.width;
                  final image2Height = twoImage?.height;
                  print(
                      'image2Width $image2Width --- image2Height $image2Height');
                  if (imageWidth != null &&
                      imageHeight != null &&
                      twoImage != null &&
                      originalImage != null) {
                    ui.Image image = ui.Image(imageWidth, imageHeight);
                    print(
                        'image.width ${image.width}---image.height ${image.height}');
                    ui.drawImage(
                      image,
                      twoImage,
                      dstW: imageWidth,
                      dstH: imageHeight,
                    );
                    print(
                        'image.width ${image.xOffset}---image.height ${image.yOffset}');
                    ui.copyInto(originalImage, image,
                        srcX: 0,
                        srcY: 0,
                        srcW: image.width,
                        srcH: image.height);
                    //ui.drawString(originalImage, ui.arial_48, 100, 120, 'Think Different');
                    List<int> wmImage = ui.encodeJpg(originalImage);

                    //File.fromRawPath(Uint8List.fromList(wmImage));

                    Directory appDocumentsDirectory =
                        await getApplicationDocumentsDirectory(); // 1
                    String appDocumentsPath = appDocumentsDirectory.path; // 2
                    filePath = '$appDocumentsPath/demoTextFile.jpg'; // 3
                    if (filePath != null) {
                      File file = File(filePath!); // 1
                      file.writeAsBytes(wmImage); // 2
                      print('path $filePath');
                    }
                    setState(() {});
                  }
                },
                icon: const Icon(
                  Icons.photo_camera,
                  color: Colors.white,
                  size: 30,
                )),
            IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.change_circle,
                  color: Colors.white,
                  size: 30,
                )),
          ],
        ),
      ),
    );
  }
}

class ImagePreview extends StatelessWidget {
  final String filePath;

  const ImagePreview(this.filePath, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(builder: (_) {
        File file = File(filePath);
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Image.file(
              file,
              fit: BoxFit.cover,
            ),
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Share.shareXFiles([XFile(filePath)], text: 'Great picture');
        },
        child: Icon(Icons.share),
      ),
    );
  }
}
