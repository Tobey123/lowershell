$tag = "��������"
$base = "http://www.lofter.com/tag/"
$images = (Invoke-WebRequest ($base + [System.Web.HttpUtility]::UrlEncode($tag))).Images | 
    where {$_.'data-origin'} | % {
        $full = $_.'data-origin' -replace "\?imageView.*$"
        $filename = [System.IO.Path]::GetTempFileName()
        Invoke-WebRequest -OutFile $filename $full

        Write-Host $filename
        # Remove-Item -Force $filename
    }

