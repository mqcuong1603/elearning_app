// // GENERATED CODE - DO NOT MODIFY BY HAND

// part of 'group_model.dart';

// // **************************************************************************
// // TypeAdapterGenerator
// // **************************************************************************

// class GroupModelAdapter extends TypeAdapter<GroupModel> {
//   @override
//   final int typeId = 3;

//   @override
//   GroupModel read(BinaryReader reader) {
//     final numOfFields = reader.readByte();
//     final fields = <int, dynamic>{
//       for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
//     };
//     return GroupModel(
//       id: fields[0] as String,
//       name: fields[1] as String,
//       courseId: fields[2] as String,
//       studentIds: (fields[3] as List).cast<String>(),
//       createdAt: fields[4] as DateTime,
//       updatedAt: fields[5] as DateTime,
//     );
//   }

//   @override
//   void write(BinaryWriter writer, GroupModel obj) {
//     writer
//       ..writeByte(6)
//       ..writeByte(0)
//       ..write(obj.id)
//       ..writeByte(1)
//       ..write(obj.name)
//       ..writeByte(2)
//       ..write(obj.courseId)
//       ..writeByte(3)
//       ..write(obj.studentIds)
//       ..writeByte(4)
//       ..write(obj.createdAt)
//       ..writeByte(5)
//       ..write(obj.updatedAt);
//   }

//   @override
//   int get hashCode => typeId.hashCode;

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is GroupModelAdapter &&
//           runtimeType == other.runtimeType &&
//           typeId == other.typeId;
// }
