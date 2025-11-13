// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forum_topic_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ForumTopicModelAdapter extends TypeAdapter<ForumTopicModel> {
  @override
  final int typeId = 11;

  @override
  ForumTopicModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ForumTopicModel(
      id: fields[0] as String,
      courseId: fields[1] as String,
      title: fields[2] as String,
      content: fields[3] as String,
      authorId: fields[4] as String,
      authorName: fields[5] as String,
      authorRole: fields[6] as String,
      attachments: (fields[7] as List).cast<AttachmentModel>(),
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
      replyCount: fields[10] as int,
      isPinned: fields[11] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ForumTopicModel obj) {
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
      ..write(obj.authorId)
      ..writeByte(5)
      ..write(obj.authorName)
      ..writeByte(6)
      ..write(obj.authorRole)
      ..writeByte(7)
      ..write(obj.attachments)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.replyCount)
      ..writeByte(11)
      ..write(obj.isPinned);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForumTopicModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
