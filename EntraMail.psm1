function Invoke-EntraMail {
    param (
        [Parameter(Mandatory=$false)]
        [string]$UsernameFile,

        [Parameter(Mandatory=$false)]
        [string]$DomainName,

        [Parameter(Mandatory=$false)]
        [string]$FirstName,

        [Parameter(Mandatory=$false)]
        [string]$LastName,

        [Parameter(Mandatory=$false)]
        [string]$NamesFile,

        [Parameter(Mandatory=$false)]
        [string]$OutputFilePath,

        [Parameter(Mandatory=$false)]
        [switch]$StopOnFirstMatch
    )

    
    function Show-Banner {
        Write-Host " _____       _             __  __       _ _ " -ForegroundColor DarkCyan
        Write-Host "| ____|_ __ | |_ _ __ __ _|  \/  | __ _(_) |" -ForegroundColor DarkCyan
        Write-Host "|  _| | '_ \| __| '__/ _  | |\/| |/ _  | | |" -ForegroundColor DarkCyan
        Write-Host "| |___| | | | |_| | | (_| | |  | | (_| | | |" -ForegroundColor DarkCyan
        Write-Host "|_____|_| |_|\__|_|  \__,_|_|  |_|\__,_|_|_|" -ForegroundColor DarkCyan
        Write-Host "                                            " -ForegroundColor DarkCyan
        Write-Host "         Find Your upn on EntraID" -ForegroundColor DarkCyan
        Write-Host "                 By ShkudW" -ForegroundColor DarkCyan
        Write-Host "  https://github.com/ShkudW/EntraMail" -ForegroundColor DarkCyan
        Write-Host "=============================================================" -ForegroundColor DarkCyan
        Write-Host ""
    }

    
    function Show-Help {
        Write-Host "Available Flags:" -ForegroundColor Cyan
        Write-Host "  -FirstName [string]   : First name of the user." -ForegroundColor Yellow
        Write-Host "  -LastName [string]    : Last name of the user." -ForegroundColor Yellow
        Write-Host "  -NamesFile [string]   : Path to file with first and last names." -ForegroundColor Yellow
        Write-Host "  -UsernameFile [string]: Path to file with usernames." -ForegroundColor Yellow
        Write-Host "  -DomainName [string]  : The domain name (Required)." -ForegroundColor Yellow
        Write-Host "  -OutputFilePath [string]: Path to save output file in HTML format." -ForegroundColor Yellow
        Write-Host "  -StopOnFirstMatch [switch]: Stop after finding the first valid user (can be used only with -FirstName -LastName or -NamesFile)." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Usage Examples:" -ForegroundColor Cyan
        Write-Host "  Invoke-EntraMail -FirstName john -LastName doe -DomainName example.com" -ForegroundColor Green
        Write-Host "  Invoke-EntraMail -NamesFile names.txt -DomainName example.com -StopOnFirstMatch" -ForegroundColor Green
        Write-Host "  Invoke-EntraMail -UsernameFile usernames.txt -DomainName example.com -OutputFilePath report.html" -ForegroundColor Green
    }

    
    Show-Banner

    
    if (-not $UsernameFile -and -not $DomainName -and -not $FirstName -and -not $LastName -and -not $NamesFile -and -not $OutputFilePath -and -not $StopOnFirstMatch) {
        Show-Help
        return
    }

    
    function Check-Tenant {
        param (
            [string]$domain
        )

        $openIdConfigUrl = "https://login.microsoftonline.com/$domain/v2.0/.well-known/openid-configuration"

        try {
            $response = Invoke-RestMethod -Uri $openIdConfigUrl -Method Get -ContentType "application/json"
            if ($response.issuer) {
                $tenantId = $response.issuer -replace "https://login.microsoftonline.com/([^/]+)/.*", '$1'
                return $tenantId
            } else {
                return $null
            }
        }
        catch {
            $errorResponse = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorResponse)
            $responseBody = $reader.ReadToEnd() | ConvertFrom-Json

            if ($responseBody.error -eq "invalid_tenant") {
                return "invalid_tenant"
            } else {
                return "error"
            }
        }
    }

    
    if ($StopOnFirstMatch) {
        if (-not ($FirstName -and $LastName) -and -not $NamesFile) {
            Write-Host "The -StopOnFirstMatch flag can only be used with -FirstName and -LastName, or -NamesFile." -ForegroundColor Red
            return
        }
        if ($UsernameFile) {
            Write-Host "The -StopOnFirstMatch flag cannot be used with -UsernameFile." -ForegroundColor Red
            return
        }
    }

    
    if (-not $DomainName) {
        Write-Host "Error: The -DomainName flag is required." -ForegroundColor Red
        return
    }

    $tenantId = Check-Tenant -domain $DomainName
    if ($tenantId -eq "invalid_tenant") {
        Write-Host "Error: The domain '$DomainName' does not have a valid Tenant ID." -ForegroundColor Red
        return
    } elseif ($tenantId -eq "error") {
        Write-Host "Error: An unexpected error occurred while checking the domain '$DomainName'." -ForegroundColor Red
        return
    } elseif (-not $tenantId) {
        Write-Host "Error: No valid Tenant found for domain '$DomainName'." -ForegroundColor Red
        return
    } else {
        Write-Host "Tenant found: The Tenant ID for domain '$DomainName' is $tenantId." -ForegroundColor Green
        Write-Host "=============================================================" -ForegroundColor DarkCyan
    }

    
    function Get-UsernameCombinations {
        param (
            [string]$FirstName,
            [string]$LastName
        )

        return @(
            "$FirstName"
            "$LastName"
            "$FirstName$LastName"
            "$FirstName.$LastName"
            "$LastName$FirstName"
            "$LastName.$FirstName"
            "$FirstName$($LastName.Substring(0,1))"
            "$LastName$($FirstName.Substring(0,1))"
            "$($FirstName.Substring(0,1))$LastName"
            "$($LastName.Substring(0,1))$FirstName"
            "$FirstName$($LastName.Substring(0,2))"
            "$LastName$($FirstName.Substring(0,2))"
            "$($FirstName.Substring(0,2))$LastName"
            "$($LastName.Substring(0,2))$FirstName"
            "$FirstName$($LastName.Substring(0,3))"
            "$LastName$($FirstName.Substring(0,3))"
            "$($FirstName.Substring(0,3))$LastName"
            "$($LastName.Substring(0,3))$FirstName"
        )
    }

    $UserNames = @()
    $validUsers = @()
    $firstValidUser = $null
    $firstValidResponse = $null

    
    if ($FirstName -and $LastName) {
        $UserNames = Get-UsernameCombinations -FirstName $FirstName -LastName $LastName
    }
    elseif ($UsernameFile) {
        $UserNames = Get-Content -Path $UsernameFile
    }
    elseif ($NamesFile) {
        $names = Get-Content -Path $NamesFile
        foreach ($name in $names) {
            $split = $name -split "\s+"
            if ($split.Length -ge 2) {
                $FirstName = $split[0]
                $LastName = $split[1]
                $UserNameCombos = Get-UsernameCombinations -FirstName $FirstName -LastName $LastName
                $UserNames += $UserNameCombos
            }
        }
    }
    else {
        Write-Host "Please provide either -FirstName with -LastName, -UsernameFile, or -NamesFile." -ForegroundColor Yellow
        return
    }

    $UserNames = $UserNames | Sort-Object | Get-Unique

    
    foreach ($UserName in $UserNames) {
        $fullUserName = "${UserName}@${DomainName}"

        try {
            $getCredentialTypeUrl = "https://login.microsoftonline.com/common/GetCredentialType"
            $body = @{
                Username = $fullUserName
            } | ConvertTo-Json

            $response = Invoke-RestMethod -Uri $getCredentialTypeUrl -Method Post -Body $body -ContentType "application/json"

            if ($response.IfExistsResult -eq 0) {
                Write-Host "The user ${fullUserName} exists in Azure AD." -ForegroundColor Green
                $validUsers += $fullUserName

                if (-not $firstValidUser) {
                    $firstValidUser = $fullUserName
                    $firstValidResponse = $response
                }

                if ($StopOnFirstMatch) {
                    break
                }
            } else {
                Write-Host "The user ${fullUserName} does not exist in Azure AD." -ForegroundColor Red
            }

            Start-Sleep -Seconds 7

            if ($firstValidUser) {
                $checkBody = @{
                    Username = $firstValidUser
                } | ConvertTo-Json

                $checkResponse = Invoke-RestMethod -Uri $getCredentialTypeUrl -Method Post -Body $checkBody -ContentType "application/json"

                if ($checkResponse.IfExistsResult -ne $firstValidResponse.IfExistsResult) {
                    Write-Host "Potential IP block detected. Please change your IP address." -ForegroundColor Yellow
                    return
                }
            }
        }
        catch {
            Write-Host "An error occurred while checking ${fullUserName}: $_" -ForegroundColor Red
        }
    }

    $validUsers = $validUsers | Sort-Object

    if (-not $validUsers) {
        Write-Host "No valid users were found. Please check your inputs." -ForegroundColor Yellow
        return
    }

    
    if ($OutputFilePath) {
        $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>EntraMail - Valid Users in EntraID</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 20px; background-color: #121212; color: #e0e0e0; }
        .container { max-width: 800px; margin: auto; background-color: #1e1e1e; padding: 20px; border-radius: 8px; box-shadow: 0px 0px 15px rgba(0, 0, 0, 0.5); }
        h1 { text-align: center; color: #00adb5; font-size: 2.5em; margin-bottom: 0; }
        h2 { text-align: center; color: #c0c0c0; font-size: 1.2em; margin-top: 5px; }
        .copyright { text-align: center; color: #555; margin-bottom: 20px; font-size: 0.9em; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { padding: 10px; border: 1px solid #333; text-align: left; }
        th { background-color: #00adb5; color: #121212; }
        tr:nth-child(even) { background-color: #2c2c2c; }
        tr:nth-child(odd) { background-color: #1e1e1e; }
        button { display: block; margin: 20px auto; padding: 10px 20px; font-size: 16px; cursor: pointer; background-color: #00adb5; color: #121212; border: none; border-radius: 5px; transition: background-color 0.3s ease; }
        button:hover { background-color: #007b9e; }
    </style>
    <script>
        function downloadTXT() {
            var validUsers = [
"@

        foreach ($user in $validUsers) {
            $html += "'$user'," + "`n"
        }

        $html = $html.TrimEnd(",`n")
        $html += @"
            ];
            var text = validUsers.join('\n');
            var blob = new Blob([text], { type: 'text/plain' });
            var anchor = document.createElement('a');
            anchor.download = 'ValidUsers.txt';
            anchor.href = window.URL.createObjectURL(blob);
            anchor.target ='_blank';
            anchor.style.display = 'none'; // just to be safe!
            document.body.appendChild(anchor);
            anchor.click();
            document.body.removeChild(anchor);
        }
    </script>
</head>
<body>
    <div class="container">
        <h1>EntraMail</h1>
        <h2>Valid Users in EntraID</h2>
        <div class="copyright">© By ShkudW</div>
        <button onclick="downloadTXT()">Download as TXT File</button>
        <table>
            <tr><th>Username</th></tr>
"@

        foreach ($user in $validUsers) {
            $html += "<tr><td>$user</td></tr>`n"
        }

        $html += @"
        </table>
    </div>
</body>
</html>
"@

        $html | Out-File -FilePath $OutputFilePath -Encoding UTF8

        Write-Host "The list of valid users has been saved to $OutputFilePath." -ForegroundColor Cyan
    }
}

Export-ModuleMember -Function Invoke-EntraMail
