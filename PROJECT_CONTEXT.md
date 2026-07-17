# QuizForge AI

## Purpose
QuizForge AI is a Flutter application that generates and delivers UPSC/BPSC-style quizzes from PDF documents using the Gemini REST API. The application should provide an exam-like experience similar to UPSC CBT examinations.

## Target Users
- UPSC Aspirants
- BPSC Aspirants
- Other Competitive Exam Aspirants

## Technology Stack
- Flutter
- Dart
- Material 3
- Gemini REST API
- Local Storage/Cache

## Architecture

Presentation (UI)
↓
Controller
↓
Repository
↓
Services
↓
Gemini REST API

## Current Project Status

### Completed
- Project setup
- PDF processing
- Gemini integration
- Quiz generation
- Result screen
- Question State Management
- Responsive Question Palette
- Material 3 UI
- Cross-platform compatibility

### Planned Features
1. UPSC Exam Timer
2. Review Screen
3. Performance Analytics
4. Quiz History
5. Resume Quiz
6. PDF Library
7. Bookmark Questions
8. Dark Mode

## UI Guidelines
- Follow Material 3.
- Responsive on Android, Windows and Web.
- Keep the interface clean and distraction-free.
- Use UPSC exam conventions wherever possible.

## Coding Guidelines
- Always read AI_RULES.md before making changes.
- Preserve the existing architecture.
- Modify only necessary files.
- Avoid unnecessary dependencies.
- Run:
  - dart format
  - flutter analyze
after every change.

## Quality Standards
- No analyzer warnings.
- No analyzer errors.
- Clean, readable code.
- Reusable widgets where appropriate.
- Maintain separation between domain models and UI state.
