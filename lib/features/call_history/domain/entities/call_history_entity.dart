class CallHistoryEntity {
  final String id;
  final String contactName;
  final String phoneNumber;
  final DateTime callTime;
  final String? notes;
  final String status;

  CallHistoryEntity({
    required this.id,
    required this.contactName,
    required this.phoneNumber,
    required this.callTime,
    this.notes,
    required this.status,
  });

  CallHistoryEntity copyWith({
    String? id,
    String? contactName,
    String? phoneNumber,
    DateTime? callTime,
    String? notes,
    String? status,
  }) {
    return CallHistoryEntity(
      id: id ?? this.id,
      contactName: contactName ?? this.contactName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      callTime: callTime ?? this.callTime,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }
}
