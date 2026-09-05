<#
.SYNOPSIS
    Builds a clean, flat RAGE runtime from the official .NET 8 runtime archive.

.DESCRIPTION
    The official archive is extracted from its shared/Microsoft.NETCore.App/<version>
    directory into a new staging directory. Only the explicitly allowed RAGE
    components are copied from the old RAGE runtime. The script never overlays
    the old runtime in place and does not copy the old coreclr, hostpolicy,
    System.* or diagnostic files.

    The output is committed only after the Bootstrapper assembly and every one
    of its types can be loaded. A JSON manifest records source versions,
    architecture, and SHA-256 checksums for every output file except the
    manifest itself.

.PARAMETER DotnetRuntimeArchive
    Official dotnet-runtime-8.0.30-win-x64.zip archive.

.PARAMETER RageRuntimePath
    Existing flat RAGE runtime directory containing Bootstrapper.dll.

.PARAMETER OutputDirectory
    Directory to create for the clean runtime.

.PARAMETER NewtonsoftJsonPath
    Optional path to Newtonsoft.Json.dll version 13.0.4. When omitted, the
    script checks the current NeptuneEvo Debug output and the old runtime.

.PARAMETER Force
    Replace a non-empty output directory after the new runtime has passed all
    validation checks.

.EXAMPLE
    .\Prepare-RageRuntime.ps1 `
        -DotnetRuntimeArchive .\dotnet-runtime-8.0.30-win-x64.zip `
        -RageRuntimePath .\dotnet\runtime `
        -OutputDirectory .\dotnet\runtime-net8-pilot

.EXAMPLE
    .\Prepare-RageRuntime.ps1 `
        -DotnetRuntimeArchive $env:TEMP\dotnet-runtime-8.0.30-win-x64.zip `
        -RageRuntimePath .\dotnet\runtime `
        -OutputDirectory .\dotnet\runtime-net8-pilot `
        -NewtonsoftJsonPath .\dotnet\resources\NeptuneEvo\bin\Debug\net8.0\Newtonsoft.Json.dll `
        -Force
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$DotnetRuntimeArchive,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$RageRuntimePath,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$OutputDirectory,

    [Parameter(Mandatory = $false)]
    [string]$NewtonsoftJsonPath,

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RuntimeVersion = '8.0.30'
$RuntimeRid = 'win-x64'
$ExpectedArchiveSha512 = '99e61c9a2d15dbb280db98bfc3ee45dfeda25fdb91e3d3c167789dd74328957a4f791c57ad13e8a3344df64a27d6ef8332dd91a773072541789a1d11ee3b4439'
$OfficialArchiveUrl = 'https://builds.dotnet.microsoft.com/dotnet/Runtime/8.0.30/dotnet-runtime-8.0.30-win-x64.zip'
$ScriptRoot = (Get-Item -LiteralPath $PSScriptRoot).FullName

function Get-ExistingDirectory {
    param([Parameter(Mandatory = $true)][string]$Path)

    $item = Get-Item -LiteralPath $Path -ErrorAction Stop
    if (-not $item.PSIsContainer) {
        throw "Expected a directory, got a file: $Path"
    }
    return $item.FullName
}

function Get-ExistingFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    $item = Get-Item -LiteralPath $Path -ErrorAction Stop
    if ($item.PSIsContainer) {
        throw "Expected a file, got a directory: $Path"
    }
    return $item.FullName
}

function Get-RelativePath {
    param(
        [Parameter(Mandatory = $true)][string]$BasePath,
        [Parameter(Mandatory = $true)][string]$Path
    )

    return $Path.Substring($BasePath.Length + 1).Replace('\', '/')
}

function Assert-SafeChildPath {
    param(
        [Parameter(Mandatory = $true)][string]$BasePath,
        [Parameter(Mandatory = $true)][string]$RelativePath
    )

    $candidate = [System.IO.Path]::GetFullPath((Join-Path -Path $BasePath -ChildPath $RelativePath.Replace('/', '\')))
    $prefix = $BasePath.TrimEnd('\') + '\'
    if (-not $candidate.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Archive entry escapes the staging directory: $RelativePath"
    }
    return $candidate
}

function Get-AssemblyMetadata {
    param([Parameter(Mandatory = $true)][string]$Path)

    $fileVersion = $null
    $assemblyName = $null
    try {
        $fileVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($Path).FileVersion
    }
    catch {
        $fileVersion = $null
    }
    try {
        $assemblyName = [System.Reflection.AssemblyName]::GetAssemblyName($Path)
    }
    catch {
        $assemblyName = $null
    }

    $result = [ordered]@{}
    if ($null -ne $assemblyName) {
        $result.assemblyVersion = $assemblyName.Version.ToString()
        $result.assemblyName = $assemblyName.Name
        $result.publicKeyToken = (($assemblyName.GetPublicKeyToken() | ForEach-Object { $_.ToString('x2') }) -join '')
    }
    if ($null -ne $fileVersion) {
        $result.fileVersion = $fileVersion
    }
    return $result
}

function Copy-RageComponent {
    param(
        [Parameter(Mandatory = $true)][System.IO.FileInfo]$SourceFile,
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$Component
    )

    $relative = $RelativePath.Replace('\', '/')
    $destination = Assert-SafeChildPath -BasePath $stageFull -RelativePath $relative
    $destinationDirectory = Split-Path -Parent $destination
    New-Item -ItemType Directory -Force -Path $destinationDirectory | Out-Null
    Copy-Item -LiteralPath $SourceFile.FullName -Destination $destination -Force
    $fileOrigins[$relative] = "rage-runtime:$Component"
    [void]$selectedRageFiles.Add($relative)
}

function Test-NewtonsoftJson1304 {
    param([Parameter(Mandatory = $true)][string]$Path)

    $metadata = Get-AssemblyMetadata -Path $Path
    if ($metadata.fileVersion -notlike '13.0.4*') {
        throw "Newtonsoft.Json must be file version 13.0.4; found '$($metadata.fileVersion)' at $Path"
    }
    if ($metadata.assemblyName -ne 'Newtonsoft.Json') {
        throw "The supplied file is not Newtonsoft.Json: $Path"
    }
}

function Find-NewtonsoftJson {
    if (-not [string]::IsNullOrWhiteSpace($NewtonsoftJsonPath)) {
        return Get-ExistingFile -Path $NewtonsoftJsonPath
    }

    $candidates = @(
        (Join-Path $ScriptRoot 'dotnet\resources\NeptuneEvo\bin\Debug\net8.0\Newtonsoft.Json.dll'),
        (Join-Path $ScriptRoot 'dotnet\resources\NeptuneEvoSDK\bin\Debug\net8.0\Newtonsoft.Json.dll'),
        (Join-Path $RageRuntimeFull 'Newtonsoft.Json.dll')
    )
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            try {
                Test-NewtonsoftJson1304 -Path (Get-ExistingFile -Path $candidate)
                return (Get-ExistingFile -Path $candidate)
            }
            catch {
                continue
            }
        }
    }

    throw "Newtonsoft.Json 13.0.4 was not found. Build the migrated project first or pass -NewtonsoftJsonPath explicitly."
}

function Get-BootstrapperTypeValidation {
    param([Parameter(Mandatory = $true)][string]$RuntimeDirectory)

    $bootstrapperPath = Join-Path $RuntimeDirectory 'Bootstrapper.dll'
    if (-not (Test-Path -LiteralPath $bootstrapperPath -PathType Leaf)) {
        throw "Bootstrapper.dll is missing from the staged runtime."
    }

    $alcType = [System.Type]::GetType('System.Runtime.Loader.AssemblyLoadContext, System.Private.CoreLib', $false)
    $assembly = $null
    $loadContext = $null
    $resolver = $null
    try {
        if ($null -ne $alcType) {
            $loadContext = [System.Runtime.Loader.AssemblyLoadContext]::new('RageRuntimeValidation-' + [System.Guid]::NewGuid().ToString('N'), $true)
            $resolver = [Func[System.Runtime.Loader.AssemblyLoadContext, System.Reflection.AssemblyName, System.Reflection.Assembly]]{
                param($context, $assemblyName)
                $candidate = Join-Path $RuntimeDirectory ($assemblyName.Name + '.dll')
                if (Test-Path -LiteralPath $candidate -PathType Leaf) {
                    try {
                        return $context.LoadFromAssemblyPath($candidate)
                    }
                    catch {
                        return $null
                    }
                }
                return $null
            }
            $loadContext.add_Resolving($resolver)
            $assembly = $loadContext.LoadFromAssemblyPath($bootstrapperPath)
        }
        else {
            $assembly = [System.Reflection.Assembly]::LoadFile($bootstrapperPath)
        }

        try {
            $types = $assembly.GetTypes()
        }
        catch [System.Reflection.ReflectionTypeLoadException] {
            $loaderErrors = @($_.Exception.LoaderExceptions | ForEach-Object { $_.Message })
            throw "Bootstrapper type loading failed: $($loaderErrors -join '; ')"
        }
        if ($types.Count -eq 0) {
            throw 'Bootstrapper.dll loaded but contains no types.'
        }

        return [ordered]@{
            assemblyName = $assembly.GetName().Name
            assemblyVersion = $assembly.GetName().Version.ToString()
            typeCount = $types.Count
        }
    }
    finally {
        if ($null -ne $loadContext) {
            if ($null -ne $resolver) {
                $loadContext.remove_Resolving($resolver)
            }
            $loadContext.Unload()
        }
    }
}

$archiveFull = Get-ExistingFile -Path $DotnetRuntimeArchive
$RageRuntimeFull = Get-ExistingDirectory -Path $RageRuntimePath
$outputInput = [System.IO.Path]::GetFullPath($OutputDirectory)
$outputRoot = [System.IO.Path]::GetPathRoot($outputInput)
$outputFull = if ($outputInput.Length -gt $outputRoot.Length) { $outputInput.TrimEnd('\') } else { $outputRoot }

if ([System.StringComparer]::OrdinalIgnoreCase.Equals($RageRuntimeFull, $outputFull)) {
    throw 'OutputDirectory must be different from RageRuntimePath; the old runtime is never modified in place.'
}
if ([System.StringComparer]::OrdinalIgnoreCase.Equals($ScriptRoot, $outputFull)) {
    throw 'OutputDirectory must not be the repository root.'
}
if ([System.StringComparer]::OrdinalIgnoreCase.Equals($outputFull.TrimEnd('\') + '\', $outputRoot)) {
    throw 'OutputDirectory must not be a filesystem root.'
}
if (Test-Path -LiteralPath $outputFull -PathType Leaf) {
    throw "OutputDirectory is a file: $outputFull"
}
if ((Test-Path -LiteralPath $outputFull -PathType Container) -and -not $Force) {
    $existingFiles = @(Get-ChildItem -LiteralPath $outputFull -File -Recurse -ErrorAction Stop)
    if ($existingFiles.Count -gt 0) {
        throw "OutputDirectory is not empty. Use -Force only when replacing this exact pilot output: $outputFull"
    }
}

$archiveSha512 = (Get-FileHash -LiteralPath $archiveFull -Algorithm SHA512).Hash.ToLowerInvariant()
if ($archiveSha512 -ne $ExpectedArchiveSha512) {
    throw "The runtime archive SHA-512 does not match official .NET $RuntimeVersion win-x64 metadata. Expected $ExpectedArchiveSha512, found $archiveSha512."
}

$newtonsoftFull = Find-NewtonsoftJson
Test-NewtonsoftJson1304 -Path $newtonsoftFull

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('redage-runtime-' + [System.Guid]::NewGuid().ToString('N'))
$stageFull = Join-Path $tempRoot 'runtime'
$fileOrigins = @{}
$selectedRageFiles = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$zip = $null

try {
    New-Item -ItemType Directory -Force -Path $stageFull | Out-Null
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($archiveFull)
    $appPrefix = "shared/Microsoft.NETCore.App/$RuntimeVersion/"
    $appEntries = @($zip.Entries | Where-Object { $_.FullName.StartsWith($appPrefix, [System.StringComparison]::Ordinal) })
    if ($appEntries.Count -eq 0) {
        throw "The archive does not contain $appPrefix"
    }

    foreach ($entry in $appEntries) {
        $relative = $entry.FullName.Substring($appPrefix.Length)
        if ([string]::IsNullOrWhiteSpace($relative) -or $relative.EndsWith('/')) {
            continue
        }
        $destination = Assert-SafeChildPath -BasePath $stageFull -RelativePath $relative
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination) | Out-Null
        $inputStream = $null
        $outputStream = $null
        try {
            $inputStream = $entry.Open()
            $outputStream = [System.IO.File]::Open($destination, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
            $inputStream.CopyTo($outputStream)
        }
        finally {
            if ($null -ne $outputStream) { $outputStream.Dispose() }
            if ($null -ne $inputStream) { $inputStream.Dispose() }
        }
        $fileOrigins[$relative] = "official-dotnet-runtime:$RuntimeVersion"
    }

    foreach ($required in @('coreclr.dll', 'hostpolicy.dll', 'System.Private.CoreLib.dll', 'Microsoft.NETCore.App.deps.json')) {
        if (-not (Test-Path -LiteralPath (Join-Path $stageFull $required) -PathType Leaf)) {
            throw "The official archive did not produce required runtime file: $required"
        }
    }
    $deps = Get-Content -LiteralPath (Join-Path $stageFull 'Microsoft.NETCore.App.deps.json') -Raw | ConvertFrom-Json
    if ($deps.runtimeTarget.name -notlike '*Version=v8.0*') {
        throw "The staged runtime deps file is not .NET 8: $($deps.runtimeTarget.name)"
    }

    $rageFiles = @(Get-ChildItem -LiteralPath $RageRuntimeFull -File -Recurse)
    $rageRootFiles = @($rageFiles | Where-Object { $_.Directory.FullName -eq $RageRuntimeFull })

    foreach ($file in $rageRootFiles | Where-Object { $_.Name -like 'Bootstrapper*.dll' -or $_.Name -like 'Bootstrapper*.xml' }) {
        Copy-RageComponent -SourceFile $file -RelativePath $file.Name -Component 'Bootstrapper'
    }
    foreach ($name in @('MessagePack.dll', 'MessagePack.Annotations.dll')) {
        $file = $rageRootFiles | Where-Object { $_.Name -eq $name } | Select-Object -First 1
        if ($null -ne $file) { Copy-RageComponent -SourceFile $file -RelativePath $file.Name -Component 'MessagePack' }
    }
    foreach ($file in $rageRootFiles | Where-Object {
        $_.Name -like 'Microsoft.CodeAnalysis*.dll' -or
        $_.Name -eq 'Microsoft.Build.Tasks.CodeAnalysis.dll' -or
        $_.Name -eq 'Microsoft.DiaSymReader.Native.amd64.dll'
    }) {
        Copy-RageComponent -SourceFile $file -RelativePath $file.Name -Component 'Roslyn'
    }
    foreach ($file in $rageFiles | Where-Object {
        $_.Directory.FullName -ne $RageRuntimeFull -and $_.Name -like 'Microsoft.CodeAnalysis*.resources.dll'
    }) {
        Copy-RageComponent -SourceFile $file -RelativePath (Get-RelativePath -BasePath $RageRuntimeFull -Path $file.FullName) -Component 'Roslyn'
    }
    foreach ($name in @('Colorful.Console.dll', 'Ben.Demystifier.dll', 'NeoSmart.Hashing.dll', 'xxHash.dll', 'Standart.Hash.xxHash.dll', 'Microsoft.Bcl.AsyncInterfaces.dll')) {
        $file = $rageRootFiles | Where-Object { $_.Name -eq $name } | Select-Object -First 1
        if ($null -ne $file) { Copy-RageComponent -SourceFile $file -RelativePath $file.Name -Component 'RAGE support' }
    }
    foreach ($file in $rageRootFiles | Where-Object { $_.Name -like 'System.Composition.*.dll' }) {
        Copy-RageComponent -SourceFile $file -RelativePath $file.Name -Component 'System.Composition'
    }

    if (-not $selectedRageFiles.Contains('Bootstrapper.dll')) {
        throw 'Bootstrapper.dll was not found in the old RAGE runtime.'
    }

    Copy-Item -LiteralPath $newtonsoftFull -Destination (Join-Path $stageFull 'Newtonsoft.Json.dll') -Force
    $fileOrigins['Newtonsoft.Json.dll'] = 'Newtonsoft.Json:13.0.4'

    $forbiddenPatterns = @(
        '^coreclr\.dll$', '^hostpolicy\.dll$', '^hostfxr\.dll$', '^System\.(?!Composition\.).+\.dll$',
        '^Microsoft\.NETCore\.App\..*$', '^dbgshim\.dll$', '^sos.*\.dll$', '^SOS.*\.dll$',
        '^mscordaccore.*\.dll$', '^mscordbi\.dll$', '^mscorrc.*\.dll$', '^clrgc\.dll$',
        '^createdump\.exe$', '\.pdb$'
    )
    $oldForbidden = @($rageFiles | Where-Object {
        $name = $_.Name
        @($forbiddenPatterns | Where-Object { $name -match $_ }).Count -gt 0
    })
    $copiedForbidden = @($selectedRageFiles | Where-Object {
        $name = [System.IO.Path]::GetFileName($_)
        @($forbiddenPatterns | Where-Object { $name -match $_ }).Count -gt 0
    })
    if ($copiedForbidden.Count -gt 0) {
        throw "Forbidden old-runtime files were selected: $($copiedForbidden -join ', ')"
    }

    $bootstrapperValidation = Get-BootstrapperTypeValidation -RuntimeDirectory $stageFull

    $runtimeArchitecture = if ([IntPtr]::Size -eq 8) { 'x64/AMD64' } else { 'x86' }
    if ($runtimeArchitecture -ne 'x64/AMD64') {
        throw 'The preparation script must run in a 64-bit PowerShell process.'
    }

    $fileRecords = @(
        foreach ($file in (Get-ChildItem -LiteralPath $stageFull -File -Recurse | Sort-Object FullName)) {
            $relative = Get-RelativePath -BasePath $stageFull -Path $file.FullName
            $metadata = Get-AssemblyMetadata -Path $file.FullName
            $record = [ordered]@{
                path = $relative
                source = if ($fileOrigins.ContainsKey($relative)) { $fileOrigins[$relative] } else { 'unknown' }
                length = $file.Length
                sha256 = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
            }
            if ($metadata.Count -gt 0) { $record.assembly = $metadata }
            [pscustomobject]$record
        }
    )

    $manifest = [ordered]@{
        schemaVersion = 1
        generatedUtc = [DateTime]::UtcNow.ToString('o')
        build = [ordered]@{
            script = 'Prepare-RageRuntime.ps1'
            layout = 'flat-rage-runtime'
            architecture = $runtimeArchitecture
            rid = $RuntimeRid
        }
        officialDotnetRuntime = [ordered]@{
            framework = 'Microsoft.NETCore.App'
            version = $RuntimeVersion
            rid = $RuntimeRid
            archive = Split-Path -Leaf $archiveFull
            archiveUrl = $OfficialArchiveUrl
            archiveSha512 = $archiveSha512
        }
        sourceRageRuntime = [ordered]@{
            directory = Split-Path -Leaf $RageRuntimeFull
            selectedFileCount = $selectedRageFiles.Count
            forbiddenCandidateCount = $oldForbidden.Count
            forbiddenCandidatePatterns = $forbiddenPatterns
            forbiddenCandidatesAreNotCopied = ($copiedForbidden.Count -eq 0)
        }
        newtonsoftJson = [ordered]@{
            version = '13.0.4'
            sourceFile = Split-Path -Leaf $newtonsoftFull
            sha256 = (Get-FileHash -LiteralPath $newtonsoftFull -Algorithm SHA256).Hash.ToLowerInvariant()
        }
        validation = [ordered]@{
            bootstrapper = $bootstrapperValidation
            dotnetDepsRuntimeTarget = $deps.runtimeTarget.name
            oldRuntimeFilesNotMerged = $true
        }
        files = $fileRecords
    }

    $manifestJson = $manifest | ConvertTo-Json -Depth 8
    $manifestPath = Join-Path $stageFull 'rage-runtime-manifest.json'
    Set-Content -LiteralPath $manifestPath -Value $manifestJson -Encoding UTF8

    if (Test-Path -LiteralPath $outputFull -PathType Container) {
        Remove-Item -LiteralPath $outputFull -Recurse -Force
    }
    Move-Item -LiteralPath $stageFull -Destination $outputFull
    Write-Output "Prepared clean RAGE runtime: $outputFull"
    Write-Output "Bootstrapper types loaded: $($bootstrapperValidation.typeCount)"
    Write-Output "Files written: $($fileRecords.Count + 1) (manifest included)"
    Write-Output "Manifest: $(Join-Path $outputFull 'rage-runtime-manifest.json')"
}
finally {
    if ($null -ne $zip) { $zip.Dispose() }
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
