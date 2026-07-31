# QuizForge AI / Project TITAN: Learning Operating System

QuizForge AI is an enterprise-grade, production-ready Learning Operating System application built with Flutter and a FastAPI Python backend. It leverages Google Gemini AI to parse UPSC (Union Public Service Commission) preparation study materials and generate high-fidelity, exam-conforming practice quizzes.

---

## Technical Architecture

The platform follows **Clean Architecture** and **SOLID design principles**:

### Flutter Client (`lib/`)
1. **Domain Models (`lib/models/`)**: Pure Dart models with zero Flutter dependencies handling domain entity contracts.
2. **Controllers (`lib/controllers/`)**: Encapsulates business logic rules and state management.
3. **Repositories (`lib/repositories/`)**: Manages offline persistence (Hive CE) and API connectivity.
4. **Services (`lib/services/`)**: Connects PDF extraction, Knowledge Intelligence Engine, and API services.
5. **UI Layer (`lib/pages/` & `lib/widgets/`)**: Responsive Material 3 design system.

### FastAPI Backend (`app/`)
1. **Core Configuration (`app/core/`)**: Managed via Pydantic `Settings` with fail-fast environment validation for production mode (`APP_ENV=production`), structured JSON logging (`JSONFormatter`), and Request ID tracing middleware (`X-Request-ID`).
2. **Identity & Auth (`app/identity/`)**: JWT Access/Refresh token authentication, password hashing (`passlib`/`bcrypt`), and protected route dependencies (`HTTPBearer`).
3. **AI Services (`app/services/`)**: Gemini API integration (`google-genai` SDK), PromptBuilder with strategy pattern, ResponseValidator for JSON schema enforcement, and key-redacted error logging.
4. **API Routes (`app/api/`)**: Versioned REST API endpoints (`/api/v1/auth`, `/api/v1/quiz`).

---

## Directory Structure

```text
QuizForge-AI/
├── app/                                    # FastAPI Backend Service
│   ├── api/                                # REST API routers (v1)
│   ├── core/                               # Settings, structured logging, middleware
│   ├── identity/                           # Authentication, JWT tokens, user schemas
│   ├── schemas/                            # Pydantic data schemas
│   ├── services/                           # Gemini AI, prompt strategy, response validator
│   └── main.py                             # FastAPI entry point
├── lib/                                    # Flutter Client Application
│   ├── core/                               # AppConfig profiles, network, utils
│   ├── controllers/                        # Business logic controllers
│   ├── models/                             # Domain models
│   ├── repositories/                       # Offline & network repositories
│   ├── services/                           # PDF extraction & AI integration
│   └── pages/                              # UI screens & Material 3 widgets
├── packages/                               # Modular Dart packages (knowledge_engine)
├── project_titan/                          # TITAN enterprise core packages
├── .env.example                            # Configuration environment template
├── Dockerfile                              # Production Docker container definition
├── requirements.txt                        # Backend Python dependencies
└── pubspec.yaml                            # Flutter client dependencies
```

---

## Production Hardening Baseline (Sprint 4.0.0)

Project TITAN includes production hardening across backend and client layers:

* **Configuration Safety (`TITAN-S4.0.0A`)**: Fail-fast startup validation in `app/core/settings.py` rejecting insecure default JWT secrets and missing API keys when running in production mode (`APP_ENV=production`).
* **Structured Observability (`TITAN-S4.0.0B`)**: Structured JSON logging (`JSONFormatter`) with request ID correlation (`X-Request-ID`), dynamic log levels, and automatic API key sanitization (`_sanitize_log_message`).
* **RFC Error Handling (`TITAN-S4.0.0C`)**: RFC-standard HTTP status codes (`503 Service Unavailable`, `504 Gateway Timeout`, `502 Bad Gateway`, `422 Unprocessable Entity`), clean user-facing error messages, and traceback isolation.
* **Production Security Posture (`TITAN-S4.0.0D`)**: Disallowed wildcard CORS credential forwarding, email format regex validation on auth endpoints, and `HTTPBearer` authentication dependencies.
* **Code Quality & Verification (`TITAN-S4.0.0E`)**: 100% clean static analysis (`flutter analyze lib`) and clean bytecode compilation (`compileall app`).

---

## Environment Configuration

Copy `.env.example` to `.env` in the root directory:

```env
# AI Provider Credentials
GEMINI_API_KEY=your_actual_gemini_api_key_here

# Backend Settings
APP_ENV=development
LOG_LEVEL=INFO
HOST=0.0.0.0
PORT=8000
CORS_ORIGINS=http://localhost:3000,http://127.0.0.1:8000
JWT_SECRET_KEY=titan-super-secret-jwt-key-change-in-production
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7
```

---

## Running the Application

### 1. Backend Service (FastAPI)

```bash
# Activate virtual environment
.\.venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run backend development server
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Backend endpoints available at:
* API Health Probe: `http://localhost:8000/health`
* Readiness Probe: `http://localhost:8000/ready`
* OpenAPI Documentation: `http://localhost:8000/docs`

### 2. Flutter Client

```bash
# Fetch dependencies
flutter pub get

# Run application in debug mode
flutter run
```

---

## Running Quality Assurance & Verification

```bash
# Backend Bytecode & Verification Tests
python -m compileall app
python -c "import tests.test_jwt_auth as t1, tests.test_observability as t2; t1.test_register_and_login_jwt_flow(); t1.test_invalid_jwt_returns_401(); t2.test_health_endpoint()"

# Flutter Static Analysis
flutter analyze lib
```
