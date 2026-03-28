import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'app_contact_model.g.dart';

@HiveType(typeId: 2)
class AppContactModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String phoneNumber;

  @HiveField(3)
  final String notes;

  AppContactModel({
    required this.name,
    required this.phoneNumber,
    required this.notes,
    String? id,
  }) : this.id = id ?? const Uuid().v4();
}
