# Repository Guidelines

## Project Structure & Module Organization
This repository is a monorepo with three services and shared orchestration.
- `frontend/` Flutter app. Main code is in `frontend/main/lib/` and widget tests in `frontend/main/test/`.
- `backend/` Python OCR + AI analysis pipeline and a FastAPI server.
- `realtime/` Placeholder for real-time processing/WebSocket work (currently contains `.gitkeep`).
- `docker-compose.yml` is the top-level orchestration file for multi-service runs.

## Build, Test, and Development Commands
Frontend (run from `frontend/main/`):
- `flutter pub get` installs dependencies.
- `flutter run` launches the app on a device/emulator.
- `flutter test` runs widget tests.
- `flutter build apk` / `flutter build ios` / `flutter build web` build targets.

Backend (run from `backend/`):
- `pip install requests openai fastapi uvicorn` installs core dependencies.
- `uvicorn api:app --reload --port 8000` starts the API server.
- Example CLI pipeline run:
  `python -c "from pipeline import ContractAnalysisPipeline; p=ContractAnalysisPipeline(); p.analyze(r'file.pdf')"`

## Coding Style & Naming Conventions
- Python: 4-space indentation, `snake_case` for functions/vars, `PascalCase` for classes.
- Dart/Flutter: use `dart format` (2-space indentation), prefer `const` widgets, and follow standard Dart naming (`lowerCamelCase` for members, `PascalCase` for types).
- Import order: `dart:` then `package:` then relative imports (see `frontend/main/AGENTS.md`).

## Testing Guidelines
- Frontend uses `flutter_test`; keep widget tests under `frontend/main/test/` and run with `flutter test`.
- No backend test framework is currently defined; if you add tests, document how to run them here and keep test files next to the module or under a new `backend/tests/`.

## Commit & Pull Request Guidelines
- Recent commits use short imperative messages like “Update frontend” with occasional Conventional Commit prefixes (e.g., `chore:`). Keep messages concise; use a type prefix if it clarifies scope.
- PRs should include: a brief summary, test commands run (or “not run”), and screenshots for UI changes.

## Security & Configuration Tips
- Do not commit secrets. Backend expects `UPSTAGE_API_KEY` and `OPENAI_API_KEY` environment variables (see `backend/README.md`).
- If you add new external API keys, document required env vars and defaults in the service README.

## Architecture Overview
- Backend pipeline flow: OCR → text cleanup/splitting → risky clause filtering → precedent/law lookup → embedding similarity → risk mapping → debate generation → LLM summary.
- Frontend consumes API results and presents clause summaries and risk indicators.

## Agent-Specific Instructions
- Follow the Flutter-specific contributor guide in `frontend/main/AGENTS.md` for UI work.
