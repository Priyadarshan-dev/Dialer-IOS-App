import 'package:hive/hive.dart';
import 'package:dialer_app_poc/features/call_history/domain/entities/call_history_entity.dart';

part 'call_history_model.g.dart';

@HiveType(typeId: 0)
class CallHistoryModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String contactName;
  
  @HiveField(2)
  final String phoneNumber;
  
  @HiveField(3)
  final DateTime callTime;
  
  @HiveField(4)
  final String? notes;
  
  @HiveField(5)
  final String status;

  CallHistoryModel({
    required this.id,
    required this.contactName,
    required this.phoneNumber,
    required this.callTime,
    this.notes,
    required this.status,
  });

  factory CallHistoryModel.fromEntity(CallHistoryEntity entity) {
    return CallHistoryModel(
      id: entity.id,
      contactName: entity.contactName,
      phoneNumber: entity.phoneNumber,
      callTime: entity.callTime,
      notes: entity.notes,
      status: entity.status,
    );
  }

  CallHistoryEntity toEntity() {
    return CallHistoryEntity(
      id: id,
      contactName: contactName,
      phoneNumber: phoneNumber,
      callTime: callTime,
      notes: notes,
      status: status,
    );
  }
}
