# FileMover

A Windows Flutter app that relocates a directory and leaves an NTFS junction at
its original path. Select a source folder and a destination **parent** folder:
`C:\Games\Example` → `D:\Moved\Example`.

## Usage

1. Close applications using the folder and choose both folders.
2. Click **Check folders** to validate access, contents, paths, and free space.
3. Click **Apply move**, double-check the paths, acknowledge that applications
   are closed, then click **Confirm and move**.
4. Keep applications closed until verification and cleanup finish.

The app hashes all files and named streams with SHA-256. It keeps the original
as a sibling backup while copying, checks contents and metadata, publishes the
destination, creates a junction through Windows APIs, verifies access through
the junction, commits the journal, then removes the backup. The original path
can be briefly unavailable during migration. Cancellation before the final
switch rolls back safely; the final switch completes before cancellation.

**History & recovery** lists incomplete operations after a restart. Recover the
original location or retry committed cleanup before starting another operation.
On failure, partial destination/staging copies are retained for inspection; their
paths appear in History. Remove retained copies manually only after checking
your restored data. Recovery stops when an unexpected directory occupies a path.
The app never recursively deletes a junction target during cleanup.

**Undo migration** copies and verifies the destination's current contents back
to the original location, including files changed since migration. It removes
the junction only after verification, commits, then cleans the old destination.
Undo requires enough free space on the original volume and the recorded junction
and destination to remain intact.

## Languages

Use the globe button in the title bar to select **English** or **简体中文**.
On first launch, Chinese Windows locales use Simplified Chinese; other locales
use English. Your choice is saved. Dates and standard widget controls use the
selected locale where Flutter supports it.

Choose **Import language JSON…** in the same menu to add another language or
override an existing one. A valid import is selected immediately and saved for
future launches. Invalid imports keep the current language unchanged.

Use [the complete English template](assets/languages/en.json) as a starting point,
or supply a partial UTF-8 JSON file like this:

```json
{
  "schemaVersion": 1,
  "locale": "fr",
  "name": "Français",
  "direction": "ltr",
  "messages": {
    "Source folder": "Dossier source",
    "Destination parent folder": "Dossier parent de destination",
    "Apply move": "Déplacer",
    "Browse {label}": "Parcourir : {label}"
  }
}
```

Message keys are the exact English source phrases from the template. Translate
the values and preserve named placeholders such as `{label}`. Unknown keys,
non-string or empty translations, and mismatched placeholders are rejected.
Use a locale such as `fr`, `de-DE`, `zh-Hant`, or `ar`, a display name, and `ltr`
or `rtl` for text direction. Files are limited to 1 MiB and 20 imported packs.
Missing translations use the built-in language when overriding it, otherwise
English. Unsupported framework locales still display your imported text, with
English standard widget controls.

Settings and imported packs are stored in
`%LOCALAPPDATA%\FileMover\languages.json`. Native errors have translated summaries;
expand **Original diagnostic details** to see the unchanged Windows/worker
diagnostics and paths. Imported packs are text data and never execute code.

## Supported limits

- Windows with Windows PowerShell 5.1 and .NET Framework 4.x; fixed local NTFS
  volumes, including migration between volumes. No automatic elevation.
- One migration/undo/recovery across app instances at a time.
- Existing destinations, overlapping paths, roots as sources, system/app
  directories, user profile roots, reparse points, encrypted files, and multiply
  linked files are rejected. Destination drive roots are allowed.
- Requires data size plus the greater of 5% or 256 MiB free space. Space and
  permissions can change after preflight; runtime failures also trigger recovery.
- The worker uses .NET Framework file APIs. Paths whose expanded backup/staging
  names approach legacy Windows limits are rejected before moving data.
- Copies timestamps, file attributes, alternate data streams, empty directories,
  and access rules. Copied ACLs are protected from destination inheritance to
  preserve source access rules; ownership and audit policies are not migrated.
- Live applications/databases and concurrent writers are unsupported. The worker
  locks existing files/streams against writes and compares the source again
  before committing; this is not a filesystem snapshot or a backup service.

## Architecture

Flutter UI and `WindowsMigrationService` launch an isolated C# Windows API worker
through PowerShell. JSON requests are base64-encoded arguments, never shell
interpolation. JSON-line events carry progress, results, and structured errors.
A small C++ method channel provides the Windows folder picker. The worker runs
outside the UI process and uses a named mutex for cross-instance serialization.

Worker assets live in `%LOCALAPPDATA%\FileMover\worker-v1`. Write-ahead journals
live in `%LOCALAPPDATA%\FileMover\operations`; each update flushes a temporary
file before atomic replacement. Directory identities and junction targets are
checked before switching, recovery, and cleanup. Do not delete journals while
recovery or cleanup is pending.

## Build and tests

Use Flutter **3.50.0 stable** with Dart **3.14.0** (or a compatible newer
version). The UI uses the standalone `material_ui` package; deprecated bundled
`package:flutter/material.dart` imports are no longer used.

```powershell
flutter pub get
flutter analyze
flutter test
powershell -NoProfile -ExecutionPolicy Bypass -File test/run_engine_tests.ps1
flutter build windows
```

Native integration tests use unique disposable folders in `build/` and a temporary
folder on another NTFS volume for cross-volume testing. They exercise real
junctions, streams, read-only files, verification failure, cancellation, undo,
conflicts, and interrupted journal states. They retain workspace fixtures for
inspection. Cross-volume testing requires `TEMP` on a different fixed NTFS drive
from the repository. The release executable is under
`build/windows/x64/runner/Release/`; distribute the entire Release folder.
