#requires -version 2


<#
.SYNOPSIS
    New-RandomData generates either pseudorandom or cryptographically secure random data
    text files. It can also be used to generate random passwords easily by streaming the
    output to STDOUT with the -StreamToSTDOUT parameter (and assigning to a variable).
    
    Pseudorandom random data generation is faster than cryptographically strong random data
    generation. About ten times faster on testing with a file of size 1 MiB.
    
    It also supports creating "blank" files nearly instantly by using the fsutil.exe utility,
    but these files have no random data, just zero bytes (`0 or \0). Use the parameter
    -NoRandomData for that. This is not useful in combination with -StreamToSTDOUT. Simply use
    "`0" * $Length # if you want that.
    
.DESCRIPTION
    The default character set can be overridden with -RandomChar, or you can exclude characters
    from it with -RandomCharExclude. The default character set is 64 characters long and
    evenly divisible by 256, so it generates a "perfect" array of 256 elements, and giving
    0 % overhead when generating cryptographically secure data.

    The -Size parameter controls the total number of random generated characters, and it is
    recommended that you make -LineLength a number that the specified size is evenly
    divisible by. Otherwise there might be rounding errors leading to the size being off by
    1-2 bytes on the remainder line / file size.

    The maximum number of random characters for generating cryptographically strong data is
    256 due to the System.Security.Cryptography.RNGCryptoServiceProvider random number
    generator generating a random byte. I suppose I could have supported addition of 
    these numbers to generate larger numbers. For pseudorandom data, you can have as many
    characters in the array as you want.

    Online "blog" documentation here:
    http://www.powershelladmin.com/wiki/Create_cryptographically_secure_and_pseudorandom_data_with_PowerShell

    MIT license.
    
    Copyright (C) 2016, Joakim Svendsen.
    All rights reserved.
    Svendsen Tech
    
    The following web resources were useful:
    https://en.wikipedia.org/wiki/Pseudorandomness
    http://stackoverflow.com/questions/28181000/improve-powershell-performance-to-generate-a-random-file
    http://stackoverflow.com/questions/533636/generating-random-files-in-windows
    https://msdn.microsoft.com/en-us/library/system.security.cryptography.rngcryptoserviceprovider%28v=vs.110%29.aspx
    
.PARAMETER Path
    Directory to store random file in. Default is current working directory ($Pwd.Path).
    USe "(Get-Location)" for current directory, not ".", because that defaults to the profile
    directory inside the cmdlet.
.PARAMETER BaseName
    If generating one file, it is the file name plus a 1 plus the extension. If generating
    more than one file, it is the base name for the file plus a possibly zero-padded count number.
    If you specify -RandomFileNameGUID, a GUID will be appended to this base name instead of
    the count number, making the file name also pseudorandom. The default is "random_file-".
.PARAMETER Extension
    The extension used for the generated files.
.PARAMETER Count
    Number of files to generate. Default 1.
.PARAMETER Size
    File size in bytes. Default 1024 B. If you specify a line length which the size is
    not evenly divisible by, the size can be off by +/- 1-2 bytes.
.PARAMETER LineLength
    Number of bytes per line, including \r\n if writing a file. If you specify a line length
    which the specified size is not evenly divisible by, the size can be off by +/- 1-2 bytes.
    The default is 128.
.PARAMETER NoClobber
    Do not overwrite existing files with the same name.
.PARAMETER RandomChar
    Random char array of chars to use for generating the pseudorandom or cryptographically secure
    random data. Default: [A-Za-z0-9_-]. 64 characters. Fits perfectly in a byte-sized array when
    repeated four times, making it as efficient as possible when generating cryptographically secure
    data, while preserving equal weighting of characters.
.PARAMETER RandomCharExclude
    Characters to exclude from the default set of characters (or the supplied set).
.PARAMETER NoRandomData
    Use fsutil and generate a file filled with zero bytes (`0 or \0) extremely fast.
    NB! No random data with this option.
.PARAMETER RandomFileNameGUID
    Append a GUID to the file base name, making the file name (also) pseudorandom.
.PARAMETER Cryptography
    Use a cryptographically secure random number generator to pick random data from the
    char array rather than a pseudorandom number generator.
.PARAMETER StreamToSTDOUT
    Do not write any files, but stream random data to STDOUT.
#>
function New-RandomData {
    [CmdletBinding()]
    param(
        [ValidateScript({Test-Path $_})][string] $Path = $PWD.Path,
        [string] $BaseName = 'random_file-',
        [string] $Extension = '.txt',
        [int64] $Count = 1,
        [int64] $Size = 1024,
        [int64] $LineLength = 128,
        [switch] $NoClobber,
        [char[]] $RandomChar = [char[]] ([char]'a'..[char]'z' + [char]'A'..[char]'Z' + [char]'0'..[char]'9' + @([char]'-', [char]'_')), # 64 chars
        [char[]] $RandomCharExclude = @(),
        [switch] $NoRandomData,
        [switch] $RandomFileNameGUID,
        [switch] $Cryptography,
        [switch] $StreamToSTDOUT)
    begin {
        function Write-FileOrSTDOUT {
            param([string] $Text)
            if ($StreamToSTDOUT) {
                $Text
            }
            else {
                # Remove the last two random characters to make room for \r\n.
                #$Text = $Text -replace '.{2}\z'
                #$Text = $Text.Remove(($Text.Length - 2))
                $StreamWriter.WriteLine($Text)
            }
        }
        if ($LineLength -gt $Size) {
            Write-Error -Message "Line length cannot be greater than size." -ErrorAction Stop
            return
        }
        if ($Cryptography -and $RandomChar.Count -gt 256) {
            Write-Error -Message "When using -Cryptography, the maximum -RandomChar array size is 256." -ErrorAction Stop
            return
        }
        [int] $PadNumber = ([string] $Count).Length
        if ($NoRandomData) {
            if (-not (Get-Command -Name fsutil -ErrorAction SilentlyContinue)) {
                Write-Error -Message "Couldn't find fsutil. Cannot continue with the -NoRandomData parameter." -ErrorAction Stop
                return
            }
        }
        # Handle exceptions.
        $RandomChar = $RandomChar | Where { $RandomCharExclude -notcontains $_ }
        Write-Verbose -Message "Random char array: $($RandomChar -join ', ')"
        Write-Verbose -Message "Random char array size: $($RandomChar.Count)"
        if ($Cryptography) {
            $ErrorActionPreference = 'Stop'
            try {
                $RNG = [System.Security.Cryptography.RandomNumberGenerator]::Create()
            }
            catch {
                Write-Error "Couldn't create System.Security.Cryptography.RandomNumberGenerator object: $_" -ErrorAction Stop
                return
            }
            $ErrorActionPreference = 'Continue'
            [int64] $CryptoNumberCount = 0
            # Repeat (parts of) the char array to make it as close to 256 items long as possible.
            # Used later to avoid generating numbers needlessly that are
            # larger than the count/length of the array. Only "full copies" are made,
            # so weighting is equal.
            [char[]] $RandomCharFull = @()
            $RepeatCount = [math]::Floor(256 / $RandomChar.Count)
            if ($RepeatCount -gt 0) {
                Write-Verbose -Message "Duplicating array of length $($RandomChar.Count) completely $RepeatCount times, to fit a byte-sized array as closely as possible."
                foreach ($i in 1..$RepeatCount) {
                    $RandomCharFull += @($RandomChar)
                }
                Write-Verbose -Message "Random char array size after duplication: $($RandomCharFull.Count)."
                if ($Cryptography) {
                    Write-Verbose -Message "Probability of generating an unusable cryptography number (overhead): $(((256 - $RandomCharFull.Count) / 256 * 100).ToString('N')) %."
                }
            }
            $RandomChar = $RandomCharFull
        }
        else {
            $RNGPseudo = New-Object -TypeName System.Random
        }
        [int] $RandomCharCount = $RandomChar.Count
        $StringBuilder = New-Object -TypeName System.Text.StringBuilder #-ArgumentList 0, $LineLength
        [int] $NumberOfLinesNeeded = [math]::Floor($Size / $LineLength)
        [float] $Remainder = $Size / $LineLength - $NumberOfLinesNeeded
        # If not evenly divisible, use one less byte here, but \r\n might be added and
        # increase size by 1-2 bytes later if you're writing files.
        [int] $RemainderBytes = [math]::Floor($Remainder * $LineLength)
        if ($RemainderBytes -gt 0) {
            Write-Verbose -Message "Remainder bytes (uneven division, beware) rounded to: $RemainderBytes (from $(($Remainder * $LineLength)))."
        }
    }
    process {
        foreach ($Cnt in 1..$Count) {
            if (-not $RandomFileNameGUID) {
                $FileName = $BaseName + ("{0:D$PadNumber}" -f $Cnt) + $Extension
            }
            else {
                $FileName = $BaseName + [guid]::NewGuid().Guid + $Extension
            }
            $FileName = Join-path -Path $Path -ChildPath $FileName
            if ($NoClobber) {
                if (Test-Path -LiteralPath $FileName -PathType Leaf) {
                    Write-Warning -Message "File '$FileName' already exists. Skipping."
                    continue
                }
            }
            if ($NoRandomData) {
                Remove-Item -LiteralPath $FileName -ErrorAction SilentlyContinue
                fsutil.exe file createnew $FileName $Size
                if ($?) {
                    Write-Verbose -Message "Wrote '$FileName' $([datetime]::Now)"
                }
                else {
                    Write-Warning -Message "Couldn't write '$FileName': $($Error[0].ToString())"
                }
                continue
            }
            if (-not $StreamToSTDOUT) {
                # Nuke it if it's there and -NoClobber isn't specified.
                Remove-Item -LiteralPath $FileName -ErrorAction SilentlyContinue
                $FileStream, $StreamWriter = $null, $null
                $ErrorActionPreference = 'Stop'
                try {
                    $FileStream = New-Object -TypeName System.IO.FileStream -ArgumentList $FileName, ([System.IO.FileMode]::CreateNew)
                    $StreamWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList $FileStream, ([System.Text.Encoding]::ASCII), $LineLength
                }
                catch {
                    Write-Warning -Message "Error creating FileStream or StreamWriter object for file name '$FileName': $_"
                    continue
                }
            }
            $ErrorActionPreference = 'Continue'
            # Cache this for a performance gain.
            if ($NumberOfLinesNeeded -gt 0) {
                # Small optimization attempt. Generating 2 random characters less per line if
                # writing a file, where \r\n will occupy two characters per line.
                if (-not $StreamToSTDOUT -and $LineLength -gt 2) {
                    $TempLineLength = $LineLength - 2
                }
                else {
                    $TempLineLength = $LineLength
                }
                foreach ($LineNum in 1..$NumberOfLinesNeeded) {
                    #[string] $Line = ''
                    [void] $StringBuilder.Clear()
                    # This cryptography approach might be pretty slow...
                    if ($Cryptography) {
                        foreach ($i in 1..$TempLineLength) {
                            # Fill $Byte with a random number (from 0-255), until we get
                            # a number small enough to index into the char array. See comments
                            # on what is now around line 100-110 in the begin block for the reason why I'm using
                            # this potentially wasteful/inefficient approach (to preserve equal weighting).
                            # Largely remedied for smaller arrays. Worst array size = 129...
                            do {
                                [byte[]] $Byte = 0
                                $RNG.GetBytes($Byte)
                                $CryptoNumberCount++
                            } while ($Byte -ge $RandomCharCount)
                            [void] $StringBuilder.Append(-join $RandomChar[$Byte])
                        }
                    }
                    else {
                        foreach ($i in 1..$TempLineLength) {
                            #-join (Get-Random -Count $LineLength -InputObject $RandomChar) # only one occurrence of each char in inputobject...
                            [void] $StringBuilder.Append(-join $RandomChar[$RNGPseudo.Next($RandomCharCount)])
                        }
                    }
                    Write-FileOrSTDOUT -Text $StringBuilder.ToString() #-StreamToSTDOUT $StreamToSTDOUT
                }
            }
            if ($RemainderBytes) {
                #Write-Verbose -Message "Remainder bytes: $RemainderBytes"
                #$Line = ''
                [void] $StringBuilder.Clear()
                if ($Cryptography) {
                    foreach ($i in 1..$RemainderBytes) {
                        do {
                            [byte[]] $Byte = 0
                            $RNG.GetBytes($Byte)
                            $CryptoNumberCount++
                        } while ($Byte -ge $RandomCharCount)
                        [void] $StringBuilder.Append(-join $RandomChar[$Byte])
                    }
                }
                else {
                    foreach ($i in 1..$RemainderBytes) {
                        #-join (Get-Random -Count $LineLength -InputObject $RandomChar) # only one of each char...
                        [void] $StringBuilder.Append(-join $RandomChar[$RNGPseudo.Next($RandomCharCount)])
                    }
                }
                Write-FileOrSTDOUT -Text $StringBuilder.ToString() #-RemainderBytes $RemainderBytes -StreamToSTDOUT $StreamToSTDOUT
            }
            if (-not $StreamToSTDOUT) {
                $StreamWriter.Close()
                $FileStream.Close()
                Write-Verbose -Message "Wrote '$FileName'. $([datetime]::Now)."
            }
        }
    }
    end {
        if (Get-Variable -Name RNG -ErrorAction SilentlyContinue) {
            $RNG.Dispose()
        }
        [gc]::Collect()
        if ($Cryptography) {
            Write-Verbose -Message "Had to get $CryptoNumberCount cryptography numbers."
        }
    }
}
