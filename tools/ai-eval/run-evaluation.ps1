param(
    [Parameter(Mandatory = $false)]
    [string]$Dataset = ""
)

$Dataset = if ([string]::IsNullOrWhiteSpace($Dataset)) {
    Join-Path $PSScriptRoot "evaluation.csv"
} else {
    $Dataset
}
$rows = @(Import-Csv -LiteralPath $Dataset)
if ($rows.Count -eq 0) { throw "The evaluation dataset is empty." }

$recognized = @($rows | Where-Object { $_.expected_food.Trim().ToLowerInvariant() -eq $_.predicted_food.Trim().ToLowerInvariant() })
$foodRows = @($rows | Where-Object { $_.expected_food.Trim().ToLowerInvariant() -ne "unknown food" })
$unknownRows = @($rows | Where-Object { $_.expected_food.Trim().ToLowerInvariant() -eq "unknown food" })
$correctAbstentions = @($unknownRows | Where-Object { $_.predicted_food.Trim().ToLowerInvariant() -eq "unknown food" })

$calorieErrors = @(foreach ($row in $foodRows) {
    [math]::Abs([double]$row.expected_calories - [double]$row.predicted_calories)
})
$proteinErrors = @(foreach ($row in $foodRows) {
    [math]::Abs([double]$row.expected_protein - [double]$row.predicted_protein)
})
$highConfidenceErrors = @($rows | Where-Object {
    [double]$_.confidence -ge 0.8 -and
    $_.expected_food.Trim().ToLowerInvariant() -ne $_.predicted_food.Trim().ToLowerInvariant()
})

$accuracy = 100 * $recognized.Count / $rows.Count
$abstention = if ($unknownRows.Count -eq 0) { 100 } else { 100 * $correctAbstentions.Count / $unknownRows.Count }
$calorieMae = if ($calorieErrors.Count -eq 0) { 0 } else { ($calorieErrors | Measure-Object -Average).Average }
$proteinMae = if ($proteinErrors.Count -eq 0) { 0 } else { ($proteinErrors | Measure-Object -Average).Average }

[pscustomobject]@{
    Samples = $rows.Count
    FoodAccuracyPercent = [math]::Round($accuracy, 2)
    CalorieMAE = [math]::Round($calorieMae, 2)
    ProteinMAE = [math]::Round($proteinMae, 2)
    UnknownAbstentionPercent = [math]::Round($abstention, 2)
    HighConfidenceErrors = $highConfidenceErrors.Count
} | Format-List

if ($highConfidenceErrors.Count -gt 0) {
    Write-Warning "High-confidence recognition errors must be reviewed before releasing this model or prompt."
    $highConfidenceErrors | Select-Object case_id, expected_food, predicted_food, confidence | Format-Table
}
