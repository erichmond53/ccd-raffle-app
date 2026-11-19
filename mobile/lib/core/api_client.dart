import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'models/raffle_event.dart';
import 'models/sale_response.dart';

class ApiClient {
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-CCD-Raffle-App-Key': ApiConfig.apiKey,
      };

  /// Upcoming, raffle-enabled, still-sellable events. Always fetch fresh —
  /// never cache across app sessions (an event can stop being sellable at
  /// any moment: raffle disabled, event ended, or a winner picked).
  Future<List<RaffleEvent>> getEvents() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/events');
    final res = await http.get(uri, headers: _headers);

    if (res.statusCode != 200) {
      throw _exceptionFor(res);
    }

    final list = jsonDecode(res.body) as List;
    return list.map((e) => RaffleEvent.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Records one completed Square charge. Safe to call twice with the same
  /// [squarePaymentId] — the server returns the identical result both times
  /// rather than creating a duplicate order.
  Future<SaleResponse> postSale({
    required int eventId,
    required int quantity,
    required String buyerFirstName,
    required String buyerLastName,
    required String buyerPhone,
    required String buyerEmail,
    required String squarePaymentId,
    required int amountChargedCents,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/sales');
    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'event_id': eventId,
        'quantity': quantity,
        'buyer_first_name': buyerFirstName,
        'buyer_last_name': buyerLastName,
        'buyer_phone': buyerPhone,
        'buyer_email': buyerEmail,
        'square_payment_id': squarePaymentId,
        'amount_charged_cents': amountChargedCents,
        'device_id': ApiConfig.deviceId,
      }),
    );

    if (res.statusCode != 200) {
      throw _exceptionFor(res);
    }

    return SaleResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  ApiException _exceptionFor(http.Response res) {
    String code = 'unknown_error';
    String message = res.body;
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      code = (body['code'] as String?) ?? code;
      message = (body['message'] as String?) ?? message;
    } catch (_) {
      // Non-JSON error body (e.g. a raw 502 from the server) — treat as transient below.
    }

    return ApiException(
      statusCode: res.statusCode,
      code: code,
      message: message,
      isTransient: res.statusCode >= 500,
    );
  }
}
