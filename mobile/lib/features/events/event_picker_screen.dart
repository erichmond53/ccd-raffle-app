import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';
import '../../core/models/raffle_event.dart';
import '../../core/models/sale_draft.dart';
import '../sale/quantity_screen.dart';
import '../sale/sale_type_screen.dart';

class EventPickerScreen extends StatefulWidget {
  const EventPickerScreen({super.key});

  @override
  State<EventPickerScreen> createState() => _EventPickerScreenState();
}

class _EventPickerScreenState extends State<EventPickerScreen> {
  final ApiClient _api = ApiClient();
  late Future<List<RaffleEvent>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = _api.getEvents();
  }

  void _refresh() {
    setState(() {
      _eventsFuture = _api.getEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sell Raffle Tickets'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<RaffleEvent>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text('Couldn\'t load events.\n${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _refresh, child: const Text('Try again')),
                  ],
                ),
              ),
            );
          }

          final events = snapshot.data!;
          if (events.isEmpty) {
            return const Center(child: Text('No sellable events right now.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final e = events[i];
              return Card(
                child: ListTile(
                  title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${DateFormat.yMMMd().format(e.startDate)} · \$${e.ticketPrice.toStringAsFixed(0)}/ticket · Pot: \$${e.potValue.toStringAsFixed(0)}'
                    '${e.dayofAvailable ? ' · Parking \$${e.dayofPrice?.toStringAsFixed(0)}' : ''}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    final draft = SaleDraft(event: e);
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => e.dayofAvailable ? SaleTypeScreen(draft: draft) : QuantityScreen(draft: draft),
                    ));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
