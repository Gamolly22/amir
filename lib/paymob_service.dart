import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymobService {
  final String apiKey =
      "ZXlKaGJHY2lPaUpJVXpVeE1pSXNJblI1Y0NJNklrcFhWQ0o5LmV5SmpiR0Z6Y3lJNklrMWxjbU5vWVc1MElpd2ljSEp2Wm1sc1pWOXdheUk2TVRBMU9UYzRNU3dpYm1GdFpTSTZJakUzTmpnMU56azFNemt1TVRNNU5qY3pJbjAuVHdqQzN1MnJwd0xsY01wLXAzZE4xeEE2bTdBVkg3b1I4WVNkUE9uZkdNSVFra3FDbDBRbm5SQ0dpcFl1eVlTTGE1TC11emptcHNVaUxSd2U5RnQ1aFE=";
  final String walletIntegrationId = "5236470";
  final String iframeId = "939136";
  final String cardIntegrationId = "5233345";

  Future<String> getAuthToken() async {
    final url = Uri.parse("https://accept.paymob.com/api/auth/tokens");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode({"api_key": apiKey}),
    );
    final data = json.decode(response.body);
    return data["token"];
  }

  Future<bool> isTransactionSuccess(int transactionId) async {
    final url = Uri.parse(
        "https://accept.paymob.com/api/acceptance/transactions/$transactionId");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["success"] == true;
    }
    return false;
  }

  Future<int> createOrder(String token, int amountCents) async {
    final url = Uri.parse("https://accept.paymob.com/api/ecommerce/orders");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "auth_token": token,
        "amount_cents": amountCents,
        "currency": "EGP",
        "delivery_needed": "false",
        "items": [],
      }),
    );
    final data = json.decode(response.body);
    return data["id"];
  }

  Future<String> getPaymentKey(
    String token,
    int orderId,
    int amountCents,
    String integrationId,
  ) async {
    final url =
        Uri.parse("https://accept.paymob.com/api/acceptance/payment_keys");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "auth_token": token,
        "amount_cents": amountCents,
        "expiration": 3600,
        "order_id": orderId,
        "billing_data": {
          "apartment": "NA",
          "email": "user@test.com",
          "floor": "NA",
          "first_name": "Test",
          "street": "NA",
          "building": "NA",
          "phone_number": "+201000000000",
          "shipping_method": "NA",
          "postal_code": "NA",
          "city": "Cairo",
          "country": "EG",
          "last_name": "User",
          "state": "NA"
        },
        "currency": "EGP",
        "integration_id": integrationId,
      }),
    );
    final data = json.decode(response.body);
    return data["token"];
  }

  Future<Map<String, dynamic>> payWithWallet(
      String paymentKey, String walletNumber) async {
    final url =
        Uri.parse("https://accept.paymob.com/api/acceptance/payments/pay");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "source": {"identifier": walletNumber, "subtype": "WALLET"},
        "payment_token": paymentKey,
      }),
    );
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> confirmWalletOtp(
      String transactionId, String otp) async {
    final url =
        Uri.parse("https://accept.paymob.com/api/acceptance/payments/otp");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "transaction_id": transactionId,
        "otp": otp,
      }),
    );
    return json.decode(response.body);
  }

  String getCardPaymentUrl(String paymentKey) {
    return "https://accept.paymob.com/api/acceptance/iframes/$iframeId?payment_token=$paymentKey";
  }
}
