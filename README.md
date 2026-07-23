# NhamHealth

NhamHealth is a full-stack starter project with a Spring Boot API and a
Flutter client. The two applications live in separate folders and are run in
separate terminals.

> **Current status:** The repository contains the initial Spring Boot and
> Flutter scaffolds. The Flutter client is not connected to the API yet.

## Project structure

| Path | Description |
| --- | --- |
| `nhamhealth_api/` | Spring Boot API using Java 21, Spring Data JPA, Spring Security, H2, and PostgreSQL support |
| `nhamhealth_flutter/` | Flutter application for Android, iOS, web, Windows, macOS, and Linux |

## Prerequisites

Install the following tools before starting:

- [Git](https://git-scm.com/downloads)
- [JDK 21](https://adoptium.net/temurin/releases/?version=21)
- [Apache Maven 3.9+](https://maven.apache.org/download.cgi) on Windows
- [Flutter SDK](https://docs.flutter.dev/get-started/install) with Dart 3.5.4 or newer
- A platform toolchain for the device you want to use, such as Android Studio
  and the Android SDK, Xcode on macOS, or Chrome for the web

Confirm that Java and Flutter are available:

```bash
java -version
flutter doctor
```

Resolve any required platform issues reported by `flutter doctor` before
running the client.

## Clone the repository

```bash
git clone https://github.com/Namchheav009/NhamHealth.git
cd NhamHealth
```

## Run the API

Open the first terminal and enter the API directory:

```bash
cd nhamhealth_api
```

On Windows, run the API with Maven:

```powershell
mvn spring-boot:run
```

On macOS or Linux, the included Maven wrapper can install the required Maven
version automatically:

```bash
./mvnw spring-boot:run
```

The API starts at [http://localhost:8080](http://localhost:8080). The runtime
H2 dependency supplies an in-memory database for local startup, so PostgreSQL
configuration is not currently required. Because Spring Security is enabled,
the development password for the default `user` account is printed in the API
terminal during startup.

Stop the API with `Ctrl+C`.

## Run the Flutter client

Keep the API running, open a second terminal at the repository root, and run:

```bash
cd nhamhealth_flutter
flutter pub get
flutter devices
flutter run
```

If more than one device is available, Flutter asks you to select one. You can
also choose a target explicitly:

```bash
# Web
flutter run -d chrome

# Windows desktop (Windows only)
flutter run -d windows
```

For Android, start an emulator or connect a device before running
`flutter devices`. For iOS, use macOS with Xcode installed.

Stop the client with `q` in the Flutter terminal or with `Ctrl+C`.

## Tests and checks

Run the API tests from `nhamhealth_api/`:

```bash
# Windows
mvn test

# macOS/Linux
./mvnw test
```

Run the Flutter checks from `nhamhealth_flutter/`:

```bash
flutter analyze
flutter test
```

## Build the applications

Build the API JAR from `nhamhealth_api/`:

```bash
# Windows
mvn clean package

# macOS/Linux
./mvnw clean package
```

The JAR is written to `nhamhealth_api/target/`.

Build a Flutter release from `nhamhealth_flutter/` for the required platform:

```bash
flutter build apk       # Android APK
flutter build appbundle # Android App Bundle
flutter build web       # Web
```

Desktop and iOS builds require their corresponding operating system and native
toolchain.

## Local API networking from Flutter

When the client is connected to the API in future development, the correct API
host depends on the Flutter target:

- Desktop, iOS simulator, and web: `http://localhost:8080`
- Android emulator: `http://10.0.2.2:8080`
- Physical device: `http://<your-computer-local-IP>:8080`

The computer and physical device must be on the same network, and the firewall
must allow the API port.
