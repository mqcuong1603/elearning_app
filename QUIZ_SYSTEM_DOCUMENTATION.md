# Quiz Management System - Complete Documentation

## Overview
The E-Learning App now has a comprehensive Quiz Management System with question bank management, quiz creation, student quiz-taking, tracking dashboard, and CSV export functionality.

## Features Implemented

### 1. Question Bank Management (Reusable Across Semesters)
**Location:** `lib/screens/instructor/question_bank_screen.dart`

#### Features:
- ✅ Create multiple choice questions with 2-6 choices
- ✅ Difficulty levels: Easy, Medium, Hard
- ✅ Edit existing questions
- ✅ Delete questions
- ✅ Search questions by text
- ✅ Filter questions by difficulty
- ✅ View question statistics (total, easy, medium, hard counts)
- ✅ Questions are course-specific and reusable across quizzes

#### Models:
- **QuestionModel** (`lib/models/question_model.dart`):
  - `id`: Unique identifier
  - `courseId`: Course association
  - `questionText`: The question content
  - `choices`: List of ChoiceModel (multiple choice options)
  - `difficulty`: 'easy', 'medium', or 'hard'
  - `createdAt`, `updatedAt`: Timestamps

- **ChoiceModel** (nested in question_model.dart):
  - `id`: Unique identifier
  - `text`: Choice text
  - `isCorrect`: Boolean flag for correct answer

#### Service:
**QuestionService** (`lib/services/question_service.dart`):
- `createQuestion()`: Create new question with validation
- `updateQuestion()`: Update existing question
- `deleteQuestion()`: Remove question
- `getQuestionsForCourse()`: Get all questions for a course
- `getQuestionsByDifficulty()`: Filter by difficulty level
- `getRandomQuestionsByDifficulty()`: Get random questions for quiz generation
- `getQuestionStatistics()`: Get count statistics
- `validateQuizStructure()`: Check if enough questions exist
- `bulkImportQuestions()`: Import multiple questions
- `searchQuestions()`: Search by text

### 2. Quiz Creation with Advanced Settings
**Location:** `lib/screens/instructor/quiz_management_screen.dart`

#### Quiz Settings:
- ✅ **Time Windows**: Open date/time and close date/time
- ✅ **Number of Attempts**: Configure max attempts per student
- ✅ **Duration**: Set quiz duration in minutes
- ✅ **Random Question Selection by Difficulty**:
  - Configure how many easy, medium, and hard questions
  - Questions are randomly selected from the question bank
  - Different students may get different questions
- ✅ **Group Scoping**: Assign quiz to specific groups or all groups
- ✅ **Validation**: Ensures enough questions exist in bank before creation

#### Quiz Model:
**QuizModel** (`lib/models/quiz_model.dart`):
- `id`, `courseId`, `title`, `description`
- `openDate`, `closeDate`: Time window
- `durationMinutes`: Quiz time limit
- `maxAttempts`: Maximum attempts allowed
- `questionStructure`: Map of difficulty -> count (e.g., {'easy': 5, 'medium': 3, 'hard': 2})
- `groupIds`: Target groups (empty = all groups)
- `instructorId`, `instructorName`: Creator info
- `createdAt`, `updatedAt`: Timestamps

#### Properties:
- `isAvailable`: Currently open
- `isClosed`: Past close date
- `isUpcoming`: Before open date
- `isForAllGroups`: Available to all groups
- `totalQuestions`: Sum of all difficulty levels

#### Service:
**QuizService** (`lib/services/quiz_service.dart`):
- `createQuiz()`: Create quiz with validation
- `updateQuiz()`: Modify quiz settings
- `deleteQuiz()`: Remove quiz and all submissions
- `getQuiz()`: Get single quiz
- `getQuizzesForCourse()`: Get all quizzes for instructor
- `getAvailableQuizzesForStudent()`: Get quizzes available to student
- `generateQuizQuestions()`: Randomly select questions based on structure
- `submitQuiz()`: Process student submission with auto-grading
- `getStudentAttemptCount()`: Check attempts used
- `canStudentTakeQuiz()`: Validate eligibility
- `getAllSubmissionsForQuiz()`: Get all submissions (instructor)
- `getQuizStatistics()`: Calculate statistics

### 3. Quiz Taking Interface (Student)
**Location:** `lib/screens/student/quiz_taking_screen.dart`

#### Features:
- ✅ **Timer**: Live countdown timer with auto-submit when time expires
- ✅ **Question Navigation**:
  - Previous/Next buttons
  - Visual progress dots (green = answered, current question highlighted)
  - Jump to any question by clicking progress dots
- ✅ **Question Display**:
  - Difficulty badge (color-coded)
  - Multiple choice options with A, B, C, D labels
  - Visual feedback for selected answer
- ✅ **Progress Tracking**:
  - Questions answered count
  - Progress bar
  - Percentage complete
- ✅ **Exit Confirmation**: Prevent accidental exits
- ✅ **Submit Confirmation**: Verify before final submission
- ✅ **Auto-Grading**: Immediate results after submission
- ✅ **Results View**:
  - Pass/Fail status
  - Score percentage
  - Correct answers count
  - Time taken
  - Attempt number

#### Quiz Submission Model:
**QuizSubmissionModel** (`lib/models/quiz_submission_model.dart`):
- `id`, `quizId`, `studentId`, `studentName`
- `answers`: List of QuizAnswerModel (question -> selected choice -> correctness)
- `score`: Percentage (0-100)
- `submittedAt`, `startedAt`: Timestamps
- `attemptNumber`: Which attempt this is
- `durationSeconds`: Time taken

**QuizAnswerModel** (nested):
- `questionId`: Question reference
- `selectedChoiceId`: Student's choice
- `isCorrect`: Whether answer was correct

### 4. Tracking Dashboard (Instructor)
**Location:** `lib/screens/instructor/quiz_tracking_screen.dart`

#### Features:
- ✅ **Statistics Overview**:
  - Total submissions count
  - Unique students count
  - Average score
  - Pass rate (≥50%)
  - Highest and lowest scores

- ✅ **Submission List**:
  - Student name
  - Score (color-coded: green ≥80%, orange ≥50%, red <50%)
  - Submission date/time
  - Attempt number
  - Pass/Fail indicator

- ✅ **Detailed View** (expandable):
  - Correct answers / Total questions
  - Duration taken
  - Start time

- ✅ **Sorting Options**:
  - By date (newest/oldest)
  - By score (highest/lowest)
  - By student name (A-Z/Z-A)

- ✅ **Filtering Options**:
  - All attempts
  - Best attempt only (per student)
  - Latest attempt only (per student)

- ✅ **Who Completed/Who Hasn't**:
  - Statistics show unique students who submitted
  - Can filter to see best scores per student
  - Can identify students who haven't submitted by comparing with enrollment

### 5. CSV Export for Grades
**Location:** Integrated in `quiz_tracking_screen.dart` (lines 446-533)

#### Export Features:
- ✅ **One-Click Export**: Download button in app bar
- ✅ **Cross-Platform Support**:
  - Web: Browser download
  - Windows/macOS/Linux: File save dialog
  - Uses platform-specific implementation

- ✅ **CSV Columns**:
  1. Student Name
  2. Student ID
  3. Score (%)
  4. Correct Answers
  5. Total Questions
  6. Duration
  7. Attempt Number
  8. Started At
  9. Submitted At
  10. Status (Passed/Failed)

- ✅ **Respects Current Filters**: Exports what you see (all/best/latest)
- ✅ **Timestamped Files**: `quiz_results_[QuizTitle]_[Timestamp].csv`
- ✅ **Error Handling**: User-friendly error messages

## State Management

### QuizProvider
**Location:** `lib/providers/quiz_provider.dart`

Manages all quiz-related state:
- Quiz lists and selection
- Question bank
- Active quiz state (timer, answers, progress)
- Submissions and statistics
- Loading and error states

**Key Methods:**
- Quiz CRUD: `createQuiz()`, `updateQuiz()`, `deleteQuiz()`
- Question CRUD: `createQuestion()`, `updateQuestion()`, `deleteQuestion()`
- Quiz Taking: `startQuiz()`, `selectAnswer()`, `submitQuiz()`, `cancelQuiz()`
- Statistics: `loadQuizStatistics()`, `loadQuestionStatistics()`
- Student: `checkQuizEligibility()`, `getAttemptCount()`

## Integration with Course Space

### Location: `lib/screens/shared/course_space_screen.dart`

#### Instructor View:
- Quizzes shown in "Classwork" tab
- Click quiz → Navigate to Quiz Management Screen
- Can create, edit, delete quizzes
- Can access Question Bank
- Can view tracking dashboard

#### Student View:
- Quizzes shown in "Classwork" tab
- Color-coded status:
  - **Green**: Available to take
  - **Blue**: Upcoming
  - **Red**: Closed
  - **Purple**: Completed (shows score)
- Click available quiz → Navigate to Quiz Taking Screen
- Shows attempt count and best score
- Disabled if max attempts reached

## Database Schema (Firestore)

### Collections:

#### `questions`:
```
{
  id: string,
  courseId: string,
  questionText: string,
  choices: [
    { id: string, text: string, isCorrect: boolean }
  ],
  difficulty: 'easy' | 'medium' | 'hard',
  createdAt: timestamp,
  updatedAt: timestamp
}
```

#### `quizzes`:
```
{
  id: string,
  courseId: string,
  title: string,
  description: string,
  openDate: timestamp,
  closeDate: timestamp,
  durationMinutes: number,
  maxAttempts: number,
  questionStructure: {
    easy: number,
    medium: number,
    hard: number
  },
  groupIds: string[],
  instructorId: string,
  instructorName: string,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

#### `quiz_submissions`:
```
{
  id: string,
  quizId: string,
  studentId: string,
  studentName: string,
  answers: [
    { questionId: string, selectedChoiceId: string, isCorrect: boolean }
  ],
  score: number,
  submittedAt: timestamp,
  attemptNumber: number,
  startedAt: timestamp,
  durationSeconds: number
}
```

## Constants

### Location: `lib/config/app_constants.dart`

Relevant constants:
- `defaultQuizDurationMinutes`: 60
- `defaultMaxQuizAttempts`: 2
- `difficultyEasy`, `difficultyMedium`, `difficultyHard`: Difficulty level constants
- `collectionQuizzes`, `collectionQuestions`, `collectionQuizSubmissions`: Firestore collections

## Security & Validation

### Question Validation:
- Must have at least 2 choices
- Must have exactly 1 correct answer
- Difficulty must be 'easy', 'medium', or 'hard'

### Quiz Validation:
- Close date must be after open date
- Question structure must not be empty
- Validates sufficient questions exist in bank before creation
- Cannot exceed max attempts
- Cannot submit after time expires
- Cannot take quiz outside time window

### Student Access Control:
- Only see quizzes assigned to their groups
- Cannot access quiz if not in target group
- Cannot exceed max attempts
- Cannot retake after max attempts reached

## Testing Checklist

### Instructor Workflow:
1. ✅ Create questions in Question Bank
2. ✅ Edit questions
3. ✅ Delete questions
4. ✅ Search/filter questions
5. ✅ Create quiz with question structure
6. ✅ Edit quiz settings
7. ✅ Delete quiz
8. ✅ View quiz tracking dashboard
9. ✅ Sort/filter submissions
10. ✅ Export to CSV

### Student Workflow:
1. ✅ View available quizzes
2. ✅ Check quiz status (upcoming/available/closed/completed)
3. ✅ Start quiz
4. ✅ Answer questions
5. ✅ Navigate between questions
6. ✅ Track progress
7. ✅ Watch timer
8. ✅ Submit quiz
9. ✅ View results
10. ✅ Retake quiz (if attempts remain)

### Edge Cases:
1. ✅ Timer expiration → auto-submit
2. ✅ Exit quiz → confirm dialog
3. ✅ Max attempts reached → cannot retake
4. ✅ Quiz not in time window → cannot access
5. ✅ Not in target group → cannot see quiz
6. ✅ Insufficient questions in bank → cannot create quiz
7. ✅ Empty submissions → graceful empty state
8. ✅ CSV export with no data → error message

## File Structure

```
lib/
├── models/
│   ├── question_model.dart           # Question & Choice models
│   ├── quiz_model.dart               # Quiz model
│   └── quiz_submission_model.dart    # Submission & Answer models
├── services/
│   ├── question_service.dart         # Question CRUD & operations
│   └── quiz_service.dart             # Quiz CRUD & operations
├── providers/
│   └── quiz_provider.dart            # State management
└── screens/
    ├── instructor/
    │   ├── question_bank_screen.dart     # Question management UI
    │   ├── quiz_management_screen.dart   # Quiz CRUD UI
    │   └── quiz_tracking_screen.dart     # Results & CSV export
    └── student/
        └── quiz_taking_screen.dart       # Quiz taking interface
```

## Next Steps / Future Enhancements (Optional)

1. **Question Types**: Add true/false, multiple-select, short answer
2. **Question Images**: Support images in questions and choices
3. **Randomize Choices**: Shuffle choice order for each student
4. **Question Pool**: Create question pools for more variety
5. **Review Mode**: Let students review their answers after submission
6. **Detailed Analytics**: Per-question statistics (which questions are hardest)
7. **Peer Comparison**: Show student's rank compared to peers
8. **Quiz Templates**: Save common quiz structures as templates
9. **Scheduled Release**: Auto-publish quizzes at scheduled time
10. **Question Import**: Import questions from CSV/JSON

## Summary

The Quiz Management System is **fully implemented** with all requested features:

✅ Question Bank Management (reusable across semesters)
✅ Multiple choice questions with difficulty levels
✅ Quiz creation with time windows, attempts, duration
✅ Random question selection by difficulty
✅ Student quiz-taking interface with timer
✅ Tracking dashboard (who completed, who hasn't)
✅ Scores and submission times
✅ CSV export for grades

All components are integrated into the course space and ready for use!
