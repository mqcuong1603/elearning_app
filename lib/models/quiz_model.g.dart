// // GENERATED CODE - DO NOT MODIFY BY HAND

// part of 'quiz_model.dart';

// // **************************************************************************
// // TypeAdapterGenerator
// // **************************************************************************

// class QuizModelAdapter extends TypeAdapter<QuizModel> {
//   @override
//   final int typeId = 7;

//   @override
//   QuizModel read(BinaryReader reader) {
//     final numOfFields = reader.readByte();
//     final fields = <int, dynamic>{
//       for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
//     };
//     return QuizModel(
//       id: fields[0] as String,
//       courseId: fields[1] as String,
//       title: fields[2] as String,
//       description: fields[3] as String,
//       openDate: fields[4] as DateTime,
//       closeDate: fields[5] as DateTime,
//       durationMinutes: fields[6] as int,
//       maxAttempts: fields[7] as int,
//       questionStructure: (fields[8] as Map).cast<String, int>(),
//       groupIds: (fields[9] as List).cast<String>(),
//       instructorId: fields[10] as String,
//       instructorName: fields[11] as String,
//       createdAt: fields[12] as DateTime,
//       updatedAt: fields[13] as DateTime,
//     );
//   }

//   @override
//   void write(BinaryWriter writer, QuizModel obj) {
//     writer
//       ..writeByte(14)
//       ..writeByte(0)
//       ..write(obj.id)
//       ..writeByte(1)
//       ..write(obj.courseId)
//       ..writeByte(2)
//       ..write(obj.title)
//       ..writeByte(3)
//       ..write(obj.description)
//       ..writeByte(4)
//       ..write(obj.openDate)
//       ..writeByte(5)
//       ..write(obj.closeDate)
//       ..writeByte(6)
//       ..write(obj.durationMinutes)
//       ..writeByte(7)
//       ..write(obj.maxAttempts)
//       ..writeByte(8)
//       ..write(obj.questionStructure)
//       ..writeByte(9)
//       ..write(obj.groupIds)
//       ..writeByte(10)
//       ..write(obj.instructorId)
//       ..writeByte(11)
//       ..write(obj.instructorName)
//       ..writeByte(12)
//       ..write(obj.createdAt)
//       ..writeByte(13)
//       ..write(obj.updatedAt);
//   }

//   @override
//   int get hashCode => typeId.hashCode;

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is QuizModelAdapter &&
//           runtimeType == other.runtimeType &&
//           typeId == other.typeId;
// }
