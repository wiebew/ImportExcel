function ConvertFrom-ExcelToSQLInsert {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $TableName,
        [Alias("FullName")]
        [Parameter(ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true, Mandatory = $true)]
        [ValidateScript( { Test-Path $_ -PathType Leaf })]
        $Path,
        [Alias("Sheet")]
        $WorksheetName = 1,
        [Alias('HeaderRow', 'TopRow')]
        [ValidateRange(1, 9999)]
        [Int]$StartRow,
        [string[]]$Header,
        [switch]$NoHeader,
        [switch]$DataOnly,
        [switch]$ConvertEmptyStringsToNull,
        [switch]$UseMsSqlSyntax
    )

    $null = $PSBoundParameters.Remove('TableName')
    $null = $PSBoundParameters.Remove('ConvertEmptyStringsToNull')
    $null = $PSBoundParameters.Remove('UseMsSqlSyntax')

    $params = @{} + $PSBoundParameters

    ConvertFrom-ExcelData @params {
        param($propertyNames, $record)

        $ColumnNames = "'" + ($PropertyNames -join "', '") + "'"
        if($UseMsSqlSyntax) {
            $ColumnNames = "[" + ($PropertyNames -join "], [") + "]"
        }

        $values = foreach ($propertyName in $PropertyNames) {
            if ($ConvertEmptyStringsToNull.IsPresent -and [string]::IsNullOrEmpty($record.$propertyName)) {
                'NULL'
            }
            else {
                $value = $record.$propertyName
                if ($value.GetType().Name -eq "String") {
                    # escape ' characters in SQL content
                    $value = $value.replace("'","''")
                }
                "'" +  $value + "'"
            }
        }
        $targetValues = ($values -join ", ")

        "INSERT INTO {0} ({1}) Values({2});" -f $TableName, $ColumnNames, $targetValues
    }
}
