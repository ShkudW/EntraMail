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
        [switch]$StopOnFirstMatch,

        [Parameter(Mandatory=$false)]
        [int]$Delay = 5  # Default delay is set to 5 seconds if not specified
    )

    function Show-Banner {
        Write-Host " _____       _             __  __       _ _ " -ForegroundColor DarkCyan
        Write-Host "| ____|_ __ | |_ _ __ __ _|  \/  | __ _(_) |" -ForegroundColor DarkCyan
        Write-Host "|  _| | '_ \| __| '__/ _  | |\/| |/ _  | | |" -ForegroundColor DarkCyan
        Write-Host "| |___| | | | |_| | | (_| | |  | | (_| | | |" -ForegroundColor DarkCyan
        Write-Host "|_____|_| |_|\__|_|  \__,_|_|  |_|\__,_|_|_|" -ForegroundColor DarkCyan
        Write-Host "                                            " -ForegroundColor DarkCyan
        Write-Host "         Find Your UPN in EntraID" -ForegroundColor DarkCyan
        Write-Host "                 By ShkudW" -ForegroundColor DarkCyan
        Write-Host "  https://github.com/ShkudW/EntraMail" -ForegroundColor DarkCyan
        Write-Host "=============================================================" -ForegroundColor DarkCyan
        Write-Host ""
    }



  function Show-Help {
        Write-Host "Available Flags:" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  -FirstName : First name of the user." -ForegroundColor Yellow
        Write-Host "  -LastName : Last name of the user." -ForegroundColor Yellow
        Write-Host "  -NamesFile : Path to file with first and last names." -ForegroundColor Yellow
        Write-Host "  -UsernameFile : Path to file with usernames." -ForegroundColor Yellow
        Write-Host "  -DomainName : The domain name (Required)." -ForegroundColor Yellow
        Write-Host "  -OutputFilePath : Path to save output file in HTML format." -ForegroundColor Yellow
        Write-Host "  -StopOnFirstMatch : Stop after finding the first valid user ((Optional)) (can be used only with -FirstName -LastName or -NamesFile)." -ForegroundColor Yellow
        Write-Host "  -Delay : Control the delay time between requests (Default 5 Seconds)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Usage Examples:" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  Invoke-EntraMail -FirstName john -LastName doe -DomainName example.com" -ForegroundColor Green
        Write-Host "  Invoke-EntraMail -NamesFile names.txt -DomainName example.com -StopOnFirstMatch" -ForegroundColor Green
        Write-Host "  Invoke-EntraMail -UsernameFile usernames.txt -DomainName example.com -OutputFilePath report.html" -ForegroundColor Green
        Write-Host ""
        Write-Host "File Examples:" -ForegroundColor Cyan
        Write-Host ""
        Write-Host " NamesFile:" -ForegroundColor Green
        Write-Host " ---------" -ForegroundColor Green
        Write-Host " fname1 lname1" -ForegroundColor Green
        Write-Host " fname2 lname2" -ForegroundColor Green
        Write-Host " fname3 lname3" -ForegroundColor Green
        Write-Host ""
        Write-Host " UserNamesFile:" -ForegroundColor Green
        Write-Host " -------------" -ForegroundColor Green
        Write-Host " username1" -ForegroundColor Green
        Write-Host " username2" -ForegroundColor Green
        Write-Host " username3" -ForegroundColor Green
        Write-Host ""
    }

    
    Show-Banner

    
    if (-not $UsernameFile -and -not $DomainName -and -not $FirstName -and -not $LastName -and -not $NamesFile -and -not $OutputFilePath -and -not $StopOnFirstMatch) {
        Show-Help
        return
    }


    # Domain validation
    if (-not $DomainName) {
        Write-Host "Error: The -DomainName flag is required." -ForegroundColor Red
        return
    }

    # Tenant checking function
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

    $tenantId = Check-Tenant -domain $DomainName
    if ($tenantId -eq "invalid_tenant") {
        Write-Host "Error: The domain '$DomainName' does not have a valid Tenant ID." -ForegroundColor Red
        return
    } elseif ($tenantId -eq "error") {
        Write-Host "Error: An unexpected error occurred while checking the domain '$DomainName'." -ForegroundColor Red
        return
    } else {
        Write-Host "Tenant found: The Tenant ID for domain '$DomainName' is $tenantId." -ForegroundColor Green
        Write-Host "=============================================================" -ForegroundColor DarkCyan
    }

    # Username combinations generator
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

    $validUsers = @()

    # Checking -FirstName and -LastName combination
    if ($FirstName -and $LastName) {
        $UserNameCombos = Get-UsernameCombinations -FirstName $FirstName -LastName $LastName
        
        foreach ($UserName in $UserNameCombos) {
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
                    if ($StopOnFirstMatch) {
                        break
                    }
                } else {
                    Write-Host "The user ${fullUserName} does not exist in Azure AD." -ForegroundColor Red
                }
            } catch {
                Write-Host "An error occurred while checking ${fullUserName}: $_" -ForegroundColor Red
            }

            # Apply delay between API requests
            Start-Sleep -Seconds $Delay
        }
    }

    # Checking file with -NamesFile
    elseif ($NamesFile) {
        $names = Get-Content -Path $NamesFile
        foreach ($name in $names) {
            $split = $name -split "\s+"
            if ($split.Length -ge 2) {
                $FirstName = $split[0]
                $LastName = $split[1]
                $UserNameCombos = Get-UsernameCombinations -FirstName $FirstName -LastName $LastName
                
                foreach ($UserName in $UserNameCombos) {
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

                            if ($StopOnFirstMatch) {
                                break
                            }
                        } else {
                            Write-Host "The user ${fullUserName} does not exist in Azure AD." -ForegroundColor Red
                        }
                    } catch {
                        Write-Host "An error occurred while checking ${fullUserName}: $_" -ForegroundColor Red
                    }

                    # Apply delay between API requests
                    Start-Sleep -Seconds $Delay
                }

                if ($StopOnFirstMatch -and $validUsers) {
                    continue
                }
            }
        }
    }

    # Checking file with -UsernameFile
    elseif ($UsernameFile) {
        $usernames = Get-Content -Path $UsernameFile
        foreach ($username in $usernames) {
            $fullUserName = "${username}@${DomainName}"

            try {
                $getCredentialTypeUrl = "https://login.microsoftonline.com/common/GetCredentialType"
                $body = @{
                    Username = $fullUserName
                } | ConvertTo-Json

                $response = Invoke-RestMethod -Uri $getCredentialTypeUrl -Method Post -Body $body -ContentType "application/json"

                if ($response.IfExistsResult -eq 0) {
                    Write-Host "The user ${fullUserName} exists in Azure AD." -ForegroundColor Green
                    $validUsers += $fullUserName
                } else {
                    Write-Host "The user ${fullUserName} does not exist in Azure AD." -ForegroundColor Red
                }
            } catch {
                Write-Host "An error occurred while checking ${fullUserName}: $_" -ForegroundColor Red
            }

            # Apply delay between API requests
            Start-Sleep -Seconds $Delay
        }
    }

    # Save results to HTML
    if ($OutputFilePath -and $validUsers) {
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
