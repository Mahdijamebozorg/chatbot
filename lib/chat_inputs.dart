import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class ChatInputs extends StatefulWidget {
  final bool typing;
  final TextEditingController textCtrl;
  final Function(String) sendMessage;
  final Function(String) uploadQrCode;
  final Function(double, double) uploadLocation;
  final Function(bool) triggerWait;

  const ChatInputs({
    super.key,
    required this.typing,
    required this.sendMessage,
    required this.textCtrl,
    required this.uploadQrCode,
    required this.uploadLocation,
    required this.triggerWait,
  });

  @override
  State<ChatInputs> createState() => _ChatInputsState();
}

class _ChatInputsState extends State<ChatInputs> {
  @override
  initState() {
    super.initState();
    widget.textCtrl.addListener(() {
      setState(() {});
    });
  }

  // Request location permission and get current position
  Future<void> _sendLocation(BuildContext context) async {
    widget.triggerWait(true);
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('سرویس‌های مکان‌یابی غیرفعال هستند.')),
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('دسترسی به مکان رد شد.')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('دسترسی به مکان برای همیشه رد شده است.'),
          ),
        );
      }
      return;
    }
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
    );
    widget.triggerWait(false);
    widget.uploadLocation(position.latitude, position.longitude);
    // if (context.mounted) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('موقعیت مکانی با موفقیت ارسال شد!')),
    //   );
    // }
  }

  // Show QR code scanning screen
  Future<void> _scanQrCode(BuildContext context) async {
    bool hasCameraPermission = await _requestCameraPermission(context);
    if (!hasCameraPermission) return;
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => QRScannerScreen(
              onQRCodeScanned: (code) {
                widget.uploadQrCode(code);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('کد اسکن شد')));
              },
            ),
      ),
    );
  }

  // Request camera permission
  Future<bool> _requestCameraPermission(BuildContext context) async {
    widget.triggerWait(true);
    PermissionStatus status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('دسترسی به دوربین رد شد.')),
        );
      }
      widget.triggerWait(false);
      return false;
    }
    widget.triggerWait(false);
    return true;
  }

  // Pick image from gallery and scan for QR code
  // Future<void> _pickImageAndScan(BuildContext context) async {
  //   bool hasStoragePermission = await _requestStoragePermission(context);
  //   if (!hasStoragePermission) return;

  //   final ImagePicker picker = ImagePicker();
  //   final XFile? image = await picker.pickImage(source: ImageSource.gallery);

  //   if (image != null) {
  //     // Note: QR code scanning from images requires additional logic.
  //     // For simplicity, we'll assume a placeholder function.
  //     // In a real app, use a library like `qr_code_tools` to decode QR from images.
  //     String qrCode =
  //         "Scanned_QR_Code_From_Image"; // Replace with actual QR decoding logic
  //     widget.uploadQrCode(qrCode);
  //     if (context.mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('کد QR از گالری با موفقیت ارسال شد!')),
  //       );
  //     }
  //   }
  // }

  // Request storage permission for gallery
  // Future<bool> _requestStoragePermission(BuildContext context) async {
  //   PermissionStatus status = await Permission.storage.request();
  //   if (status.isDenied || status.isPermanentlyDenied) {
  //     if (context.mounted) {
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(const SnackBar(content: Text('دسترسی به حافظه رد شد.')));
  //     }
  //     return false;
  //   }
  //   return true;
  // }

  bool sendingLocation = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          if (widget.textCtrl.text.isNotEmpty)
            Directionality(
              textDirection: TextDirection.ltr,
              child: IconButton(
                onPressed:
                    widget.typing
                        ? null
                        : () => widget.sendMessage(widget.textCtrl.text),
                icon: const Icon(Icons.send),
                color: widget.typing ? Colors.grey : Colors.blue,
                tooltip: 'ارسال',
              ),
            ),
          if (widget.textCtrl.text.isEmpty)
            IconButton(
              onPressed: widget.typing ? null : () => _sendLocation(context),
              icon: const Icon(Icons.location_on),
              color: widget.typing ? Colors.grey : Colors.blue,
              tooltip: 'ارسال موقعیت مکانی',
            ),
          if (widget.textCtrl.text.isEmpty)
            IconButton(
              onPressed:
                  widget.typing
                      ? null
                      : () {
                        // if (kIsWeb) {
                        //   ScaffoldMessenger.of(context).showSnackBar(
                        //     const SnackBar(
                        //       content: Text('سرویس‌ غیرفعال است.'),
                        //       duration: Duration(seconds: 1),
                        //     ),
                        //   );
                        //   return;
                        // }
                        _scanQrCode(context);
                        // showDialog(
                        //   context: context,
                        //   builder:
                        //       (context) => AlertDialog(
                        //         title: const Text('اسکن کد QR'),
                        //         content: Column(
                        //           mainAxisSize: MainAxisSize.min,
                        //           spacing: 12,
                        //           children: [
                        //             ElevatedButton(
                        //               onPressed: () {
                        //                 if (kIsWeb) return;
                        //                 Navigator.pop(context);
                        //                 _scanQrCode(context);
                        //               },
                        //               child: const Text('اسکن با دوربین'),
                        //             ),
                        //             ElevatedButton(
                        //               onPressed: () {
                        //                 if (kIsWeb) return;
                        //                 Navigator.pop(context);
                        //                 _pickImageAndScan(context);
                        //               },
                        //               child: const Text('انتخاب از گالری'),
                        //             ),
                        //           ],
                        //         ),
                        //       ),
                        // );
                      },
              icon: const Icon(Icons.qr_code_scanner),
              color: widget.typing ? Colors.grey : Colors.blue,
              tooltip: 'اسکن کد QR',
            ),
          const SizedBox(width: 8),

          Expanded(
            child: TextField(
              controller: widget.textCtrl,
              enabled: !widget.typing,
              decoration: InputDecoration(
                hintText:
                    widget.typing
                        ? 'لطفاً منتظر پاسخ باشید...'
                        : 'پیام خود را تایپ کنید...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onSubmitted: widget.sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

// QR Scanner Screen
class QRScannerScreen extends StatefulWidget {
  final void Function(String) onQRCodeScanned;

  const QRScannerScreen({super.key, required this.onQRCodeScanned});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  StreamSubscription? _subscription;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.blue,
        title: const Text(
          'اسکن کد',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.blue,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            right: 0,
            left: 0,
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.max,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await controller?.toggleFlash();
                      setState(() {});
                    },
                    child: FutureBuilder<bool?>(
                      future: controller?.getFlashStatus(),
                      builder: (context, snapshot) {
                        return Text(
                          'فلش: ${snapshot.data ?? false ? "روشن" : "خاموش"}',
                        );
                      },
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await controller?.flipCamera();
                      setState(() {});
                    },
                    child: FutureBuilder(
                      future: controller?.getCameraInfo(),
                      builder: (context, snapshot) {
                        return Text(
                          'دوربین: ${snapshot.data == CameraFacing.back
                              ? 'پشت'
                              : snapshot.data == CameraFacing.front
                              ? 'جلو'
                              : 'پشت'}',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    _subscription = controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null && mounted) {
        controller.pauseCamera();
        widget.onQRCodeScanned(scanData.code!);
        Navigator.pop(context);
      }
    });
  }
}
