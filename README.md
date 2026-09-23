# MyEQ App

A clean Flutter application foundation using a feature-first project structure.

## Project Structure

```text
lib/
├── main.dart                         # Application entry point
├── application.dart                  # Root MaterialApp configuration
├── core/
│   └── theme/
│       └── application_theme.dart    # Shared application theme
└── features/
	└── home/
		└── presentation/
			└── pages/
				└── home_page.dart   # Home screen UI and local state
```

## Run Locally

```bash
flutter pub get
flutter run
```

## Verify

```bash
flutter test
flutter analyze
```

## Backend

The Node.js, Express, and MongoDB backend lives in `backend/`. See [backend/README.md](backend/README.md) for local and production setup.
