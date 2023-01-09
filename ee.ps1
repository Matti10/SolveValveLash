$shims = import-csv -path .\sizes.csv

$head = import-csv -path .\head.csv


$exUpper = 0.35
$exLower = 0.25
$intUpper = 0.25
$intLower = 0.15


$gaps = [System.Collections.ArrayList]@() #gap from cam to "bucket"

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




function check-shit {
    param(
        [System.Collections.ArrayList]$shimList,
        [System.Collections.ArrayList]$usedGaps,
        $prefix = "",
        $n = 0
    )

    Write-Host $shimList.Count

    if($shimList.count -eq $shims.count-3)
    {
        #write-host "SOLVED!! :"
        #write-host $shimList
        $shimList | ft
        $shimList | export-csv -Path ".\sols\solution-$(Get-Date -format "ddmmss").csv" -force

        if ((($shimList | Group-Object location && $shimList | Group-Object shim) | Group-Object count).name -ne "1")
        {
            throw "BAD SOLUTION"
        }
    }
    else
    {
            $remainingGaps = $gaps | Where {$_.location -notin $usedGaps.location}
            $remainingShims = $shims | Where {$_.shimID -notin $shimList.shim}
        
            $remainingGaps | ForEach-Object {
                $gap = $_
                #write-host -f blue "$prefix|-- Working on location $($gap.location)"
                foreach ($shim in $remainingShims)
                {    
                    #write-host -f yellow "$prefix  |-- Working on shim $($shim.shimId)"
                     $n = $n+1
                    
                    [double]$combGap = [double]$gap.gap - [double]$shim.height
        
                    $flag = $false
        
                    if ($gap.location -gt 12)
                    {
                        #exhaust
                        if ($combGap -le $exUpper -and $combGap -ge $exLower)
                        {
                            $flag = $true
                        }
                    }
                    else
                    {
                        #intake
                        if ($combGap -le $intUpper -and $combGap -ge $intLower)
                        {
                            $flag = $true   
                        }
                    }
        
                    if ($flag)
                    {
                        #write-host -f Green "$prefix    |-- Shim fits exploring deeper"
                        
                        $shimList += [PSCustomObject] @{
                            location = $gap.location
                            shim = $shim.shimId
                        }
        
                        $usedGaps += $gap
        
                        $prefix += "    "
        
                        $e = check-shit -shimList $shimList -usedGaps $usedGaps -prefix $prefix -n $n
        
                        if ($e)
                        {
                            $shimList.RemoveAt($shimList.Count -1)
                            $usedGaps.RemoveAt($usedGaps.Count -1)
                            $prefix.Remove(0,3)
                        } 
                        else
                        {
                            #write-host $shimList
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
        
            # return $shimList
    }

}

$emptyShimList = [System.Collections.ArrayList]@()
$emptyUsedGaps = [System.Collections.ArrayList]@()


$outout = check-shit -shimList $emptyShimList -usedGaps $emptyUsedGaps