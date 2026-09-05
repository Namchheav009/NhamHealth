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

### API source layout

The API uses a layer-based structure under
`nhamhealth_api/src/main/java/com/nhamhealth/nhamhealth_api/`:

| Folder | Responsibility |
| --- | --- |
| `config/` | Spring and security configuration |
| `controller/` | All REST and web request controllers |
| `dto/` | API request and response objects |
| `entity/` | JPA database entities |
| `exception/` | Application-specific exceptions |
| `repository/` | Spring Data repositories grouped by feature package |
| `security/` | Authentication principals and JWT support |
| `service/` | Business logic grouped by feature package |

Controllers remain under `controller/`, with `api/`, `auth/`, and `admin/`
subfolders so request-handling code is easy to locate. See the
[API documentation](nhamhealth_api/docs/README.md) for a detailed folder guide,
feature map, and a checklist for adding new Spring Boot features. Repository
placement is documented in the
[repository package guide](nhamhealth_api/src/main/java/com/nhamhealth/nhamhealth_api/repository/README.md),
and service placement is documented in the
[service package guide](nhamhealth_api/src/main/java/com/nhamhealth/nhamhealth_api/service/README.md).

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

New mobile users can register through `POST /api/v1/auth/register` with
`fullName`, `email`, and a password of at least eight characters. Registration
returns the same bearer-token response as login. The Flutter client stores this
token in platform secure storage.

### Configure NVIDIA AI

NVIDIA NIM powers food and drink image recognition, nutrition estimates, meal
recommendations, and the wellness chatbot. Keep the key on the server, then
restart the API so it can read the environment variable:

```powershell
$env:APP_AI_NVIDIA_API_KEY="your-nvidia-api-key"
$env:APP_STORAGE_SUPABASE_SERVICE_KEY="your-supabase-service-role-key"
$env:SPRING_DATASOURCE_PASSWORD="your-database-password"
cd nhamhealth_api
.\mvnw.cmd spring-boot:run
```

From Git Bash/MINGW, use `export` in the same terminal before starting Spring:

```bash
export APP_AI_NVIDIA_API_KEY='your-nvidia-api-key'
export APP_STORAGE_SUPABASE_SERVICE_KEY='your-supabase-service-role-key'
export SPRING_DATASOURCE_PASSWORD='your-database-password'
cd nhamhealth_api
./mvnw.cmd spring-boot:run
```

Vision, fallback vision, nutrition, recommendation, and assistant models can be
changed through the `app.ai.nvidia.*` properties documented in
`application.properties.example`. When `NVIDIA_API_KEY` is absent, meal ranking
and chatbot features use their local fallbacks; remote image analysis is
unavailable. Never put the NVIDIA key in Flutter or commit it to the repository.

### Configure password-reset email

Forgot password uses a real email verification flow. Configure the API with a
Gmail account that has two-step verification enabled and use a Gmail App
Password, not the account's normal password:

```powershell
$env:GMAIL_USERNAME="your-account@gmail.com"
$env:GMAIL_APP_PASSWORD="your-16-character-app-password"
.\mvnw.cmd spring-boot:run
```

The app requests a four-digit code from `POST /api/v1/auth/forgot-password`,
exchanges it for a short-lived one-time token through
`POST /api/v1/auth/verify-reset-code`, and changes the BCrypt password through
`POST /api/v1/auth/reset-password`. Codes expire after 3 minutes, reset tokens
after 15 minutes, and resend is limited to once every 30 seconds.

### Configure PlasGate SMS

PlasGate requires an account-approved sender ID (maximum 11 characters). Do not
use `Nham Health`, `SMS Info`, or another sender unless PlasGate has enabled it
for your account. Configure the approved value in the terminal that starts the
API:

```powershell
$env:PLASGATE_PRIVATE_KEY="your-private-key"
$env:PLASGATE_SECRET_KEY="your-secret-key"
$env:PLASGATE_SENDER_ID="approved-id"
$env:PLASGATE_SMS_FALLBACK_TO_CONSOLE="false" # production
.\mvnw.cmd spring-boot:run
```

`PLASGATE_FALLBACK_SENDER_ID` is optional and must also be approved. When no
sender is configured in local development, the default console fallback avoids
calling the gateway and prints the simulated verification message instead.

### Configure Google sign-in

Google sign-in requires OAuth credentials from the Google Cloud Console; no
client secret is stored in the Flutter application.

1. Create an OAuth **Web application** client. Put its client ID in
   `nhamhealth_api/src/main/resources/application.properties`:

   ```properties
   app.auth.google.client-id=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
   ```

2. For Android, create an OAuth **Android** client for the package
   `com.example.nhamhealth_flutter` and add the SHA-1 fingerprints for every
   signing configuration you use. Copy the safe example to the ignored local
   configuration file and replace its placeholders with the Android and Web
   client IDs from the same Google Cloud project:

   ```powershell
   Copy-Item nhamhealth_app/config/google_oauth.example.json `
     nhamhealth_app/config/google_oauth.json
   ```

   Android builds also load this ignored file through the native Gradle
   configuration, so a normal `flutter run` works. VS Code launch profiles
   additionally pass it as Dart defines for other supported platforms. From a
   terminal on iOS, macOS, or web, use:

   ```powershell
   cd nhamhealth_app
   flutter run --dart-define-from-file=config/google_oauth.json
   ```

3. For iOS, create an OAuth **iOS** client for the Xcode bundle identifier.
   Add its reversed client ID under `CFBundleURLTypes` in
   `nhamhealth_app/ios/Runner/Info.plist`, put its client ID in
   `GOOGLE_CLIENT_ID` in the local JSON file, then run with that file:

   ```powershell
   flutter run --dart-define-from-file=config/google_oauth.json
   ```

The styled Google button currently targets Android, iOS, and macOS. Google
requires its SDK-rendered button for interactive Flutter web sign-in, so the
custom mobile button reports that it is unavailable when run on web. The API
always verifies Google ID-token signature, audience, issuer, and expiry before
creating an NhamHealth session.

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

### Enable real-time phone notifications

Android notifications use Firebase Cloud Messaging. The checked-in
`google-services.json` configures the Flutter client, while the Spring API must
authenticate separately with a Firebase service account. Download the private
key from **Firebase console > Project settings > Service accounts**, keep it
outside the repository, and start the API from PowerShell with:

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\secure\nhamhealth-firebase-admin.json"
$env:NHAMHEALTH_PUSH_ENABLED="true"
mvn spring-boot:run
```

Restart the app (or sign in again) on each physical phone after enabling push
so its current FCM token is registered with the API. Android 13 and newer also
require the user to allow notifications when prompted. Incoming community and
admin notifications then show immediately while the app is open, backgrounded,
or closed; tapping a post notification opens that post.

If multiple devices are available, Flutter will ask you to select one. A target
can also be selected explicitly:

```bash
flutter run -d chrome   # Web
flutter run -d windows  # Windows desktop
```

For Android, start an emulator or connect a device before running
`flutter devices`. Building and running the iOS client requires macOS and
Xcode.

From the repository root, the Windows launcher checks API health and selects
the correct Android connection automatically:

```powershell
.\run-android.ps1 -Mode emulator
.\run-android.ps1 -Mode usb
.\run-android.ps1 -Mode wifi
```

USB mode requires USB debugging and uses `adb reverse`, so it does not depend
on Wi-Fi, the computer's IP address, or a firewall rule. Wi-Fi mode detects the
computer's current Wi-Fi IPv4 address; use `-ComputerIp 192.168.1.10` only when
automatic detection is not appropriate. Pass `-DeviceId <id>` when more than
one Android target is connected.

## Supabase PostgreSQL

The API reads its Supabase connection directly from
`nhamhealth_api/src/main/resources/application.properties`:

1. Create the ignored local configuration file from the safe template:

   ```powershell
   Copy-Item nhamhealth_api/src/main/resources/application.properties.example nhamhealth_api/src/main/resources/application.properties
   ```

2. In the Supabase dashboard, open the project and select **Connect**.
3. Open **Session pooler** > **View parameters** and copy the displayed host,
   username, and database password.
4. Update the Spring properties with the Supabase connection values:

   ```properties
   spring.profiles.active=supabase
   spring.datasource.url=jdbc:postgresql://YOUR_SESSION_POOLER_HOST:5432/postgres?sslmode=require
   spring.datasource.username=postgres.YOUR_PROJECT_REF
   spring.datasource.password=YOUR_DATABASE_PASSWORD
   spring.jpa.hibernate.ddl-auto=update
   spring.datasource.hikari.maximum-pool-size=5
   spring.datasource.hikari.minimum-idle=1
   spring.datasource.hikari.idle-timeout=600000
   spring.datasource.hikari.max-lifetime=1800000
   spring.datasource.hikari.keepalive-time=120000
   spring.datasource.hikari.validation-timeout=5000
   spring.datasource.hikari.connection-timeout=30000
   spring.datasource.hikari.data-source-properties.tcpKeepAlive=true
   logging.level.com.zaxxer.hikari.pool.PoolBase=ERROR
   ```

   Keep the `jdbc:` prefix and do not quote the values.

5. Start the API:

   ```powershell
   # Windows PowerShell
   .\mvnw.cmd spring-boot:run
   ```

### Shared uploaded images

The API uses the local `nhamhealth_api/uploads` directory when Supabase Storage
is not configured. That is suitable for one development machine only. If two
PCs run the API against the same database, configure shared storage:

1. In Supabase Dashboard, open **Storage** and create a **public** bucket named
   `nhamhealth-images`.
2. Set these server-only values in `application.properties`:

   ```properties
   app.storage.supabase.url=https://YOUR_PROJECT_REF.supabase.co
   app.storage.supabase.service-key=YOUR_SERVER_ONLY_SERVICE_ROLE_KEY
   app.storage.supabase.bucket=nhamhealth-images
   ```

3. Restart the API. New profile, meal, recipe-step, and ingredient images will
   be uploaded to the shared bucket and their public HTTPS URLs will be stored
   in the database.

Never add the service-role key to Flutter or commit it to Git. Images uploaded
before shared storage was enabled remain on the PC that originally received
them and should be uploaded again.

   ```bash
   # macOS/Linux
   ./mvnw spring-boot:run
   ```

A successful connection ends with a `Started NhamhealthApiApplication` message
in the server log. Hibernate creates or updates application tables in the
database's `public` schema as JPA entities are added.

`application.properties` now contains server credentials. Keep the repository
private and never expose the database password or service-role key to Flutter,
JavaScript, logs, or screenshots.

If the development machine has IPv6 connectivity, Supabase's direct connection
can be used instead:

```properties
spring.datasource.url=jdbc:postgresql://db.YOUR_PROJECT_REF.supabase.co:5432/postgres?sslmode=require
spring.datasource.username=postgres
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

For builds that include Google sign-in, append
`--dart-define-from-file=config/google_oauth.json` to the selected build
command.

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
