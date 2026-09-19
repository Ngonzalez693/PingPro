# PingPro

**Table-tennis training mobile app with 3D drill visualization.**

Undergraduate thesis in Systems Engineering • Multimedia Engineering — Universidad de San Buenaventura Cali (2025).

PingPro lets coaches and athletes build drills step by step (stroke, spin, table zone, direction and side) and watch them performed by a 3D human model animated from self-captured motion-capture data.

Flutter · Node.js · TypeScript · Express · PostgreSQL · Firebase Auth · Cloudinary · Blender

---

## Contents

- [What it does](#what-it-does)
- [Architecture](#architecture)
- [Tech stack](#tech-stack)
- [Repository structure](#repository-structure)
- [Domain model](#domain-model)
- [API](#api)
- [Getting started](#getting-started)
- [Tests](#tests)
- [Author](#author)
- [License](#license)

---

## What it does

- **Drill library.** Each drill is an ordered sequence of steps, and each step is defined by five parameters: stroke (`hit`), spin (`rotation`), table zone (`zone`), direction (`direction`) and side (`side`).
- **Session builder.** Trainings group drills into structured practice sessions, with category, duration and cover image.
- **3D visualization.** Every step in a sequence is translated into one or more `.glb` animations of a human model rigged in Blender and animated from motion-capture data. The mapping from drill parameters to animations lives in `exercise_to_glb_steps.dart`, and the models are served from Cloudinary through a client-side cached catalogue.
- **Authentication and roles.** Firebase Auth with token verification on the backend. Per-user state (favorites, completed drills and trainings) is stored separately from the shared content.
- **Statistics.** Completed drills and trainings charted over daily, weekly and monthly periods with `fl_chart`. Everything is computed client-side from the `completedAt` timestamps already held in the app's stores — the backend exposes no statistics endpoints.

## Architecture

A monorepo with two independent applications:

```
Flutter (mobile)  ──HTTP/JSON──▶  Node.js/Express REST API  ──▶  PostgreSQL
      │                                    │                     (Supabase)
      │                                    └──▶  Cloudinary (.glb models)
      └──────────────  Firebase Auth  ─────────────┘
```

The backend follows a layered separation with dependency inversion:

```
routes → controllers → services → repositories (interface) → Postgres implementation
```

Each repository is declared first as an interface (`IExerciseRepository`, `IUserRepository`, …) and then implemented against PostgreSQL (`PostgresExerciseRepository`, …). Services depend on the interface rather than on the driver, so the persistence layer can be swapped without touching business logic — which is exactly what the migration from Firestore to PostgreSQL exercised: the implementations were replaced and the services were left untouched.

Input validation with Joi per schema and route, centralized error handling, normalized responses (`apiResponse`), logging with Winston/Morgan, and hardened HTTP headers via Helmet.

## Tech stack

| Layer | Technologies |
|---|---|
| Mobile | Flutter 3.29, Dart 3.7, `model_viewer_plus`, `fl_chart`, `flutter_svg` |
| Backend | Node.js 18+, TypeScript, Express 4, Joi, Winston, Helmet |
| Data | PostgreSQL 17 (`pg`), Supabase in production, Firebase Auth |
| Multimedia | Blender (modelling, rigging, motion capture), Cloudinary (`.glb` hosting) |
| Quality | Jest, ts-jest, Supertest, ESLint, Prettier |

## Repository structure

```
PingPro/
├── pingpro_back/            Node.js + TypeScript REST API
│   ├── src/
│   │   ├── config/          Firebase Admin (Auth), Postgres pool and SSL
│   │   ├── controllers/     Auth, Exercise, Training, User, Model3D
│   │   ├── services/        Business logic
│   │   ├── repositories/    Postgres implementations
│   │   ├── interfaces/      Model and repository contracts
│   │   ├── middlewares/     Auth, roles, rate limiting, validation, errors
│   │   ├── routes/          Endpoint definitions
│   │   ├── db/              Migration runner and transaction helper
│   │   ├── migration/       One-off Firestore → Postgres import
│   │   └── utils/           Joi validators, domain enums, logger
│   ├── db/                  SQL migrations and database bootstrap scripts
│   └── tests/               Unit, contract and integration tests
│
└── pingpro_front/           Flutter application
    ├── lib/
    │   ├── core/            Theme, HTTP services, state, 3D mappers
    │   ├── models/          Exercise, Training, SequenceStep, Model3D
    │   ├── screens/         14 screens (login, home, drills, …)
    │   └── widgets/         Reusable components and 3D viewer
    └── assets/              Images and icons
```

## Domain model

Table-tennis vocabulary is encoded as enums in `utils/enums.ts` and shared between backend and app:

| Enum | Values |
|---|---|
| `HitCode` | forehand, backhand, forehand-backhand, flick (forehand / banana / strawberry), serve, free, until-it-drops |
| `RotationCode` | backspin, topspin, right/left sidespin, drive, lifted, free |
| `ZoneCode` | short, mid, long, free |
| `DirectionCode` | seven positions across the width of the table, plus free |
| `SideCode` | right, pivot, left, centre |

A `SequenceStep` is the combination of those five codes, an `Exercise` is an ordered list of steps, and a `Training` is a list of drills. The client-side mapper turns each step into one or more chained animations, each with its own duration.

## API

All routes are served under the `/api` prefix.

| Resource | Endpoints |
|---|---|
| `/auth` | `POST /signup`, `POST /verify` |
| `/exercises` | `GET /`, `GET /:id`, `POST /`, `PUT /:id`, `DELETE /:id`, `GET /me/states`, `POST /:id/favorite`, `POST /:id/completed` |
| `/trainings` | `GET /`, `GET /:id`, `POST /`, `PUT /:id`, `DELETE /:id`, `GET /me/list`, `GET /me/states`, `POST /:id/completed` |
| `/users` | `GET /me`, `GET /:id`, `POST /`, `PUT /:id`, `DELETE /:id` |
| `/model3d` | `GET /`, `GET /:id` |

Every resource except `/auth` requires a Firebase token in the `Authorization` header — the router applies `authMiddleware` before any handler, so an anonymous request gets `401` even on a plain `GET /api/exercises`.

Authorization is layered on top of authentication: writes to the shared catalogue (`POST`, `PUT`, `DELETE` on `/exercises` and `/trainings`) are restricted to the `admin` role, and the `/users/:id` routes require that the caller either owns the record or is an admin. `POST /auth/signup` is rate-limited.

## Getting started

**Requirements:** Node.js ≥ 18, Flutter 3.29, PostgreSQL 17, a Firebase project and a Cloudinary account.

### Backend

```bash
cd pingpro_back
npm install
cp .env.example .env      # Firebase Admin credentials + DATABASE_URL
```

Create the local development database once, as superuser, then apply the schema:

```bash
psql -U postgres -p 5433 -f db/create-dev-database.sql
npm run db:migrate
```

`DATABASE_URL` points at the local database in development and at the Supabase session pooler in production. Do not append `?sslmode=`: SSL is decided in `src/config/postgres.ts`, which disables it for local hosts and verifies the server against `certs/supabase-ca.crt` everywhere else.

```bash
npm run dev               # development with nodemon
npm run build && npm start
```

### Flutter app

```bash
cd pingpro_front
flutter pub get
# create a .env file with: API_BASE_URL=http://localhost:3000
flutter run
```

`API_BASE_URL` is the host only, without the `/api` prefix — the services in `lib/core/services/` append the full path themselves. A phone on the same network needs the machine's LAN address rather than `localhost`.

The app also needs the Firebase configuration for the target platform (`google-services.json` on Android, `GoogleService-Info.plist` on iOS).

## Tests

```bash
cd pingpro_back
npm test                  # unit suites
npm run test:integration  # Firebase emulators + local test database
```

Unit tests cover controllers, services, middlewares (roles, rate limiting), validators and the Postgres pool configuration.

The integration suites need two things: the Firebase Auth and Firestore emulators, which `npm run test:integration` starts and stops around Jest, and a local `pingpro_test` database created once from `db/create-test-database.sql`. They cover each Postgres repository, the schema itself, the auth/catalogue/users APIs and the one-off Firestore import.

Two independent guards keep the tests off real data. `tests/setup.ts` pins the project to `demo-pingpro` — a prefix Firebase guarantees never reaches the cloud — and points `DATABASE_URL` at the local test database, before anything can load the production `.env`. Behind that, `poolConfig()` throws if a test run targets a database that is not both local and named `*_test`.

## Author

**Nicolás González Toro** — Software Systems Engineer and Multimedia Engineer

**Camilo González Toro** — Multimedia Engineer

Fifteen years of competitive table tennis are the source of the domain knowledge behind this project.

[LinkedIn](https://www.linkedin.com/in/nicolas-gonzalez-toro) · [Behance](https://www.behance.net/ngonzalez693) · [GitHub](https://github.com/Ngonzalez693)

## License

© 2025 Nicolás González Toro. All rights reserved.
This code is published for reference and demonstration purposes only. No permission is granted to use, copy, modify or distribute it.
