import 'package:material_ui/material_ui.dart';
import '../../core/models/sale_draft.dart';
import 'payment_screen.dart';

class BuyerInfoScreen extends StatefulWidget {
  final SaleDraft draft;
  const BuyerInfoScreen({super.key, required this.draft});

  @override
  State<BuyerInfoScreen> createState() => _BuyerInfoScreenState();
}

class _BuyerInfoScreenState extends State<BuyerInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  late final TextEditingController _email;

  @override
  void initState() {
    super.initState();
    final d = widget.draft;
    _firstName = TextEditingController(text: d.buyerFirstName);
    _lastName = TextEditingController(text: d.buyerLastName);
    _phone = TextEditingController(text: d.buyerPhone);
    _email = TextEditingController(text: d.buyerEmail);
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;
    final d = widget.draft;
    d.buyerFirstName = _firstName.text.trim();
    d.buyerLastName = _lastName.text.trim();
    d.buyerPhone = _phone.text.trim();
    d.buyerEmail = _email.text.trim();

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PaymentScreen(draft: d),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buyer Info')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _firstName,
              decoration: const InputDecoration(labelText: 'First name *', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastName,
              decoration: const InputDecoration(labelText: 'Last name', border: OutlineInputBorder()),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Phone *', border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email (optional)', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _continue,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Continue to Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
