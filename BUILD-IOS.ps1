param(
    [string]$GameSource = (Join-Path $PSScriptRoot '..\Balatro\Balatro.exe'),
    [string]$PythonPath
)
$ErrorActionPreference = 'Stop'
if (-not $PythonPath) {
    $pythonCommand = Get-Command python -ErrorAction SilentlyContinue
    if ($pythonCommand) { $PythonPath = $pythonCommand.Source }
    else {
        $PythonPath = Join-Path $env:USERPROFILE '.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
    }
}
if (-not (Test-Path -LiteralPath $PythonPath)) { throw 'Python 3 requerido. Usa -PythonPath con su ruta.' }
if (-not (Test-Path -LiteralPath $GameSource)) { throw 'No se encuentra la copia local. Usa -GameSource.' }
Push-Location $PSScriptRoot
try {
    & $PythonPath build.py --ios --skip-apk --keep-crt --no-readabletro --force --balatro $GameSource
    if ($LASTEXITCODE -ne 0) { throw 'Build fallido.' }
    & $PythonPath tools/validate_ipa.py --original $GameSource
    if ($LASTEXITCODE -ne 0) { throw 'Validacion fallida.' }
    Get-FileHash -LiteralPath 'balatro-portrait.ipa' -Algorithm SHA256
} finally { Pop-Location }
