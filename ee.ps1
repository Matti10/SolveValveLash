$shims = import-csv -path .\sizes.csv

$head = import-csv -path .\head.csv


$exUpper = 0.35
$exLower = 0.25
$intUpper = 0.25
$intLower = 0.15


$gaps = [System.Collections.ArrayList]@() #gap from cam to "bucket"

[double]$global:nodeCount = 0.0


#figure out gap for each location
foreach ($location in $head)
{

    $shimHeight = ($shims | Where-Object {$_.shimID -eq $location.shimID}).height

    $gap = [double]$location.distance + [double]$shimHeight

    $gaps += [PSCustomObject] @{
        location = $location.location
        gap = $gap
    }
}

$gaps = $gaps | Sort-Object -Descending
$shims = $shims  | Sort-Object -Descending




function check-shit {
    param(
        [System.Collections.ArrayList]$shimList,
        [System.Collections.ArrayList]$solvedLocations,
        $prefix = ""
    )

    [double]$global:nodeCount = [double]$global:nodeCount + [double]1
    # Write-Host $global:nodeCount

    # Write-Progress -PercentComplete ($global:nodeCount/13000000000000000000000000000000000) -Activity "Node's explored"
    # Write-Progress -PercentComplete ($shimList.Count/24*100) -Activity "$($global:nodeCount)/13000000000000000000000000000000000"
    
    if($shimList.count -eq $shims.count)
    {
        write-host "SOLVED!! :"
        write-host $shimList
        $shimList | ft
        $shimList | export-csv -Path ".\sols\solution-$(Get-Date -format "ddmmss").csv" -force

        if ((($shimList | Group-Object location && $shimList | Group-Object shim) | Group-Object count).name -ne "1")
        {
            throw "BAD SOLUTION"
        }
        # Start-Sleep -Milliseconds 500
    }
    else
    {
        $remainingLocations = $gaps | Where {$_.location -notin $solvedLocations.location}
        $remainingShims = $shims | Where {$_.shimID -notin $shimList.shim}
    
        foreach ($location in $remainingLocations)
        {
            #write-host -f blue "$prefix|-- Working on location $($location.location)"
            foreach ($shim in $remainingShims)
            {    
                #write-host -f yellow "$prefix  |-- Working on shim $($shim.shimId)"
                
                [double]$lash = [double]$location.gap - [double]$shim.height
    
                $flag = $false
    
                if ([int]$location.location -gt 12)
                {
                    #exhaust
                    if ($lash -le $exUpper -and $lash -ge $exLower)
                    {
                        $flag = $true
                    }
                }
                else
                {
                    #intake
                    if ($lash -le $intUpper -and $lash -ge $intLower)
                    {
                        $flag = $true   
                    }
                }
    
                if ($flag)
                {
                    #write-host -f Green "$prefix    |-- Shim fits exploring deeper"
                    
                    $shimList += [PSCustomObject] @{
                        location = $location.location
                        shim = $shim.shimId
                        lash = $lash
                    }
    
                    $solvedLocations += $location
    
                    $prefix += "    "
    
                    $e = check-shit -shimList $shimList -solvedLocations $solvedLocations -prefix $prefix
    
                    if ($e -eq $true)
                    {
                        $shimList.RemoveAt($shimList.Count -1)
                        $solvedLocations.RemoveAt($solvedLocations.Count -1)
                        $prefix.Remove(0,3)
                    } 
                    else
                    {
                        # write-host $shimList
                    }
                }
                else
                {
                    #write-host -f red "$prefix    |-- Shim doesn't fit, testing next shim"
                }
            }
            #write-host -f Red "$prefix  |-- No remaining shims fit, returning "
            return $true
        }
    
        return $false
    }

}

$emptyShimList = [System.Collections.ArrayList]@()
$emptyUsedGaps = [System.Collections.ArrayList]@()


$outout = check-shit -shimList $emptyShimList -solvedLocations $emptyUsedGaps