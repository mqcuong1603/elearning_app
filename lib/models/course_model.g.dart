// // GENERATED CODE - DO NOT MODIFY BY HAND

// part of 'course_model.dart';

// // **************************************************************************
// // TypeAdapterGenerator
// // **************************************************************************

// class CourseModelAdapter extends TypeAdapter<CourseModel> {
//   @override
//   final int typeId = 2;

//   @override
//   CourseModel read(BinaryReader reader) {
//     final numOfFields = reader.readByte();
//     final fields = <int, dynamic>{
//       for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
//     };
//     return CourseModel(
//       id: fields[0] as String,
//       code: fields[1] as String,
//       name: fields[2] as String,
//       semesterId: fields[3] as String,
//       sessions: fields[4] as int,
//       coverImageUrl: fields[5] as String?,
//       description: fields[6] as String?,
//       instructorId: fields[7] as String,
//       instructorName: fields[8] as String,
//       createdAt: fields[9] as DateTime,
//       updatedAt: fields[10] as DateTime,
//     );
//   }

//   @override
//   void write(BinaryWriter writer, CourseModel obj) {
//     writer
//       ..writeByte(11)
//       ..writeByte(0)
//       ..write(obj.id)
//       ..writeByte(1)
//       ..write(obj.code)
//       ..writeByte(2)
//       ..write(obj.name)
//       ..writeByte(3)
//       ..write(obj.semesterId)
//       ..writeByte(4)
//       ..write(obj.sessions)
//       ..writeByte(5)
//       ..write(obj.coverImageUrl)
//       ..writeByte(6)
//       ..write(obj.description)
//       ..writeByte(7)
//       ..write(obj.instructorId)
//       ..writeByte(8)
//       ..write(obj.instructorName)
//       ..writeByte(9)
//       ..write(obj.createdAt)
//       ..writeByte(10)
//       ..write(obj.updatedAt);
//   }

//   @override
//   int get hashCode => typeId.hashCode;

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is CourseModelAdapter &&
//           runtimeType == other.runtimeType &&
//           typeId == other.typeId;
// }
