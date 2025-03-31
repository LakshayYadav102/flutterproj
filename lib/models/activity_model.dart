class Activity {
  final String id;
  final String userId;
  final DateTime fromDate;
  final DateTime toDate;
  final double transportation;
  final String diet;
  final double energy;
  final double totalEmission;

  Activity({
    required this.id,
    required this.userId,
    required this.fromDate,
    required this.toDate,
    required this.transportation,
    required this.diet,
    required this.energy,
    required this.totalEmission,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['_id'],
      userId: json['userId'],
      fromDate: DateTime.parse(json['fromDate']),
      toDate: DateTime.parse(json['toDate']),
      transportation: (json['transportation'] as num).toDouble(),
      diet: json['diet'],
      energy: (json['energy'] as num).toDouble(),
      totalEmission: (json['totalEmission'] as num).toDouble(),
    );
  }
}
