import 'raffle_event.dart';

/// In-progress sale, carried forward screen-to-screen as the staff member
/// works through Event → Quantity → Buyer Info → Payment.
class SaleDraft {
  final RaffleEvent event;
  int quantity;
  String buyerFirstName;
  String buyerLastName;
  String buyerPhone;
  String buyerEmail;

  SaleDraft({
    required this.event,
    this.quantity = 5,
    this.buyerFirstName = '',
    this.buyerLastName = '',
    this.buyerPhone = '',
    this.buyerEmail = '',
  });

  int get amountChargedCents => (event.ticketPrice * quantity * 100).round();
}
