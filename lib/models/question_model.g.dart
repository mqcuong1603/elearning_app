// // GENERATED CODE - DO NOT MODIFY BY HAND

// part of 'question_model.dart';

// // **************************************************************************
// // TypeAdapterGenerator
// // **************************************************************************

// class QuestionModelAdapter extends TypeAdapter<QuestionModel> {
//   @override
//   final int typeId = 8;

//   @override
//   QuestionModel read(BinaryReader reader) {
//     final numOfFields = reader.readByte();
//     final fields = <int, dynamic>{
//       for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
//     };
//     return QuestionModel(
//       id: fields[0] as String,
//       courseId: fields[1] as String,
//       questionText: fields[2] as String,
//       choices: (fields[3] as List).cast<ChoiceModel>(),
//       difficulty: fields[4] as String,
//       createdAt: fields[5] as DateTime,
//       updatedAt: fields[6] as DateTime,
//     );
//   }

//   @override
//   void write(BinaryWriter writer, QuestionModel obj) {
//     writer
//       ..writeByte(7)
//       ..writeByte(0)
//       ..write(obj.id)
//       ..writeByte(1)
//       ..write(obj.courseId)
//       ..writeByte(2)
//       ..write(obj.questionText)
//       ..writeByte(3)
//       ..write(obj.choices)
//       ..writeByte(4)
//       ..write(obj.difficulty)
//       ..writeByte(5)
//       ..write(obj.createdAt)
//       ..writeByte(6)
//       ..write(obj.updatedAt);
//   }

//   @override
//   int get hashCode => typeId.hashCode;

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is QuestionModelAdapter &&
//           runtimeType == other.runtimeType &&
//           typeId == other.typeId;
// }

// class ChoiceModelAdapter extends TypeAdapter<ChoiceModel> {
//   @override
//   final int typeId = 101;

//   @override
//   ChoiceModel read(BinaryReader reader) {
//     final numOfFields = reader.readByte();
//     final fields = <int, dynamic>{
//       for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
//     };
//     return ChoiceModel(
//       id: fields[0] as String,
//       text: fields[1] as String,
//       isCorrect: fields[2] as bool,
//     );
//   }

//   @override
//   void write(BinaryWriter writer, ChoiceModel obj) {
//     writer
//       ..writeByte(3)
//       ..writeByte(0)
//       ..write(obj.id)
//       ..writeByte(1)
//       ..write(obj.text)
//       ..writeByte(2)
//       ..write(obj.isCorrect);
//   }

//   @override
//   int get hashCode => typeId.hashCode;

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is ChoiceModelAdapter &&
//           runtimeType == other.runtimeType &&
//           typeId == other.typeId;
// }
