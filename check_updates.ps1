# Define the variables
$url = "https://files.tripi.zip/Games/WoW%20Updates/TBC%202.4.3/"
$file_name = "patch-enUS.MPQ"
$changes_file = "changes.txt"
$updateFolder = Split-Path -Parent $MyInvocation.MyCommand.Path
$outputFile = Join-Path -Path $updateFolder -ChildPath $file_name
$finalOutputFile = Join-Path -Path (Join-Path -Path $updateFolder -ChildPath "..\Data\enUS") -ChildPath $file_name
$changesOutputFile = Join-Path -Path $updateFolder -ChildPath $changes_file

# Function to check for updates
function Check-ForUpdates {
    try {
        # Fetch the HTML content from the URL
        $response = Invoke-WebRequest -Uri $url -UseBasicP -ErrorAction Stop
        $htmlContent = $response.Content
        
        # Output the HTML content for debugging
        Write-Output "HTML Content fetched from the website:"
        Write-Output $htmlContent
        
        # Find the file date using regex
        $regex = [regex]::new("<a href=""$file_name"">.*?</a>\s*(?<date>\d{1,2}-\w{3}-\d{4}\s+\d{1,2}:\d{2})", 'IgnoreCase')
        $matches = $regex.Matches($htmlContent)

        if ($matches.Count -gt 0) {
            $websiteFileDate = [datetime]::ParseExact($matches[0].Groups["date"].Value, "dd-MMM-yyyy HH:mm", $null)
            Write-Output "Website file date for `$file_name: $websiteFileDate"
        } else {
            Write-Output "No matches found in the HTML content for `$file_name."
            return $null
        }

        # Find the changes.txt date
        $changesRegex = [regex]::new("<a href=""$changes_file"">.*?</a>\s*(?<date>\d{1,2}-\w{3}-\d{4}\s+\d{1,2}:\d{2})", 'IgnoreCase')
        $changesMatches = $changesRegex.Matches($htmlContent)

        if ($changesMatches.Count -gt 0) {
            $websiteChangesDate = [datetime]::ParseExact($changesMatches[0].Groups["date"].Value, "dd-MMM-yyyy HH:mm", $null)
            Write-Output "Website changes date for `$changes_file: $websiteChangesDate"
        } else {
            Write-Output "No matches found in the HTML content for `$changes_file."
            return $null
        }

        return @{ FileDate = $websiteFileDate; ChangesDate = $websiteChangesDate }
    } catch {
        Write-Output "Error occurred: $_"
        return $null
    }
}

# Check for updates
$dates = Check-ForUpdates

if ($dates -ne $null) {
    $websiteFileDate = $dates.FileDate
    $websiteChangesDate = $dates.ChangesDate
    $patchUpdated = $false
    $changesUpdated = $false

    # Check local file date for the patch file
    if (Test-Path $finalOutputFile) {
        $localFileDate = (Get-Item $finalOutputFile).LastWriteTime
        Write-Output "Local patch file date: $localFileDate"
        Write-Output "Comparing with website patch file date: $websiteFileDate"

        # Compare dates correctly
        if ($localFileDate.ToUniversalTime() -lt $websiteFileDate.ToUniversalTime()) {
            Write-Output "Local patch file is older than the website version. Downloading new patch file..."
            Invoke-WebRequest -Uri "$url$file_name" -OutFile $outputFile
            
            # Remove old patch if exists
            if (Test-Path $finalOutputFile) {
                Remove-Item -Path $finalOutputFile -Force
            }
            
            # Copy the new file to the Data\enUS folder
            Copy-Item -Path $outputFile -Destination $finalOutputFile  # Copy to the final destination
            Write-Output "Patch file updated successfully."
            $patchUpdated = $true
        } else {
            Write-Output "Local patch file is up to date."
        }
    } else {
        Write-Output "Local patch file does not exist. Downloading new patch file..."
        Invoke-WebRequest -Uri "$url$file_name" -OutFile $outputFile

        # Copy the new file to the Data\enUS folder
        Copy-Item -Path $outputFile -Destination $finalOutputFile  # Copy to the final destination
        Write-Output "Patch file updated successfully."
        $patchUpdated = $true
    }

    # Check local file date for the changes.txt file
    if (Test-Path $changesOutputFile) {
        $localChangesDate = (Get-Item $changesOutputFile).LastWriteTime
        Write-Output "Local changes.txt date: $localChangesDate"
        Write-Output "Comparing with website changes.txt date: $websiteChangesDate"

        # Compare dates correctly
        if ($localChangesDate.ToUniversalTime() -lt $websiteChangesDate.ToUniversalTime()) {
            Write-Output "Local changes.txt is older than the website version. Downloading new changes.txt..."
            Invoke-WebRequest -Uri "$url$changes_file" -OutFile $changesOutputFile
            Write-Output "New changes.txt downloaded successfully."
            $changesUpdated = $true
        } else {
            Write-Output "Local changes.txt is up to date."
        }
    } else {
        Write-Output "Local changes.txt does not exist. Downloading new changes.txt..."
        Invoke-WebRequest -Uri "$url$changes_file" -OutFile $changesOutputFile
        Write-Output "New changes.txt downloaded successfully."
        $changesUpdated = $true
    }
} else {
    Write-Output "Error: Unable to check for updates."
}

# Prompt to open changes.txt only if it was updated
if ($changesUpdated) {
    $openChanges = Read-Host "Changes.txt has been updated. Do you want to open it? (y/n)"
    if ($openChanges -eq 'y' -or $openChanges -eq 'yes') {
        Start-Process "notepad.exe" -ArgumentList $changesOutputFile
        # Wait for Notepad to close before launching wow.exe
        Wait-Process -Name "notepad"
    }
}

# Launch the wow.exe application
$exePath = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "..\wow.exe"
Start-Process -FilePath $exePath
