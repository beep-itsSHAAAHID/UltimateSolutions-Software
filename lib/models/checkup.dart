class DailySales {
  final String userId; // ID of the user (admin or salesman)
  final double startingOdometer;
  final String startingLocation;

  DailySales({
    required this.userId,
    required this.startingOdometer,
    required this.startingLocation,
  });
}
