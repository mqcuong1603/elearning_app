// // GENERATED CODE - DO NOT MODIFY BY HAND

// part of 'assignment_model.dart';

// // **************************************************************************
// // TypeAdapterGenerator
// // **************************************************************************

// class AssignmentModelAdapter extends TypeAdapter<AssignmentModel> {
//   @override
//   final int typeId = 5;

//   @override
//   AssignmentModel read(BinaryReader reader) {
//     final numOfFields = reader.readByte();
//     final fields = <int, dynamic>{
//       for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
//     };
//     return AssignmentModel(
//       id: fields[0] as String,
//       courseId: fields[1] as String,
//       title: fields[2] as String,
//       description: fields[3] as String,
//       attachments: (fields[4] as List).cast<AttachmentModel>(),
//       startDate: fields[5] as DateTime,
//       deadline: fields[6] as DateTime,
//       allowLateSubmission: fields[7] as bool,
//       lateDeadline: fields[8] as DateTime?,
//       maxAttempts: fields[9] as int,
//       allowedFileFormats: (fields[10] as List).cast<String>(),
//       maxFileSize: fields[11] as int,
//       groupIds: (fields[12] as List).cast<String>(),
//       instructorId: fields[13] as String,
//       instructorName: fields[14] as String,
//       createdAt: fields[15] as DateTime,
//       updatedAt: fields[16] as DateTime,
//     );
//   }

//   @override
//   void write(BinaryWriter writer, AssignmentModel obj) {
//     writer
//       ..writeByte(17)
//       ..writeByte(0)
//       ..write(obj.id)
//       ..writeByte(1)
//       ..write(obj.courseId)
//       ..writeByte(2)
//       ..write(obj.title)
//       ..writeByte(3)
//       ..write(obj.description)
//       ..writeByte(4)
//       ..write(obj.attachments)
//       ..writeByte(5)
//       ..write(obj.startDate)
//       ..writeByte(6)
//       ..write(obj.deadline)
//       ..writeByte(7)
//       ..write(obj.allowLateSubmission)
//       ..writeByte(8)
//       ..write(obj.lateDeadline)
//       ..writeByte(9)
//       ..write(obj.maxAttempts)
//       ..writeByte(10)
//       ..write(obj.allowedFileFormats)
//       ..writeByte(11)
//       ..write(obj.maxFileSize)
//       ..writeByte(12)
//       ..write(obj.groupIds)
//       ..writeByte(13)
//       ..write(obj.instructorId)
//       ..writeByte(14)
//       ..write(obj.instructorName)
//       ..writeByte(15)
//       ..write(obj.createdAt)
//       ..writeByte(16)
//       ..write(obj.updatedAt);
//   }

//   @override
//   int get hashCode => typeId.hashCode;

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is AssignmentModelAdapter &&
//           runtimeType == other.runtimeType &&
//           typeId == other.typeId;
// }
