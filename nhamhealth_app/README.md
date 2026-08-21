# NhamHealth Flutter app

## Run on a physical Android phone

Connect the computer and phone to the same Wi-Fi network, start the Spring Boot
API, and then use either of these options:

- In VS Code, launch **NhamHealth App (physical phone)**. Its pre-launch task
  detects the computer's current Wi-Fi IPv4 address automatically.
- From PowerShell in this directory, run:

```powershell
.\tool\run_android_phone.ps1
```

The helper verifies the API health endpoint and writes the current URL to the
ignored `config/local_api.json` file before Flutter compiles the app. No Wi-Fi
address is committed to the source code.

For an Android emulator, use the **NhamHealth App (Android emulator)** launch
configuration; it uses `http://10.0.2.2:8080`.
