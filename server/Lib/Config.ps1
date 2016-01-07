function Get-Images {
<#
.SYNOPSIS

Load image from social network

.PARAMETER tag

The hash tag

.EXAMPLE

$files = Get-Images "ThisIsAUniqueSecretTag"

#>
    param([string]$tag)

    $url = "http://www.lofter.com/tag/" + $tag
    $req = Invoke-WebRequest $url
    $req.Images | where {$_.'data-origin'} | % {
            $full = $_.'data-origin' -replace "\?imageView.*$"
            $filename = [System.IO.Path]::GetTempFileName()
            Invoke-WebRequest -OutFile $filename $full
            return $filename
        }
}