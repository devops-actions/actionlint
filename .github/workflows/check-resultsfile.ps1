Param (
    [string] $resultsFilePath
)

$result = Get-Content $resultsFilePath    
$items = @(ConvertFrom-Json $result -Depth 10)     
      
$found1 = $false
$found2 = $false
$found3 = $false
foreach ($item in $items) { 
    Write-Host "Found an error: "
    Write-Host "Message:" $item.message
    Write-Host "Filepath:" $item.filepath
    Write-Host "Line:" $item.line

    if ($item.filepath -eq '.github/workflows/workflow-with-errors.yml' -and $item.line -eq 6) {
        Write-Host "Found first file path and line number"
        if ($item.message -eq "job ""job-with-errors"" needs job ""test-local-action"" which does not exist in this workflow") { 
            $found1 = $true
        }
    }

    if ($item.filepath -eq '.github/workflows/workflow-with-errors.yml' -and $item.line -eq 12) {
        Write-Host "Found second file path and line number"
        if ($item.message -eq "property ""test-local-action"" is not defined in object type {}") { 
            $found2 = $true
        }
    }

    if ($item.filepath -eq '.github/workflows/workflow-with-errors.yml' -and $item.line -eq 18) {
        Write-Host "Found third file path and line number"
        if ($item.message -eq "property ""test-job"" is not defined in object type {}"){
            $found3 = $true
        }
    }
        
    Write-Host "----------------------------------------------------------------------------------------------"   
}

if (!$found1){
    Write-Host "Error finding the first expected result. Exiting with failure"
} 
else {
    Write-Host "Found first the expected error succesfully"
}

if (!$found2){
    Write-Host "Error finding the second expected result. Exiting with failure"
} 
else {
    Write-Host "Found the second expected error succesfully"
}

if (!$found3){
    Write-Host "Error finding the third expected result. Exiting with failure"
} 
else {
    Write-Host "Found the third expected error succesfully"
}

if (!$found1 -or !$found2 -or !$found3){
    exit 1
}