Import-Module "steg"

$url = "http://www.lofter.com/tag/%e9%94%9f%e6%96%a4%e6" + 
    "%8b%b7%e9%94%9f%e6%96%a4%e6%8b%b7%e9%94%9f%e6%96%a4" +
    "%e6%8b%b7%e9%94%9f%e6%96%a4%e6%8b%b7"

$images = (Invoke-WebRequest ($url)).Images | 
    where {$_.'data-origin'} | % {
        $full = $_.'data-origin' -replace "\?imageView.*$"
        $filename = [System.IO.Path]::GetTempFileName()
        Invoke-WebRequest -OutFile $filename $full
        $buf = Extract-Steg $filename 
        $info = [System.Text.Encoding]::ASCII.GetString($buf)
        Write-Host $info
        Remove-Item -Force $filename
    }
