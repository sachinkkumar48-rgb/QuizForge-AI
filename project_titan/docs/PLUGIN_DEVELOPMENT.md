# Project TITAN 2.0 — Plugin Development Guide

## Overview
Project TITAN supports extensible plugins for AI providers, log sinks, error reporters, telemetry hooks, and custom analytics engines.

---

## Creating a Custom Plugin

### 1. Declare Dependencies
In your plugin's `pubspec.yaml`, depend on `titan_core` and `titan_domain`:

```yaml
dependencies:
  titan_core:
    path: ../titan_core
  titan_domain:
    path: ../titan_domain
```

### 2. Implement Component Interfaces

#### Custom AI Provider
```dart
class CustomAIProvider implements MentorProvider {
  @override
  Future<MentorMessage> generateResponse({
    required MentorContext context,
    required List<MentorMessage> history,
    required String userPrompt,
  }) async {
    // Custom AI provider logic
  }
}
```

#### Custom Log Sink
```dart
class CustomLogSink implements LogSink {
  @override
  void write(TitanLogEntry entry) {
    // Write log entry to external remote telemetry
  }
}
```

### 3. Register Plugin in Service Locator
```dart
void registerCustomPlugin() {
  final locator = TitanServiceLocator();
  locator.registerSingleton<LogSink>(CustomLogSink());
}
```
