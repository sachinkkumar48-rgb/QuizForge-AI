# Project TITAN 2.0 — Testing Strategy & Guidelines

## Test Pyramid & Coverage Requirements
Project TITAN enforces unit, widget, and integration testing across all 25 sub-packages:

1. **Unit Tests**: Test models, engine algorithms, repository logic, security managers, and performance optimization utilities. Target coverage: **100%**.
2. **Widget Tests**: Test Material 3 components using `WidgetTester` and MaterialApp wrappers.
3. **Integration Tests**: Verify end-to-end user flows, offline persistence, and provider adapters.

---

## Execution Commands

### Test Single Package
```bash
# Security package tests
cd project_titan/packages/titan_security
flutter test

# Core package tests
cd project_titan/packages/titan_core
flutter test
```

### Test Entire Monorepo
```bash
# Melos monorepo execution
melos bootstrap
melos test
```

### Code Format & Static Analysis
```bash
# Format check
dart format . --set-exit-if-changed

# Static analysis across monorepo
melos analyze
```
