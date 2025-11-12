// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announcement_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AnnouncementModelAdapter extends TypeAdapter<AnnouncementModel> {
  @override
  final int typeId = 4;

  @override
  AnnouncementModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AnnouncementModel(
      id: fields[0] as String,
      courseId: fields[1] as String,
      title: fields[2] as String,
      content: fields[3] as String,
      attachments: (fields[4] as List).cast<AttachmentModel>(),
      groupIds: (fields[5] as List).cast<String>(),
      instructorId: fields[6] as String,
      instructorName: fields[7] as String,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
      viewedBy: (fields[10] as List).cast<String>(),
      downloadedBy: (fields[11] as Map).map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as List).cast<String>())),
    );
  }

  @override
  void write(BinaryWriter writer, AnnouncementModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.courseId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.attachments)
      ..writeByte(5)
      ..write(obj.groupIds)
      ..writeByte(6)
      ..write(obj.instructorId)
      ..writeByte(7)
      ..write(obj.instructorName)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.viewedBy)
      ..writeByte(11)
      ..write(obj.downloadedBy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnnouncementModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AttachmentModelAdapter extends TypeAdapter<AttachmentModel> {
  @override
  final int typeId = 100;

  @override
  AttachmentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AttachmentModel(
      id: fields[0] as String,
      url: fields[1] as String,
      filename: fields[2] as String,
      size: fields[3] as int,
      type: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AttachmentModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.filename)
      ..writeByte(3)
      ..write(obj.size)
      ..writeByte(4)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttachmentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
