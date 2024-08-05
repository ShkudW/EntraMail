# EntraMail

EntraMail is a PowerShell tool designed to identify valid users in Azure Active Directory (Azure AD). The tool attempts to determine if specific usernames exist within a specified domain using various combinations of given and last names.

## Features

- **Username Generation:** Automatically generates possible username combinations from given and last names.
- **Azure AD Verification:** Checks if the generated usernames exist in Azure AD.
- **IP Blocking Detection:** Stops the script and notifies the user if a potential IP block is detected.
- **Custom Output:** Generates a styled HTML report and provides an option to download the results as a TXT file.

## Usage

### Prerequisites

- PowerShell 5.0 or higher
- Internet connection

### Command Line Usage

```powershell
# Load The Script
Import-Module .\EntraMail.psm1

# To check a single set of names
Invoke-EntraMail -PrivateName "Shaked" -LastName "Wiessman" -DomainName "example.com" -OutputFilePath "results.html"

# To check multiple names+last-names from a file
Invoke-EntraMail -NamesFilePath "names.txt" -DomainName "example.com" -OutputFilePath "results.html"

# To check a list of usernames from a file
Invoke-EntraMail -FilePath "usernames.txt" -DomainName "example.com" -OutputFilePath "results.html"
```

### Poc:
# To check a single set of names:
![image](https://github.com/user-attachments/assets/72c3196b-6161-456a-b405-2112ad346336)

-- The tool will rotate between the provided first name and last name --

# To check multiple names+last-names from a file:

![image](https://github.com/user-attachments/assets/7ff71ac6-9632-499d-9900-e25027c1bad3)

Example of name+lastname file:
![image](https://github.com/user-attachments/assets/eee92276-ea42-4747-8840-b035759f6bb8)

-- In this option, you can add the -StopOnFirstMatch flag, so that after finding a valid user from the first line of the file, the tool will move to the next line --


# To check a list of usernames from a file

![image](https://github.com/user-attachments/assets/24639f6c-84bf-418e-b52d-3ca338cb43ba)

Exampe of users list:
![image](https://github.com/user-attachments/assets/39390d8f-4187-47d0-9f47-a3b15196f6ca)


# After finding the first valid user, the tool continuously samples the server's response for that user. If the server's response changes, it indicates that your IP address has been blocked, and you need to change your IP address

![image](https://github.com/user-attachments/assets/c26482fd-924e-4839-9528-87b3c72e47aa)


-------------------
**# To check **





