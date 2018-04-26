$SubscriptionID = “MSDN Platforms”
$WorkFolder = "C:\Labfiles\"
$DD = Get-Date -Format "yyyy-MM-dd"
$YY = Get-Date -Format "yyyy"
$AzureUsage = Get-UsageAggregates -ReportedStartTime $YY"-01-01" -ReportedEndTime $DD -AggregationGranularity "Hourly" -ShowDetails $True
$AzureUsage.UsageAggregations.Properties | `
            Select-Object `
            @{n='SubscriptionID';e={$SubscriptionID}}, `
            UsageStartTime, `
            UsageEndTime, `
            MeterName, `
            MeterCategory, `
            MeterRegion, `
            Unit, `
            Quantity, `
            InstanceData `
            | Export-CSV -LiteralPath $WorkFolder"AzureUsageData.csv"
