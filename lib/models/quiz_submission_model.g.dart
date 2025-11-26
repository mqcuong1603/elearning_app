// // GENERATED CODE - DO NOT MODIFY BY HAND

// part of 'quiz_submission_model.dart';

// // **************************************************************************
// // TypeAdapterGenerator
// // **************************************************************************

// class QuizSubmissionModelAdapter extends TypeAdapter<QuizSubmissionModel> {
//   @override
//   final int typeId = 9;

//   @override
//   QuizSubmissionModel read(BinaryReader reader) {
//     final numOfFields = reader.readByte();
//     final fields = <int, dynamic>{
//       for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
//     };
//     return QuizSubmissionModel(
//       id: fields[0] as String,
//       quizId: fields[1] as String,
//       studentId: fields[2] as String,
//       studentName: fields[3] as String,
//       answers: (fields[4] as List).cast<QuizAnswerModel>(),
//       score: fields[5] as double,
//       submittedAt: fields[6] as DateTime,
//       attemptNumber: fields[7] as int,
//       startedAt: fields[8] as DateTime,
//       durationSeconds: fields[9] as int,
//     );
//   }

//   @override
//   void write(BinaryWriter writer, QuizSubmissionModel obj) {
//     writer
//       ..writeByte(10)
//       ..writeByte(0)
//       ..write(obj.id)
//       ..writeByte(1)
//       ..write(obj.quizId)
//       ..writeByte(2)
//       ..write(obj.studentId)
//       ..writeByte(3)
//       ..write(obj.studentName)
//       ..writeByte(4)
//       ..write(obj.answers)
//       ..writeByte(5)
//       ..write(obj.score)
//       ..writeByte(6)
//       ..write(obj.submittedAt)
//       ..writeByte(7)
//       ..write(obj.attemptNumber)
//       ..writeByte(8)
//       ..write(obj.startedAt)
//       ..writeByte(9)
//       ..write(obj.durationSeconds);
//   }

//   @override
//   int get hashCode => typeId.hashCode;

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is QuizSubmissionModelAdapter &&
//           runtimeType == other.runtimeType &&
//           typeId == other.typeId;
// }

// class QuizAnswerModelAdapter extends TypeAdapter<QuizAnswerModel> {
//   @override
//   final int typeId = 102;

//   @override
//   QuizAnswerModel read(BinaryReader reader) {
//     final numOfFields = reader.readByte();
//     final fields = <int, dynamic>{
//       for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
//     };
//     return QuizAnswerModel(
//       questionId: fields[0] as String,
//       selectedChoiceId: fields[1] as String,
//       isCorrect: fields[2] as bool,
//     );
//   }

//   @override
//   void write(BinaryWriter writer, QuizAnswerModel obj) {
//     writer
//       ..writeByte(3)
//       ..writeByte(0)
//       ..write(obj.questionId)
//       ..writeByte(1)
//       ..write(obj.selectedChoiceId)
//       ..writeByte(2)
//       ..write(obj.isCorrect);
//   }

//   @override
//   int get hashCode => typeId.hashCode;

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is QuizAnswerModelAdapter &&
//           runtimeType == other.runtimeType &&
//           typeId == other.typeId;
// }
