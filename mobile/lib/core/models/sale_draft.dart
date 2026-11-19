import 'raffle_event.dart';

enum SaleType { raffle, dayOfParking }

String saleTypeToApiString(SaleType t) => t == SaleType.dayOfParking ? 'dayof_parking' : 'raffle';

/// In-progress sale, carried forward screen-to-screen as the staff member
/// works through Event → (Sale Type) → Quantity → Buyer Info → Payment.
class SaleDraft {
  final RaffleEvent event;
  SaleType saleType;
  int quantity;
  String buyerFirstName;
  String buyerLastName;
  String buyerPhone;
  String buyerEmail;

  SaleDraft({
    required this.event,
    this.saleType = SaleType.raffle,
    this.quantity = 5,
    this.buyerFirstName = '',
    this.buyerLastName = '',
    this.buyerPhone = '',
    this.buyerEmail = '',
  });

  double get unitPrice => saleType == SaleType.dayOfParking ? (event.dayofPrice ?? 0) : event.ticketPrice;

  int get amountChargedCents => (unitPrice * quantity * 100).round();
}
