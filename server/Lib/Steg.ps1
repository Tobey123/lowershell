function Decode-Fake-Ver {
<#
.SYNOPSIS

Decode a hidden integer pretend to be a version number from Image's EXIF tag

.PARAMETER img

Carrier image object

.EXAMPLE

$img = [System.Drawing.Image]::FromFile($path)
$num = Decode-Fake-Ver $img

#>
    param([string]$ver)

    $ver -match "((\d+\.)*\d)+" | Out-Null
    $ver = $matches[0].ToCharArray()
    [Array]::Reverse($ver)
    $ver = -join $ver -split "\."
    return $ver[$ver.Count..1] | foreach {$num = 0;$base = [Convert]::ToInt32($ver[0])} {
        $num *= $base
        $num += [Convert]::ToInt32($_)
    } {$num}
}

function Extract-Steg {
<#
.SYNOPSIS

Extract hidden message from an image using LSB algorithm

.PARAMETER $filename

Path to the carrier image

.EXAMPLE

Extract-Steg "path-to-some-image.png"
#>
    param([string]$filename)

    [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
    [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing.Imaging") | Out-Null

    $path = (Get-ChildItem $filename).FullName    
    $base64_alphabet = -join [char[]]([char]'A'..[char]'Z' + [char]'a'..[char]'z' + [char]'0'..[char]'9') + '+/'
    $img = [System.Drawing.Image]::FromFile($path)
	
	$TAG_SOFT = 305
    $soft = $img.PropertyItems | where {$_.Id -eq $TAG_SOFT} | % {[System.Text.Encoding]::ASCII.GetString($_.Value)}
    $payload_len = Decode-Fake-Ver $soft

	# read image
    $rect = [System.Drawing.Rectangle]::FromLTRB(0, 0, $img.width, $img.height)
    $mode = [System.Drawing.Imaging.ImageLockMode]::ReadOnly
    $format = [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    $data = $img.LockBits($rect, $mode, $img.PixelFormat)
    $size = [Math]::Abs($data.Stride) * $img.Height
    $pixels = New-Object Byte[] $size
    [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $pixels, 0, $size)
    $img.Dispose()

	# decode binary data
    $len = $payload_len / 6
    $buf = New-Object char[] $len
    $mod = $len % 4
    $padding = ''
    if ($mod) {
        $padding = '=' * (4 - $mod)
    }
    for ($i = 0; $i -lt $len; $i++) {
        # note: order of each color channel differs from PIL
        $buf[$i] = (2..0 + 5..3) | % {$val = 0; $j = 0} {
            $val += ($pixels[$i * 6 + $j] -band 1) -shl $_
            $j++
        } {$base64_alphabet[$val]}
    }
    $buf = (-join $buf) + $padding
    return [System.Convert]::FromBase64String($buf)
}
