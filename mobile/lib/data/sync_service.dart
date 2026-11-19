import '../core/api_client.dart';
import '../core/models/local_sale.dart';
import '../core/models/sale_response.dart';
import 'local_sales_db.dart';

/// Pushes pending local sales to WordPress. Never re-invokes Square — a
/// [LocalSale] is only ever retried against the WordPress endpoint, because
/// the money was already taken the moment the row was written.
class SyncService {
  final ApiClient _api = ApiClient();
  final LocalSalesDb _db = LocalSalesDb.instance;

  /// Attempts to sync every pending sale. Returns the number that moved to
  /// `synced`. Sales that hit a permanent (4xx) failure become
  /// `failed_permanent` and stop being retried automatically.
  Future<int> syncPending() async {
    final pending = await _db.pending();
    var succeeded = 0;

    for (final sale in pending) {
      final ok = await syncOne(sale);
      if (ok) succeeded++;
    }

    return succeeded;
  }

  /// Syncs a single sale. Returns true if it ended up `synced`.
  Future<bool> syncOne(LocalSale sale) async {
    try {
      final SaleResponse res = await _api.postSale(
        eventId: sale.eventId,
        saleType: sale.saleType,
        quantity: sale.quantity,
        buyerFirstName: sale.buyerFirstName,
        buyerLastName: sale.buyerLastName,
        buyerPhone: sale.buyerPhone,
        buyerEmail: sale.buyerEmail,
        squarePaymentId: sale.squarePaymentId,
        amountChargedCents: sale.amountChargedCents,
      );

      await _db.update(sale.copyWith(
        syncStatus: SyncStatus.synced,
        orderId: res.orderId,
        ticketNumbersFormatted: res.ticketNumbersFormatted,
        potValue: res.potValue,
        lastError: null,
      ));
      return true;
    } on ApiException catch (e) {
      if (e.isTransient) {
        // Stays pending — will be retried on the next sync pass.
        await _db.update(sale.copyWith(
          retryCount: sale.retryCount + 1,
          lastError: '${e.code}: ${e.message}',
        ));
        return false;
      } else {
        // Permanent failure (4xx) — money's already taken, needs human eyes.
        await _db.update(sale.copyWith(
          syncStatus: SyncStatus.failedPermanent,
          lastError: '${e.code}: ${e.message}',
        ));
        return false;
      }
    } catch (e) {
      // Network error (offline, timeout, DNS, etc.) — treat as transient.
      await _db.update(sale.copyWith(
        retryCount: sale.retryCount + 1,
        lastError: e.toString(),
      ));
      return false;
    }
  }
}
