import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import '../../core/models/local_sale.dart';
import '../../data/local_sales_db.dart';
import '../../data/sync_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<LocalSale> _sales = [];
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sales = await LocalSalesDb.instance.all();
    if (mounted) setState(() => _sales = sales);
  }

  Future<void> _retryAllPending() async {
    setState(() => _syncing = true);
    await SyncService().syncPending();
    await _load();
    if (mounted) setState(() => _syncing = false);
  }

  Future<void> _retryOne(LocalSale sale) async {
    await SyncService().syncOne(sale);
    await _load();
  }

  Color _statusColor(SyncStatus s) {
    switch (s) {
      case SyncStatus.synced:
        return Colors.green;
      case SyncStatus.pending:
        return Colors.orange;
      case SyncStatus.failedPermanent:
        return Colors.red;
    }
  }

  String _statusLabel(SyncStatus s) {
    switch (s) {
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.pending:
        return 'Pending';
      case SyncStatus.failedPermanent:
        return 'Needs attention';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _sales.where((s) => s.syncStatus == SyncStatus.pending).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          if (pendingCount > 0)
            Container(
              width: double.infinity,
              color: Colors.orange[50],
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$pendingCount pending — tap to retry'),
                  TextButton(
                    onPressed: _syncing ? null : _retryAllPending,
                    child: _syncing ? const Text('Retrying...') : const Text('Retry all'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _sales.isEmpty
                ? const Center(child: Text('No sales yet.'))
                : ListView.builder(
                    itemCount: _sales.length,
                    itemBuilder: (context, i) {
                      final s = _sales[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _statusColor(s.syncStatus),
                          child: Text('${s.quantity}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                        title: Text(s.eventTitle),
                        subtitle: Text(
                          '${s.isDayOfParking ? "Parking" : "Raffle"} · '
                          '${s.buyerFirstName} ${s.buyerLastName} · '
                          '${DateFormat.jm().format(s.createdAt)}\n'
                          '${_statusLabel(s.syncStatus)}'
                          '${s.ticketNumbersFormatted != null ? ' · #${s.ticketNumbersFormatted}' : ''}'
                          '${s.lastError != null && s.syncStatus != SyncStatus.synced ? '\n${s.lastError}' : ''}',
                        ),
                        isThreeLine: s.lastError != null && s.syncStatus != SyncStatus.synced,
                        trailing: s.syncStatus != SyncStatus.synced
                            ? IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: () => _retryOne(s),
                              )
                            : const Icon(Icons.check, color: Colors.green),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
