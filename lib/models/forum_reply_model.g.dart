// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forum_reply_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ForumReplyModelAdapter extends TypeAdapter<ForumReplyModel> {
  @override
  final int typeId = 12;

  @override
  ForumReplyModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ForumReplyModel(
      id: fields[0] as String,
      topicId: fields[1] as String,
      content: fields[2] as String,
      authorId: fields[3] as String,
      authorName: fields[4] as String,
      authorRole: fields[5] as String,
      attachments: (fields[6] as List).cast<AttachmentModel>(),
      parentReplyId: fields[7] as String?,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ForumReplyModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.topicId)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.authorId)
      ..writeByte(4)
      ..write(obj.authorName)
      ..writeByte(5)
      ..write(obj.authorRole)
      ..writeByte(6)
      ..write(obj.attachments)
      ..writeByte(7)
      ..write(obj.parentReplyId)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForumReplyModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
