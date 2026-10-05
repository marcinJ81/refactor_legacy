<#
  log-instalacji.ps1 — wpis do logu instalacji (bez znaczników czasu).
  wersja-instalatora: 0.2.2

  -Naglowek "<tekst>"  → nowa sekcja `## <tekst>` (np. `Uruchomienie instalatora`,
                          `Podsumowanie`); numeracja kroków liczy się od nowa.
  -Tresc "<tekst>"     → kolejny krok `<nr>. <tekst>`.
  -Blok "<tekst>"      → tekst dopisany bez numeru (np. instrukcja w podsumowaniu).
  Plik tworzony z tytułem `# Log instalacji harnessu`, jeśli nie istnieje.
#>
param(
    [Parameter(Mandatory)][string] $Log,
    [string] $Naglowek,
    [string] $Tresc,
    [string] $Blok
)
. (Join-Path $PSScriptRoot "_wspolne.ps1")

$utf8 = [System.Text.UTF8Encoding]::new($false)
if (-not (Test-Path -LiteralPath $Log)) {
    Write-PlikUtf8 -Sciezka $Log -Tresc "# Log instalacji harnessu`n"
}
if ($Naglowek) { [System.IO.File]::AppendAllText($Log, "`n## $Naglowek`n`n", $utf8) }
if ($Tresc)    { Add-KrokLogu -Log $Log -Tresc $Tresc }
if ($Blok)     { [System.IO.File]::AppendAllText($Log, "`n$Blok`n", $utf8) }
