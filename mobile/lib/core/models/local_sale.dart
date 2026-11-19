enum SyncStatus { pending, synced, failedPermanent }

SyncStatus syncStatusFromString(String s) {
  switch (s) {
    case 'synced':
      return SyncStatus.synced;
    case 'failed_permanent':
      return SyncStatus.failedPermanent;
    default:
      return SyncStatus.pending;
  }
}

String syncStatusToString(SyncStatus s) {
  switch (s) {
    case SyncStatus.synced:
      return 'synced';
    case SyncStatus.failedPermanent:
      return 'failed_permanent';
    case SyncStatus.pending:
      return 'pending';
  }
}

/// A raffle-ticket sale recorded on the device. Written the moment the payment
/// succeeds, before the WordPress sync call is even attempted — this row is the
/// proof money was taken. The sync call is best-effort on top, never the reverse.
class LocalSale {
  final int? id;
  final String squarePaymentId;
  final int eventId;
  final String eventTitle;
  final int quantity;
  final String buyerFirstName;
  final String buyerLastName;
  final String buyerPhone;
  final String buyerEmail;
  final int amountChargedCents;
  final DateTime createdAt;
  final SyncStatus syncStatus;
  final int? orderId;
  final String? ticketNumbersFormatted;
  final double? potValue;
  final String? lastError;
  final int retryCount;

  LocalSale({
    this.id,
    required this.squarePaymentId,
    required this.eventId,
    required this.eventTitle,
    required this.quantity,
    required this.buyerFirstName,
    required this.buyerLastName,
    required this.buyerPhone,
    required this.buyerEmail,
    required this.amountChargedCents,
    required this.createdAt,
    this.syncStatus = SyncStatus.pending,
    this.orderId,
    this.ticketNumbersFormatted,
    this.potValue,
    this.lastError,
    this.retryCount = 0,
  });

  LocalSale copyWith({
    SyncStatus? syncStatus,
    int? orderId,
    String? ticketNumbersFormatted,
    double? potValue,
    String? lastError,
    int? retryCount,
  }) {
    return LocalSale(
      id: id,
      squarePaymentId: squarePaymentId,
      eventId: eventId,
      eventTitle: eventTitle,
      quantity: quantity,
      buyerFirstName: buyerFirstName,
      buyerLastName: buyerLastName,
      buyerPhone: buyerPhone,
      buyerEmail: buyerEmail,
      amountChargedCents: amountChargedCents,
      createdAt: createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
      orderId: orderId ?? this.orderId,
      ticketNumbersFormatted: ticketNumbersFormatted ?? this.ticketNumbersFormatted,
      potValue: potValue ?? this.potValue,
      lastError: lastError ?? this.lastError,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  Map<String, dynamic> toDb() {
    return {
      'id': id,
      'square_payment_id': squarePaymentId,
      'event_id': eventId,
      'event_title': eventTitle,
      'quantity': quantity,
      'buyer_first_name': buyerFirstName,
      'buyer_last_name': buyerLastName,
      'buyer_phone': buyerPhone,
      'buyer_email': buyerEmail,
      'amount_charged_cents': amountChargedCents,
      'created_at': createdAt.toIso8601String(),
      'sync_status': syncStatusToString(syncStatus),
      'order_id': orderId,
      'ticket_numbers_formatted': ticketNumbersFormatted,
      'pot_value': potValue,
      'last_error': lastError,
      'retry_count': retryCount,
    };
  }

  factory LocalSale.fromDb(Map<String, dynamic> row) {
    return LocalSale(
      id: row['id'] as int?,
      squarePaymentId: row['square_payment_id'] as String,
      eventId: row['event_id'] as int,
      eventTitle: row['event_title'] as String,
      quantity: row['quantity'] as int,
      buyerFirstName: row['buyer_first_name'] as String,
      buyerLastName: row['buyer_last_name'] as String,
      buyerPhone: row['buyer_phone'] as String,
      buyerEmail: row['buyer_email'] as String,
      amountChargedCents: row['amount_charged_cents'] as int,
      createdAt: DateTime.parse(row['created_at'] as String),
      syncStatus: syncStatusFromString(row['sync_status'] as String),
      orderId: row['order_id'] as int?,
      ticketNumbersFormatted: row['ticket_numbers_formatted'] as String?,
      potValue: (row['pot_value'] as num?)?.toDouble(),
      lastError: row['last_error'] as String?,
      retryCount: row['retry_count'] as int? ?? 0,
    );
  }
}
