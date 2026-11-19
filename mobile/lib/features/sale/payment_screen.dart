import 'package:material_ui/material_ui.dart';
import 'package:square_mobile_payments_sdk/square_mobile_payments_sdk.dart';
import '../../core/models/local_sale.dart';
import '../../core/models/sale_draft.dart';
import '../../core/square_payment_service.dart';
import '../../data/local_sales_db.dart';
import '../../data/sync_service.dart';
import 'success_screen.dart';

class PaymentScreen extends StatefulWidget {
  final SaleDraft draft;
  const PaymentScreen({super.key, required this.draft});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _square = SquarePaymentService();
  bool _charging = false;
  String? _errorMessage;

  Future<void> _chargeCard() async {
    setState(() {
      _charging = true;
      _errorMessage = null;
    });

    try {
      final squarePaymentId = await _square.charge(amountCents: widget.draft.amountChargedCents);
      await _recordSaleAndProceed(squarePaymentId);
    } on PaymentError catch (e) {
      if (!mounted) return;
      setState(() {
        _charging = false;
        // A staff-initiated cancel isn't an error worth alarming over.
        _errorMessage = e.code == PaymentErrorCode.canceled ? 'Cancelled.' : e.message;
      });
    } on AuthorizeError catch (e) {
      if (!mounted) return;
      setState(() {
        _charging = false;
        _errorMessage = 'Could not authorize with Square: ${e.message}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _charging = false;
        _errorMessage = e.toString();
      });
    }
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
                  Text('Hold card near the top of the phone...'),
                ],
              )
            else
              Column(
                children: [
                  const Icon(Icons.contactless, size: 64),
                  const SizedBox(height: 20),
                  if (_errorMessage != null) ...[
                    Text(_errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                  ],
                  ElevatedButton(
                    onPressed: _chargeCard,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      child: Text(_errorMessage != null ? 'Try Again' : 'Charge Card'),
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
