import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pretty_http_logger/pretty_http_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart_delivery/util/app_constants.dart';

class QrCode extends StatefulWidget {
  final String orderId;
  const QrCode({super.key, required this.orderId});

  @override
  State<QrCode> createState() => _QrCodeState();
}

class _QrCodeState extends State<QrCode> {
  String? upiString;
  String? qrId;
  bool isLoading = false;
  String? errorMessage;
  Timer? _timer;
  String? qrUrl;
  String? qrImageBase64;

  @override
  void initState() {
    super.initState();
    qrCodeApi();

    // har 5 second me payment check karega
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      checkPaymentApi();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await _onBackPressed();
      },
      child: Scaffold(
        backgroundColor: Color(0xFFF4F9FF),
        appBar: AppBar(
          backgroundColor: Color(0xFFF4F9FF),
          title: const Text("Scan & Pay"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              bool exit = await _onBackPressed();
              if (exit) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: Container(
          color: Color(0xFFF4F9FF),
          // color: Colors.red,
          child: Center(
            child: !isLoading
                ? errorMessage != null
                ? Text(
              errorMessage!,
              style: const TextStyle(color: Colors.red),
            )
                : qrImageBase64 != null
                ? Image.memory(
              _base64ToImage(qrImageBase64!),
            )
                : const Text("⏳ Generating QR...")
                : const CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }

  /// Back button press par dialog dikhane ka function
  Future<bool> _onBackPressed() async {
    bool? exitApp = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Exit Payment"),
        content: const Text(
            "Are you sure you want to go back? Payment may fail if not completed."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Stay
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () {
              _timer?.cancel(); // ✅ Stop periodic payment check
              Navigator.of(context).pop(true); // Exit allowed
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
    return exitApp ?? false;
  }

  Future<void> qrCodeApi() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    HttpWithMiddleware http = HttpWithMiddleware.build(
      middlewares: [HttpLogger(logLevel: LogLevel.BODY)],
    );

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString(AppConstants.token);

      var url = "${AppConstants.baseUrl}${AppConstants.razorPayQr}";
      var response = await http.post(
        Uri.parse(url),
        headers: {
          'content-type': 'application/json',
          'accept': 'application/json',
        },
        body: jsonEncode({
          "order_id": widget.orderId,
          "token": token,
        }),
      );

      debugPrint("✅ QR Response: ${response.body}");

      Map<String, dynamic> jsonResponse = jsonDecode(response.body);

      if (jsonResponse['success'] == true) {
        setState(() {
          upiString = jsonResponse['qr_url'];
          qrId = jsonResponse['qr_id'];
          qrImageBase64 = jsonResponse['qr_image'];
        });
      } else {
        setState(() {
          errorMessage = jsonResponse['message'] ?? "Failed to generate QR";
        });
      }
    } catch (error) {
      debugPrint("❌ Error in qrCodeApi: $error");
      setState(() {
        errorMessage = "Something went wrong!";
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }



  Future<void> checkPaymentApi() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString(AppConstants.token);

      HttpWithMiddleware http = HttpWithMiddleware.build(
        middlewares: [HttpLogger(logLevel: LogLevel.BODY)],
      );

      var url =
          "${AppConstants.baseUrl}${AppConstants.checkPayment}/$qrId/${widget.orderId}?token=$token";

      debugPrint("🔗 CheckPayment URL: $url");

      var response = await http.get(
        Uri.parse(url),
        headers: {
          'content-type': 'application/json',
          'accept': 'application/json',
        },
      );

      debugPrint("✅ CheckPayment Response: ${response.body}");

      Map<String, dynamic> jsonResponse = jsonDecode(response.body);

      if (jsonResponse['status'] == true) {
        _timer?.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Payment Successful!"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          Future.delayed(const Duration(seconds: 2), () {
            // if (mounted) Navigator.pop(context, qrId);
            if (mounted) Navigator.pop(context, true);

          });
        }
      }/*else{
        Future.delayed(const Duration(seconds: 2), () {
          // if (mounted) Navigator.pop(context, qrId);
          if (mounted) Navigator.pop(context, true);

        });
      }*/
    } catch (error) {
      debugPrint("❌ Error in checkPaymentApi: $error");
    }
  }


}

Uint8List _base64ToImage(String base64String) {
  return base64Decode(base64String);
}
