# NhamHealth

NhamHealth is an early-stage full-stack health application built with a Spring
Boot API and a Flutter client. Both projects live in this repository and run as
separate applications.

> [!NOTE]
> The Flutter client is connected to the Spring REST API through a health-check
> endpoint. Domain endpoints can now be added using the same service pattern.

## Project structure

| Path | Description |
| --- | --- |
| `nhamhealth_api/` | Java 21 and Spring Boot 4.1 API with Spring MVC, Security, JPA, H2, and PostgreSQL support |
| `nhamhealth_app/` | Flutter application targeting Android, iOS, web, Windows, macOS, and Linux |

## Prerequisites

- [Git](https://git-scm.com/downloads)
- [JDK 21](https://adoptium.net/temurin/releases/?version=21)
- [Apache Maven 3.9+](https://maven.apache.org/download.cgi) on Windows
- [Flutter](https://docs.flutter.dev/get-started/install) with a Dart SDK that
  satisfies `^3.5.4`
- The platform toolchain for your target device, such as Android Studio and the
  Android SDK, Xcode on macOS, or Chrome for web development

The included Maven Wrapper can be used on macOS and Linux.

Check the installed tools before continuing:

```bash
java -version
flutter doctor
```

Resolve any required platform issues reported by `flutter doctor`.

## Getting started

Clone the repository:

```bash
git clone https://github.com/Namchheav009/NhamHealth.git
cd NhamHealth
```

### Run the API

Open a terminal in the API directory:

```bash
cd nhamhealth_api
```

Run the application on Windows:

```powershell
mvn spring-boot:run
```

Or on macOS and Linux:

```bash
./mvnw spring-boot:run
```

The API starts on `http://localhost:8080`. The default profile uses an in-memory
H2 database, so no external database is needed for local development. No user or
administrator accounts are inserted automatically. Authentication uses the
accounts already stored in the configured database.

Stop the server with `Ctrl+C`.

Verify the public REST endpoint in a browser or API client:

```text
GET http://localhost:8080/api/v1/health
```

It returns JSON containing `status`, `service`, and `timestamp`. Local Flutter
web origins are enabled through the backend CORS configuration. Other Spring
pages remain protected by Spring Security for the dashboard.

Open the dashboard login UI at `http://localhost:8080/login`. Only an active,
verified user whose database role is `ADMIN` can sign in to this page. A normal
`USER` account signs in through the Flutter-facing endpoint:

```http
POST /api/v1/auth/login
Content-Type: application/json

{"email":"user@example.com","password":"your-password"}
```

The response contains an `accessToken`, `tokenType`, `expiresIn`, and the user
summary. Flutter should send the token on protected API requests:

```http
Authorization: Bearer <accessToken>
```

`GET /api/v1/auth/me` can be used to verify the token and retrieve its current
user identity. Passwords stored in `users.password_hash` must be BCrypt hashes.

### Run the Flutter client

Keep the API terminal open, then open another terminal from the repository
root:

```bash
cd nhamhealth_app
flutter pub get
flutter devices
flutter run
```

The first screen calls the Spring health endpoint and shows the connection
status. On a physical phone, provide the computer's LAN address:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080
```

Replace the example address with the computer's address on the same Wi-Fi
network. Android debug and profile builds allow local HTTP traffic; release
builds must use HTTPS. The same override can point to staging or production:

```bash
flutter run --dart-define=API_BASE_URL=https://api.example.com
```

If multiple devices are available, Flutter will ask you to select one. A target
can also be selected explicitly:

```bash
flutter run -d chrome   # Web
flutter run -d windows  # Windows desktop
```

For Android, start an emulator or connect a device before running
`flutter devices`. Building and running the iOS client requires macOS and
Xcode.

## Supabase PostgreSQL

The API uses H2 unless the `supabase` Spring profile is active. To connect the
API to a Supabase PostgreSQL database:

1. In the Supabase dashboard, open the project and select **Connect**.
2. Open **Session pooler** > **View parameters** and copy the displayed host,
   username, and database password.
3. From `nhamhealth_api/`, create the local environment file:

   ```powershell
   # Windows PowerShell
   Copy-Item .env.example .env
   ```

   ```bash
   # macOS/Linux
   cp .env.example .env
   ```

4. Replace the placeholders in `.env` with the Supabase connection values:

   ```properties
   SUPABASE_DB_URL=jdbc:postgresql://YOUR_SESSION_POOLER_HOST:5432/postgres?sslmode=require
   SUPABASE_DB_USERNAME=postgres.YOUR_PROJECT_REF
   SUPABASE_DB_PASSWORD=YOUR_DATABASE_PASSWORD
   JPA_DDL_AUTO=update
   DB_POOL_MAX_SIZE=5
   DB_POOL_MIN_IDLE=1
   ```

   Keep the `jdbc:` prefix and do not quote the values.

5. Start the API with the Supabase profile:

   ```powershell
   # Windows PowerShell
   mvn spring-boot:run "-Dspring-boot.run.profiles=supabase"
   ```

   ```bash
   # macOS/Linux
   ./mvnw spring-boot:run -Dspring-boot.run.profiles=supabase
   ```

A successful connection ends with a `Started NhamhealthApiApplication` message
in the server log. Hibernate creates or updates application tables in the
database's `public` schema as JPA entities are added.

The `.env` file is ignored by Git. Never commit database credentials; only the
placeholder-based `.env.example` should be version controlled.

If the development machine has IPv6 connectivity, Supabase's direct connection
can be used instead:

```properties
SUPABASE_DB_URL=jdbc:postgresql://db.YOUR_PROJECT_REF.supabase.co:5432/postgres?sslmode=require
SUPABASE_DB_USERNAME=postgres
```

Use the exact connection values shown by the Supabase dashboard. The session
pooler on port `5432` is the usual option for IPv4 networks.

## Tests and checks

Run the API test suite from `nhamhealth_api/`:

```powershell
# Windows
mvn test
```

```bash
# macOS/Linux
./mvnw test
```

Run the Flutter checks from `nhamhealth_app/`:

```bash
flutter analyze
flutter test
```

## Build

Build the API JAR from `nhamhealth_api/`:

```powershell
# Windows
mvn clean package
```

```bash
# macOS/Linux
./mvnw clean package
```

The generated JAR is written to `nhamhealth_api/target/`.

Build the Flutter application from `nhamhealth_app/` for the required platform:

```bash
flutter build apk       # Android APK
flutter build appbundle # Android App Bundle
flutter build web       # Web
```

Desktop and iOS builds require their corresponding operating system and native
toolchain.

## Local API addresses for Flutter

When the Flutter client is connected to the backend, its API base URL will
depend on the target:

| Flutter target | API base URL |
| --- | --- |
| Web, desktop, or iOS simulator | `http://localhost:8080` |
| Android emulator | `http://10.0.2.2:8080` |
| Physical device | `http://<YOUR_COMPUTER_LAN_IP>:8080` |

For a physical device, the computer and device must be on the same network, and
the computer's firewall must allow traffic to port `8080`.
