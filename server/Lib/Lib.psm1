Get-ChildItem (Join-Path $PSScriptRoot *.ps1) | ? {-Not ($_.BaseName -contains "__init__")} | % { . $_.FullName}