class SentPayrollSlip {
  final String employeeId;
  final String employeeName;
  final int month;
  final int year;
  final DateTime sentAt;
  final int totalGaji;

  const SentPayrollSlip({
    required this.employeeId,
    required this.employeeName,
    required this.month,
    required this.year,
    required this.sentAt,
    required this.totalGaji,
  });
}
