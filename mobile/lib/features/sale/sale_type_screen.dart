import 'package:material_ui/material_ui.dart';
import '../../core/models/sale_draft.dart';
import 'quantity_screen.dart';

class SaleTypeScreen extends StatelessWidget {
  final SaleDraft draft;
  const SaleTypeScreen({super.key, required this.draft});

  void _choose(BuildContext context, SaleType type) {
    draft.saleType = type;
    // Parking passes are almost always bought one at a time; raffle tickets
    // keep the existing default of 5 (see QuantityScreen's quick picks).
    if (type == SaleType.dayOfParking) {
      draft.quantity = 1;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => QuantityScreen(draft: draft),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(draft.event.title)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('What are you selling?', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.confirmation_number, size: 36),
                title: const Text('Raffle Tickets'),
                subtitle: Text('\$${draft.event.ticketPrice.toStringAsFixed(0)} each'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _choose(context, SaleType.raffle),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.local_parking, size: 36),
                title: const Text('Day-Of Parking Pass'),
                subtitle: Text('\$${draft.event.dayofPrice?.toStringAsFixed(0) ?? '—'} each'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _choose(context, SaleType.dayOfParking),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
