Properties `
{
    $Configuration = $null
}

$root = $PSScriptRoot
$src = Resolve-Path "$root\..\src"

Task pre-build -description 'Restore NuGet packages, copy configs.' `
{
    Initialize-MSBuild
    Invoke-NugetRestore -SolutionPath "$src\BlueGreenTest.sln"
}

Task build -depends pre-build -description '* Build all projects.' `
    -requiredVariables @('Configuration') `
{
    Invoke-SolutionBuild -SolutionPath "$src\BlueGreenTest.sln" -Configuration $Configuration
}
