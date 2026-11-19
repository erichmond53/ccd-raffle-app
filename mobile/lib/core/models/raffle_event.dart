class RaffleEvent {
  final int eventId;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final double ticketPrice;
  final double potValue;
  final int ticketsSold;

  RaffleEvent({
    required this.eventId,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.ticketPrice,
    required this.potValue,
    required this.ticketsSold,
  });

  factory RaffleEvent.fromJson(Map<String, dynamic> json) {
    return RaffleEvent(
      eventId: json['event_id'] as int,
      title: json['title'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      ticketPrice: (json['ticket_price'] as num).toDouble(),
      potValue: (json['pot_value'] as num).toDouble(),
      ticketsSold: json['tickets_sold'] as int,
    );
  }
}
