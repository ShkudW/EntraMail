function Invoke-EntraMail {
    param (
        [Parameter(Mandatory=$false)]
        [string]$FilePath,

        [Parameter(Mandatory=$false)]
        [string]$DomainName,

        [Parameter(Mandatory=$false)]
        [string]$PrivateName,

        [Parameter(Mandatory=$false)]
        [string]$LastName,

        [Parameter(Mandatory=$false)]
        [string]$NamesFilePath,

        [Parameter(Mandatory=$false)]
        [string]$OutputFilePath,

        [Parameter(Mandatory=$false)]
        [switch]$StopOnFirstMatch
    )

    
    Write-Host " _____       _             __  __       _ _ " -ForegroundColor DarkCyan
    Write-Host "| ____|_ __ | |_ _ __ __ _|  \/  | __ _(_) |" -ForegroundColor DarkCyan
    Write-Host "|  _| | '_ \| __| '__/ _` | |\/| |/ _` | | |" -ForegroundColor DarkCyan
    Write-Host "| |___| | | | |_| | | (_| | |  | | (_| | | |" -ForegroundColor DarkCyan
    Write-Host "|_____|_| |_|\__|_|  \__,_|_|  |_|\__,_|_|_|" -ForegroundColor DarkCyan
    Write-Host "                                            " -ForegroundColor DarkCyan
    Write-Host "                 EntraMail" -ForegroundColor DarkCyan
    Write-Host "      A tool for finding valid users in Azure AD" -ForegroundColor DarkCyan
    Write-Host "                 By Shaked Wiessman" -ForegroundColor DarkCyan
    Write-Host "=============================================================" -ForegroundColor DarkCyan

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

    
    $url = "https://login.microsoftonline.com/common/GetCredentialType"

    
    if ($PrivateName) {
        if (-not ($LastName -and $DomainName)) {
            Write-Host "When using -PrivateName, you must also provide -LastName and -DomainName." -ForegroundColor Red
            return
        }
        if ($FilePath -or $NamesFilePath) {
            Write-Host "You cannot use -FilePath or -NamesFilePath when using -PrivateName." -ForegroundColor Red
            return
        }
    }
    elseif ($FilePath) {
        if ($PrivateName -or $LastName -or $NamesFilePath) {
            Write-Host "You cannot use -PrivateName, -LastName, or -NamesFilePath when using -FilePath." -ForegroundColor Red
            return
        }
        if (-not $DomainName) {
            Write-Host "When using -FilePath, you must also provide -DomainName." -ForegroundColor Red
            return
        }
    }
    elseif ($NamesFilePath) {
        if ($PrivateName -or $LastName -or $FilePath) {
            Write-Host "You cannot use -PrivateName, -LastName, or -FilePath when using -NamesFilePath." -ForegroundColor Red
            return
        }
        if (-not $DomainName) {
            Write-Host "When using -NamesFilePath, you must also provide -DomainName." -ForegroundColor Red
            return
        }
    }
    else {
        Write-Host "Please provide either -PrivateName with -LastName, -FilePath, or -NamesFilePath." -ForegroundColor Yellow
        return
    }

    
    $UserNames = @()
    $validUsers = @()
    $firstValidUser = $null
    $firstValidResponse = $null

    if ($PrivateName -and $LastName) {
        $UserNames = Get-UsernameCombinations -FirstName $PrivateName -LastName $LastName
    }
    elseif ($FilePath) {
        $UserNames = Get-Content -Path $FilePath
    }
    elseif ($NamesFilePath) {
        $names = Get-Content -Path $NamesFilePath
        foreach ($name in $names) {
            $split = $name -split "\s+"
            if ($split.Length -ge 2) {
                $FirstName = $split[0]
                $LastName = $split[1]
                $UserNameCombos = Get-UsernameCombinations -FirstName $FirstName -LastName $LastName
                
                $foundValidUser = $false
                foreach ($UserName in $UserNameCombos) {
                    # Create the request body for each user
                    $body = @{
                        Username = "$UserName@$DomainName"
                    } | ConvertTo-Json

                    
                    $response = Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json"

                    # Check if the user exists based on IfExistsResult
                    if ($response.IfExistsResult -eq 0) {
                        Write-Host "The user $UserName@$DomainName exists in Azure AD." -ForegroundColor Green
                        $validUsers += "$UserName@$DomainName"

                        # Set the first valid user and response for later checks
                        if (-not $firstValidUser) {
                            $firstValidUser = "$UserName@$DomainName"
                            $firstValidResponse = $response
                        }

                        
                        $foundValidUser = $true

                        
                        if ($StopOnFirstMatch) {
                            break
                        }
                    } else {
                        Write-Host "The user $UserName@$DomainName does not exist in Azure AD." -ForegroundColor Red
                    }

                    
                    Start-Sleep -Seconds 7

                    
                    if ($firstValidUser) {
                        $checkBody = @{
                            Username = $firstValidUser
                        } | ConvertTo-Json

                        $checkResponse = Invoke-RestMethod -Uri $url -Method Post -Body $checkBody -ContentType "application/json"

                        if ($checkResponse.IfExistsResult -ne $firstValidResponse.IfExistsResult) {
                            Write-Host "Potential IP block detected. Please change your IP address." -ForegroundColor Yellow
                            return
                        }
                    }
                }
                if ($foundValidUser -and $StopOnFirstMatch) {
                    continue
                }
            }
        }
    }

    
    $validUsers = $validUsers | Sort-Object

    
    if (-not $validUsers) {
        Write-Host "No valid users were found. Please check your inputs." -ForegroundColor Yellow
        return
    }

    # Check if OutputFilePath is provided before generating HTML
    if ($OutputFilePath) {
        # Create HTML output with dark theme
        $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>EntraMail - Valid Users in Azure AD</title>
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
        <h2>Valid Users in Azure AD</h2>
        <div class="copyright">© By Shaked Wiessman</div>
        <button onclick="downloadTXT()">Download as TXT</button>
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

        # Save the HTML content to a file
        $html | Out-File -FilePath $OutputFilePath -Encoding UTF8

        Write-Host "The list of valid users has been saved to $OutputFilePath." -ForegroundColor Cyan
    }
}


Export-ModuleMember -Function Invoke-EntraMail
