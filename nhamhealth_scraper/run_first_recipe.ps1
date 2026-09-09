$ErrorActionPreference = "Stop"
Push-Location $PSScriptRoot
try {
    if (-not (Test-Path ".\venv\Scripts\python.exe")) {
        python -m venv venv
        if ($LASTEXITCODE -ne 0) { throw "Could not create virtual environment" }
    }
    & ".\venv\Scripts\python.exe" -m pip install -r requirements.txt
    if ($LASTEXITCODE -ne 0) { throw "Could not install requirements" }
    if (-not (Test-Path ".env")) { Copy-Item ".env.example" ".env" }
    & ".\venv\Scripts\python.exe" main.py --url "https://cambodiancookbook.com/recipes/bai-sach-chrouk/"
    if ($LASTEXITCODE -ne 0) { throw "Review output/normalized_recipes.json and the validation errors above. No import was requested." }
    Write-Host "Review output/normalized_recipes.json and images/bai-sach-chrouk.webp. No database import was requested."
} finally {
    Pop-Location
}
