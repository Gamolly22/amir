import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymobCheckout {
  static Future<void> open({
    required BuildContext context,
    required String publicKey,
    required String clientSecret,
  }) async {
    
    if (kIsWeb) {
      final pk = Uri.encodeComponent(publicKey);
      final cs = Uri.encodeComponent(clientSecret);

      
      final url = Uri.parse("/paymob_checkout.html?pk=$pk&cs=$cs");

      await launchUrl(
        url,
        mode: LaunchMode.platformDefault,
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PaymobWebViewPage(
          publicKey: publicKey,
          clientSecret: clientSecret,
        ),
      ),
    );
  }
}

class _PaymobWebViewPage extends StatefulWidget {
  final String publicKey;
  final String clientSecret;

  const _PaymobWebViewPage({
    required this.publicKey,
    required this.clientSecret,
  });

  @override
  State<_PaymobWebViewPage> createState() => _PaymobWebViewPageState();
}

class _PaymobWebViewPageState extends State<_PaymobWebViewPage> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();

    final html = """
<!doctype html>
<html>
<body style="font-family:Arial;padding:16px">
<div id="btn"></div>
<script src="https://flashapi.paymob.com/paymob-elements.js"></script>
<script>
  const paymob = Paymob("${widget.publicKey}");
  const btn = paymob.checkoutButton({ client_secret: "${widget.clientSecret}" });
  btn.mount("#btn");
</script>
</body>
</html>
""";

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(html);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("الدفع")),
      body: WebViewWidget(controller: controller),
    );
  }
}
