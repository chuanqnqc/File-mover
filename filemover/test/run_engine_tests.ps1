$ErrorActionPreference = 'Stop'
$project = Split-Path -Parent $PSScriptRoot
$testRoot = Join-Path $project ('build\engine-tests-' + [Guid]::NewGuid().ToString('N'))
Add-Type -Path (Join-Path $project 'assets\engine.cs'), (Join-Path $PSScriptRoot 'engine_tests.cs') -ReferencedAssemblies System.Web.Extensions
[FileMover.EngineTests]::Run($testRoot)
