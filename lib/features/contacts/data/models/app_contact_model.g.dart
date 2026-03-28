// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_contact_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppContactModelAdapter extends TypeAdapter<AppContactModel> {
  @override
  final int typeId = 2;

  @override
  AppContactModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppContactModel(
      name: fields[1] as String,
      phoneNumber: fields[2] as String,
      notes: fields[3] as String,
      id: fields[0] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AppContactModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.phoneNumber)
      ..writeByte(3)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppContactModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
