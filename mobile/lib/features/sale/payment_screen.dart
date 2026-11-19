import 'dart:math';
import 'package:material_ui/material_ui.dart';
import '../../core/models/local_sale.dart';
import '../../core/models/sale_draft.dart';
import '../../data/local_sales_db.dart';
import '../../data/sync_service.dart';
import 'success_screen.dart';

/// PHASE 1 STUB: the real Square Mobile Payments SDK (Tap to Pay) isn't wired
/// in yet — see docs/setup-checklist.md. This screen stands in for it so the
/// rest of the app (local queue, sync, history) can be built and tested now.
/// Replace [_fakeChargeCard] with a real `square_mobile_payments_sdk` charge
/// in Phase 2; nothing else in this screen should need to change, since the
/// local-row-first invariant below is exactly what the real SDK flow needs too.
class PaymentScreen extends StatefulWidget {
  final SaleDraft draft;
  const PaymentScreen({super.key, required this.draft});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _charging = false;

  Future<void> _fakeChargeCard() async {
    setState(() => _charging = true);
    await Future.delayed(const Duration(seconds: 1)); // pretend the tap happened

    // A real Square charge's payment ID looks like "sq0idp-...". Prefixing
    // this stub clearly as fake so it's unmistakable in logs/History if this
    // ever leaked into a real build.
    final fakePaymentId = 'stub-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(99999)}';

    await _recordSaleAndProceed(fakePaymentId);
  }

  /// The local row is written the instant the charge succeeds, before any
  /// network call — that row is the proof money was taken. Syncing it to
  /// WordPress is attempted right away but is best-effort: if it fails, the
  /// sale still shows up (as pending) in History, never lost.
  Future<void> _recordSaleAndProceed(String squarePaymentId) async {
    final d = widget.draft;

    final sale = LocalSale(
      squarePaymentId: squarePaymentId,
      eventId: d.event.eventId,
      eventTitle: d.event.title,
      quantity: d.quantity,
      buyerFirstName: d.buyerFirstName,
      buyerLastName: d.buyerLastName,
      buyerPhone: d.buyerPhone,
      buyerEmail: d.buyerEmail,
      amountChargedCents: d.amountChargedCents,
      createdAt: DateTime.now(),
    );

    final stored = await LocalSalesDb.instance.insert(sale);
    final synced = await SyncService().syncOne(stored);

    final finalRow = synced
        ? await LocalSalesDb.instance.findByPaymentId(squarePaymentId) ?? stored
        : stored;

    if (!mounted) return;

    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => SuccessScreen(sale: finalRow),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    final total = d.amountChargedCents / 100;

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${d.quantity} ticket(s) — ${d.event.title}', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('\$${total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 40),
            if (_charging)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Processing...'),
                ],
              )
            else
              Column(
                children: [
                  const Icon(Icons.contactless, size: 64),
                  const SizedBox(height: 12),
                  const Text(
                    'DEV STUB — real Tap to Pay not wired in yet',
                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _fakeChargeCard,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      child: Text('Simulate Payment Success'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
