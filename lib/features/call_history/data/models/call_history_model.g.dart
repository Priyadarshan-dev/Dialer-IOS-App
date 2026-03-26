// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_history_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CallHistoryModelAdapter extends TypeAdapter<CallHistoryModel> {
  @override
  final int typeId = 0;

  @override
  CallHistoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CallHistoryModel(
      id: fields[0] as String,
      contactName: fields[1] as String,
      phoneNumber: fields[2] as String,
      callTime: fields[3] as DateTime,
      notes: fields[4] as String?,
      status: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CallHistoryModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.contactName)
      ..writeByte(2)
      ..write(obj.phoneNumber)
      ..writeByte(3)
      ..write(obj.callTime)
      ..writeByte(4)
      ..write(obj.notes)
      ..writeByte(5)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallHistoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
