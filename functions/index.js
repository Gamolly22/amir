const functions = require("firebase-functions");
const fetch = require("node-fetch");

// ✅ حط الـ apiKey زي ما هو عندك (placeholder)
const PAYMOB_API_KEY = "PUT_YOUR_PAYMOB_API_KEY_HERE";

async function getAuthToken() {
  const res = await fetch("https://accept.paymob.com/api/auth/tokens", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ api_key: PAYMOB_API_KEY }),
  });
  const json = await res.json();
  return json.token;
}

exports.verifyPaymobPayment = functions.https.onCall(async (data, context) => {
  const transactionId = data.transactionId; // int/string
  const orderId = data.orderId; // int/string
  const amountCents = data.amountCents; // int (اختياري)

  // 1) لو معانا transactionId -> نأكد من transactions endpoint
  if (transactionId) {
    const url = `https://accept.paymob.com/api/acceptance/transactions/${transactionId}`;
    const res = await fetch(url);
    const json = await res.json();

    const success = json && json.success === true;
    return { success, source: "transaction", raw: json };
  }

  // 2) fallback: لو معانا orderId -> نجيب order ونشوف paid_amount_cents / paid
  if (orderId) {
    const token = await getAuthToken();

    // ملاحظة: endpoint ده غالبًا بيشتغل بدون توكن، بس خلينا نمرره كـ query احتياطي
    const url = `https://accept.paymob.com/api/ecommerce/orders/${orderId}?token=${token}`;
    const res = await fetch(url, {
      headers: { "Content-Type": "application/json" },
      method: "GET",
    });

    const json = await res.json();

    const paidAmount = Number((json && json.paid_amount_cents) || 0);
    const paidFlag = json && json.paid === true;

    // ✅ نجاح لو paidFlag true أو paid_amount_cents > 0
    // ولو amountCents متبعت، نتاكد paidAmount >= amountCents
    let success = false;
    if (amountCents != null) {
      success = paidFlag || paidAmount >= Number(amountCents);
    } else {
      success = paidFlag || paidAmount > 0;
    }

    return { success, source: "order", raw: json };
  }

  // 3) لا ده ولا ده
  return { success: false, source: "none" };
});
