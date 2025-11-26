// // GENERATED CODE - DO NOT MODIFY BY HAND

// part of 'semester_model.dart';

// // **************************************************************************
// // TypeAdapterGenerator
// // **************************************************************************

// class SemesterModelAdapter extends TypeAdapter<SemesterModel> {
//   @override
//   final int typeId = 1;

//   @override
//   SemesterModel read(BinaryReader reader) {
//     final numOfFields = reader.readByte();
//     final fields = <int, dynamic>{
//       for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
//     };
//     return SemesterModel(
//       id: fields[0] as String,
//       code: fields[1] as String,
//       name: fields[2] as String,
//       createdAt: fields[3] as DateTime,
//       updatedAt: fields[4] as DateTime,
//       isCurrent: fields[5] as bool,
//     );
//   }

//   @override
//   void write(BinaryWriter writer, SemesterModel obj) {
//     writer
//       ..writeByte(6)
//       ..writeByte(0)
//       ..write(obj.id)
//       ..writeByte(1)
//       ..write(obj.code)
//       ..writeByte(2)
//       ..write(obj.name)
//       ..writeByte(3)
//       ..write(obj.createdAt)
//       ..writeByte(4)
//       ..write(obj.updatedAt)
//       ..writeByte(5)
//       ..write(obj.isCurrent);
//   }

//   @override
//   int get hashCode => typeId.hashCode;

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is SemesterModelAdapter &&
//           runtimeType == other.runtimeType &&
//           typeId == other.typeId;
// }
