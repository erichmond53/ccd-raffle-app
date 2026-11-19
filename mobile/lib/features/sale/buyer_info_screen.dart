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

  // Order matters here — it defines what "up"/"down" step through.
  late final List<FocusNode> _focusOrder;
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();

  int get _currentFieldIndex => _focusOrder.indexWhere((f) => f.hasFocus);

  @override
  void initState() {
    super.initState();
    final d = widget.draft;
    _firstName = TextEditingController(text: d.buyerFirstName);
    _lastName = TextEditingController(text: d.buyerLastName);
    _phone = TextEditingController(text: d.buyerPhone);
    _email = TextEditingController(text: d.buyerEmail);
    _focusOrder = [_firstNameFocus, _lastNameFocus, _phoneFocus, _emailFocus];
    for (final f in _focusOrder) {
      f.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final f in _focusOrder) {
      f.dispose();
    }
    super.dispose();
  }

  void _stepField(int delta) {
    final i = _currentFieldIndex;
    if (i == -1) return;
    final next = i + delta;
    if (next < 0 || next >= _focusOrder.length) return;
    _focusOrder[next].requestFocus();
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
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final i = _currentFieldIndex;

    return Scaffold(
      appBar: AppBar(title: const Text('Buyer Info')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _firstName,
              focusNode: _firstNameFocus,
              decoration: const InputDecoration(labelText: 'First name *', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastName,
              focusNode: _lastNameFocus,
              decoration: const InputDecoration(labelText: 'Last name', border: OutlineInputBorder()),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              focusNode: _phoneFocus,
              decoration: const InputDecoration(labelText: 'Phone *', border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              focusNode: _emailFocus,
              decoration: const InputDecoration(labelText: 'Email (optional)', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _emailFocus.unfocus(),
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
      bottomNavigationBar: keyboardOpen
          ? Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_up),
                        onPressed: (i > 0) ? () => _stepField(-1) : null,
                        tooltip: 'Previous field',
                      ),
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down),
                        onPressed: (i != -1 && i < _focusOrder.length - 1) ? () => _stepField(1) : null,
                        tooltip: 'Next field',
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => FocusScope.of(context).unfocus(),
                    child: const Text('Done'),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
