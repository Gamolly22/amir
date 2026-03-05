import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cloud_functions/cloud_functions.dart';

class PaymobPaymentScreen extends StatefulWidget {
  final String paymentUrl;
  final String successUrl;
  final String failedUrl;

  final int orderId;
  final int amountCents;
  final int? transactionId;

  const PaymobPaymentScreen({
    super.key,
    required this.paymentUrl,
    required this.successUrl,
    required this.failedUrl,
    required this.orderId,
    required this.amountCents,
    this.transactionId,
  });

  @override
  State<PaymobPaymentScreen> createState() => _PaymobPaymentScreenState();
}

class _PaymobPaymentScreenState extends State<PaymobPaymentScreen> {
  late final WebViewController _controller;
  bool _verifying = false;

  int? _extractTransactionIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final candidates = [
        uri.queryParameters["transaction_id"],
        uri.queryParameters["id"],
        uri.queryParameters["txn_id"],
      ];
      final v = candidates.firstWhere(
        (x) => x != null && x!.isNotEmpty,
        orElse: () => null,
      );
      if (v == null) return null;
      return int.tryParse(v);
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleSuccess(String url) async {
    if (_verifying) return;
    setState(() => _verifying = true);

    final extractedTx =
        widget.transactionId ?? _extractTransactionIdFromUrl(url);

    bool ok = false;
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('verifyPaymobPayment');

      final res = await callable.call({
        "transactionId": extractedTx,
        "orderId": widget.orderId,
        "amountCents": widget.amountCents,
      });

      ok = res.data["success"] == true;
    } catch (_) {
      ok = false;
    }

    if (!mounted) return;
    Navigator.pop(context, ok);
  }

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) async {
            debugPrint("🔗 Page finished loading: $url");

            if (url.startsWith(widget.successUrl)) {
              await _handleSuccess(url);
            } else if (url.startsWith(widget.failedUrl)) {
              Navigator.pop(context, false);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إتمام الدفع"),
        backgroundColor: Colors.teal,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_verifying)
            Container(
              color: Colors.black.withOpacity(0.35),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      "جاري تأكيد عملية الدفع...",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
