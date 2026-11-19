import 'package:material_ui/material_ui.dart';
import '../../core/models/sale_draft.dart';
import 'buyer_info_screen.dart';

class QuantityScreen extends StatefulWidget {
  final SaleDraft draft;
  const QuantityScreen({super.key, required this.draft});

  @override
  State<QuantityScreen> createState() => _QuantityScreenState();
}

class _QuantityScreenState extends State<QuantityScreen> {
  late final TextEditingController _customController;

  @override
  void initState() {
    super.initState();
    _customController = TextEditingController(text: widget.draft.quantity.toString());
  }

  void _setQuantity(int q) {
    if (q < 1) return;
    setState(() {
      widget.draft.quantity = q;
      _customController.text = q.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final total = draft.amountChargedCents / 100;

    return Scaffold(
      appBar: AppBar(title: Text(draft.event.title)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              draft.saleType == SaleType.dayOfParking ? 'How many parking passes?' : 'How many tickets?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: (draft.saleType == SaleType.dayOfParking ? [1, 2, 3, 4] : [5, 10, 20]).map((q) {
                final selected = draft.quantity == q;
                return ChoiceChip(
                  label: Text('$q'),
                  selected: selected,
                  onSelected: (_) => _setQuantity(q),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _customController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Custom quantity', border: OutlineInputBorder()),
              onChanged: (v) {
                final q = int.tryParse(v);
                if (q != null && q >= 1) {
                  setState(() => draft.quantity = q);
                }
              },
            ),
            const Spacer(),
            Text(
              'Total: \$${total.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: draft.quantity >= 1
                  ? () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => BuyerInfoScreen(draft: draft),
                      ));
                    }
                  : null,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
