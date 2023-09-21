param (
    # Build mode
    [Parameter()]
    [ValidateSet('Debug', 'Release', 'Checked', 'Profile')]
    [string]
    $Mode = "Release",

    # Only
    [Parameter()]
    [ValidateSet('wasm', 'webassembly', 'asm.js', 'asm')]
    [string]
    $Only,

    # Engine path
    [Parameter()]
    [string]
    $EnginePath = "../../cocos-engine"
)

$includingWebAssembly = (-not $Only) -or ($Only.ToLower() -in "wasm", "webassembly")
$includingAsmJs = (-not $Only) -or ($Only.ToLower() -in "asm.js", "asm")

Write-Host "Start build"
Write-Host "Including WebAssembly: $includingWebAssembly"
Write-Host "Including asm.js: $includingAsmJs"

if (-not $env:EMSCRIPTEN) {
    if ($env:EMSDK) {
        $env:EMSCRIPTEN = "$env:EMSDK/upstream/emscripten"
    }
}
if (-not $env:EMSCRIPTEN) {
    Write-Error "Environment variable 'EMSCRIPTEN' is not set. " +
            "Either set it to <emsdk>/upstream/emscripten, or set environment variable 'EMSDK' to location of <emsdk>."
    exit -1
}

try {
    Push-Location

    Measure-Command {
        $baseDir = $PSScriptRoot
        $buildMode=$Mode.ToLower()
        $scriptSuffix = if ($IsWindows) { ".bat" } else { ".sh" }

        function Output {
            param ([string]$filename)

            $source = "$baseDir/physx/bin/emscripten/$buildMode/$filename"
            $target1 = "$baseDir/builds/$filename"
            New-Item -ItemType Directory -Force (Split-Path $target1 -Parent) | Out-Host
            Copy-Item -Recurse -Force $source $target1 | Out-Host
            $target2 = "$EnginePath/native/external/emscripten/physx/$filename"
            New-Item -ItemType Directory -Force (Split-Path $target2 -Parent) | Out-Host
            Copy-Item -Recurse -Force $source $target2 | Out-Host
        }

        if ($includingAsmJs) {
            Set-Location $baseDir

            Write-Host "Building asm.js"
            Write-Host "Generating..."

            Set-Location ./physx
            & "./generate_projects${scriptSuffix}" emscripten-js | Out-Host

            Write-Host "Compiling..."
            Set-Location "compiler/emscripten-js-$buildMode"
            ninja | Out-Host

            Write-Host "Copying..."
            Output("physx.$buildMode.asm.js")
        }

        ###########################################################################

        if ($includingWebAssembly) {
            Set-Location $baseDir

            Write-Host "Building WebAssembly"
            Write-Host "Generating..."
    
            Set-Location physx/
            & "./generate_projects${scriptSuffix}" emscripten-wasm | Out-Host
    
            Write-Host "Compiling..."
            Set-Location "compiler/emscripten-wasm-$buildMode"
            ninja | Out-Host

            Write-Host "Copying..."
            Output("physx.$buildMode.wasm.js")
            Output("physx.$buildMode.wasm.wasm")
        }
    }
} finally {
    Pop-Location
}