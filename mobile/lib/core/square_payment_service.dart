import 'package:square_mobile_payments_sdk/square_mobile_payments_sdk.dart';
import 'package:uuid/uuid.dart';
import 'api_client.dart';

class SquarePaymentException implements Exception {
  final String message;
  SquarePaymentException(this.message);

  @override
  String toString() => message;
}

/// Thin wrapper around the Square Mobile Payments SDK. Owns the
/// authorize-before-charging dance so screens never touch the SDK directly.
class SquarePaymentService {
  final SquareMobilePaymentsSdk _sdk = SquareMobilePaymentsSdk();
  final ApiClient _api = ApiClient();
  final Uuid _uuid = const Uuid();

  /// Authorizes against Square if not already authorized this session.
  /// Fetches a fresh one-time code from our server each time — the code
  /// expires in 60 minutes and is single-use, so there's no point caching it.
  Future<void> ensureAuthorized() async {
    final state = await _sdk.authManager.getAuthorizationState();
    if (state == AuthorizationState.authorized) return;

    final auth = await _api.getMobileAuth();
    await _sdk.authManager.authorize(auth.authorizationCode, auth.locationId);
  }

  /// Prompts the buyer to tap their card and returns the real Square payment
  /// ID once the charge succeeds. Throws [SquarePaymentException] if the SDK
  /// reports anything other than success — callers should NOT record a local
  /// sale on failure, unlike a successful charge which must be recorded
  /// before any network call.
  Future<String> charge({required int amountCents}) async {
    await ensureAuthorized();

    final paymentAttemptId = _uuid.v4();

    final Payment payment = await _sdk.paymentManager.startPayment(
      PaymentParameters(
        amountMoney: Money(amount: amountCents, currencyCode: CurrencyCode.usd),
        paymentAttemptId: paymentAttemptId,
        processingMode: ProcessingMode.autoDetect,
        allowCardSurcharge: false,
      ),
      const PromptParameters(
        additionalPaymentMethods: [],
        mode: PromptMode.defaultMode,
      ),
    );

    final paymentId = payment.id;
    if (paymentId == null || paymentId.isEmpty) {
      throw SquarePaymentException('Square reported success but returned no payment ID.');
    }
    return paymentId;
  }
}
