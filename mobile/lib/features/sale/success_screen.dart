import 'package:material_ui/material_ui.dart';
import '../../core/models/local_sale.dart';
import '../events/event_picker_screen.dart';

class SuccessScreen extends StatelessWidget {
  final LocalSale sale;
  const SuccessScreen({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    final synced = sale.syncStatus == SyncStatus.synced;

    return Scaffold(
      appBar: AppBar(title: const Text('Sale Complete'), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 72, color: Colors.green[600]),
            const SizedBox(height: 16),
            Text(
              sale.isDayOfParking ? '${sale.quantity} parking pass(es) sold' : '${sale.quantity} ticket(s) sold',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(sale.eventTitle, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            if (synced && sale.isDayOfParking)
              const Text('Confirmed.')
            else if (synced) ...[
              Text('Ticket numbers: ${sale.ticketNumbersFormatted}', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('Pot: \$${sale.potValue?.toStringAsFixed(0) ?? '—'}'),
            ] else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Payment recorded. Still syncing to the server —\n'
                  'check History if it doesn\'t confirm shortly.',
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const EventPickerScreen()),
                  (route) => false,
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: Text('Next Sale'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
