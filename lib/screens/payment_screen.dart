import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentScreen extends StatefulWidget {
  final String pdfTitle;
  final int amount; // in paise (100 = ₹1)

  const PaymentScreen({
    super.key,
    required this.pdfTitle,
    this.amount = 100, // default ₹1 for testing
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _openCheckout() {
    var options = {
      'key': 'rzp_test_RGfTAuTohoJpta', // 🔑 Replace with Live Key in production
      'amount': widget.amount, // in paise (100 = ₹1)
      'name': 'MBBS Freaks',
      'description': widget.pdfTitle,
      'prefill': {
        'contact': '9876543210',
        'email': 'testuser@gmail.com',
      },
      'method': {
        'upi': true,         // ✅ Enable UPI
        'card': true,
        'netbanking': true,
        'wallet': true,
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Razorpay error: $e");
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ SUCCESS: ${response.paymentId}")),
    );
    // TODO: Call your backend API to verify payment before unlocking premium
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("❌ ERROR: ${response.code} - ${response.message}"),
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Wallet Selected: ${response.walletName}")),
    );
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Unlock Premium")),
      body: Center(
        child: ElevatedButton(
          onPressed: _openCheckout,
          child: const Text("Pay Now ₹1"),
        ),
      ),
    );
  }
}
