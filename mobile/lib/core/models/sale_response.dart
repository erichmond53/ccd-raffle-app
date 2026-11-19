class SaleResponse {
  final bool success;
  final bool alreadyExisted;
  final int orderId;
  final int eventId;
  final String saleType;
  final int quantity;
  // Raffle-only — null/empty for a day-of parking sale.
  final List<int> ticketNumbers;
  final String? ticketNumbersFormatted;
  final double? potValue;

  SaleResponse({
    required this.success,
    required this.alreadyExisted,
    required this.orderId,
    required this.eventId,
    required this.saleType,
    required this.quantity,
    required this.ticketNumbers,
    this.ticketNumbersFormatted,
    this.potValue,
  });

  factory SaleResponse.fromJson(Map<String, dynamic> json) {
    return SaleResponse(
      success: json['success'] as bool,
      alreadyExisted: json['already_existed'] as bool,
      orderId: json['order_id'] as int,
      eventId: json['event_id'] as int,
      saleType: json['sale_type'] as String? ?? 'raffle',
      quantity: json['quantity'] as int,
      ticketNumbers: (json['ticket_numbers'] as List?)?.map((e) => e as int).toList() ?? const [],
      ticketNumbersFormatted: json['ticket_numbers_formatted'] as String?,
      potValue: (json['pot_value'] as num?)?.toDouble(),
    );
  }
}

/// Thrown by [ApiClient] on any non-2xx response.
///
/// [isTransient] mirrors the server's documented 4xx-vs-5xx contract:
/// 401/400/409 are permanent (don't retry, surface to staff), 5xx is transient
/// (keep retrying with backoff). See docs/api-contract.md for the full table.
class ApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;
  final bool isTransient;

  ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    required this.isTransient,
  });

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}
