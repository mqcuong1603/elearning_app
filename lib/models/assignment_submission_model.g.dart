// // GENERATED CODE - DO NOT MODIFY BY HAND

// part of 'assignment_submission_model.dart';

// // **************************************************************************
// // TypeAdapterGenerator
// // **************************************************************************

// class AssignmentSubmissionModelAdapter
//     extends TypeAdapter<AssignmentSubmissionModel> {
//   @override
//   final int typeId = 6;

//   @override
//   AssignmentSubmissionModel read(BinaryReader reader) {
//     final numOfFields = reader.readByte();
//     final fields = <int, dynamic>{
//       for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
//     };
//     return AssignmentSubmissionModel(
//       id: fields[0] as String,
//       assignmentId: fields[1] as String,
//       studentId: fields[2] as String,
//       studentName: fields[3] as String,
//       files: (fields[4] as List).cast<AttachmentModel>(),
//       attemptNumber: fields[5] as int,
//       submittedAt: fields[6] as DateTime,
//       isLate: fields[7] as bool,
//       grade: fields[8] as double?,
//       feedback: fields[9] as String?,
//       gradedAt: fields[10] as DateTime?,
//       gradedBy: fields[11] as String?,
//     );
//   }

//   @override
//   void write(BinaryWriter writer, AssignmentSubmissionModel obj) {
//     writer
//       ..writeByte(12)
//       ..writeByte(0)
//       ..write(obj.id)
//       ..writeByte(1)
//       ..write(obj.assignmentId)
//       ..writeByte(2)
//       ..write(obj.studentId)
//       ..writeByte(3)
//       ..write(obj.studentName)
//       ..writeByte(4)
//       ..write(obj.files)
//       ..writeByte(5)
//       ..write(obj.attemptNumber)
//       ..writeByte(6)
//       ..write(obj.submittedAt)
//       ..writeByte(7)
//       ..write(obj.isLate)
//       ..writeByte(8)
//       ..write(obj.grade)
//       ..writeByte(9)
//       ..write(obj.feedback)
//       ..writeByte(10)
//       ..write(obj.gradedAt)
//       ..writeByte(11)
//       ..write(obj.gradedBy);
//   }

//   @override
//   int get hashCode => typeId.hashCode;

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is AssignmentSubmissionModelAdapter &&
//           runtimeType == other.runtimeType &&
//           typeId == other.typeId;
// }
