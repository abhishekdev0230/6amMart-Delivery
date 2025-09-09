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
    return Scaffold(
      appBar: AppBar(title: const Text("Scan & Pay")),
      body: Center(
        child: !isLoading
            ? errorMessage != null
                ? Text(errorMessage!, style: const TextStyle(color: Colors.red))
            : qrImageBase64 != null
            ? Image.memory(
          _base64ToImage(qrImageBase64!),
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        )
            : const Text("⏳ Generating QR...")

            : const CircularProgressIndicator(),
      ),
    );
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
          "token": token, // ✅ token body me bhejna zaruri hai
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

      // 🔑 Token ko query parameter me bhejo
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
            if (mounted) Navigator.pop(context, qrId);
          });
        }
      }
    } catch (error) {
      debugPrint("❌ Error in checkPaymentApi: $error");
    }
  }


}

Uint8List _base64ToImage(String base64String) {
  return base64Decode(base64String);
}
