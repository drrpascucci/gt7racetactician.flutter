class Gt7WheelValues {
  const Gt7WheelValues({
    required this.frontLeft,
    required this.frontRight,
    required this.rearLeft,
    required this.rearRight,
    this.isEmpty = false,
  });

  final double frontLeft;
  final double frontRight;
  final double rearLeft;
  final double rearRight;
  final bool isEmpty;
}
