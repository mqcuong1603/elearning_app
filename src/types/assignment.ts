export interface Assignment {
  id: string;
  courseId: string;
  title: string;
  description: string;
  instructions: string;

  // Timing settings
  startDate: Date;
  dueDate: Date;
  allowLateSubmission: boolean;
  latePenaltyPercentage?: number; // Penalty per day late
  cutoffDate?: Date; // Hard deadline if late submissions allowed

  // Attempt settings
  maxAttempts: number; // 0 = unlimited

  // File settings
  allowedFileTypes: string[]; // e.g., ['.pdf', '.docx', '.jpg']
  maxFileSize: number; // in MB
  maxFiles: number;

  // Grading
  totalPoints: number;

  // Group scoping
  groupIds: string[]; // Empty array = all students in course

  // Attachments (instructor provided files/images)
  attachments: AssignmentAttachment[];

  // Metadata
  createdAt: Date;
  updatedAt: Date;
  createdBy: string; // instructor user ID
  published: boolean;
}

export interface AssignmentAttachment {
  id: string;
  name: string;
  url: string;
  type: string; // MIME type
  size: number; // in bytes
  uploadedAt: Date;
}

export interface Submission {
  id: string;
  assignmentId: string;
  courseId: string;
  studentId: string;
  attemptNumber: number;

  // Submission content
  files: SubmissionFile[];
  text?: string; // Optional text submission

  // Status
  submittedAt: Date;
  isLate: boolean;

  // Grading
  status: 'submitted' | 'graded' | 'returned';
  grade?: number;
  feedback?: string;
  gradedAt?: Date;
  gradedBy?: string; // instructor user ID

  // Metadata
  updatedAt: Date;
}

export interface SubmissionFile {
  id: string;
  name: string;
  url: string;
  type: string; // MIME type
  size: number; // in bytes
  uploadedAt: Date;
}

// For tracking dashboard
export interface SubmissionSummary {
  assignmentId: string;
  totalStudents: number;
  submitted: number;
  notSubmitted: number;
  graded: number;
  lateSubmissions: number;
  averageGrade?: number;
}

export interface StudentSubmissionStatus {
  studentId: string;
  studentName: string;
  studentEmail: string;
  hasSubmitted: boolean;
  attemptCount: number;
  latestSubmission?: Submission;
  isLate: boolean;
  grade?: number;
  status: 'not_submitted' | 'submitted' | 'graded' | 'returned';
}
