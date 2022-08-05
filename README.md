# RandomData
Svendsen Tech's New-RandomData function generates cryptographically secure or pseudorandom data. Can be used to generate keys and passwords with the -StreamToSTDOUT parameter and has comprehensive features for generating files with random data, of a specified size.

Works on Linux, but on a 8192 bytes specified file size I got 8064 as actual size. Guessing "\r" missing once per line is the difference. 
Might investigate and fix.

The module has been published to the PowerShell Gallery and can be downloaded, inspected and installed with `Save-Module`, `Find-Module` and `Install-Module`.

PowerShell Gallery link (Microsoft site): https://www.powershellgallery.com/packages/RandomData/

Comprehensive online blog documentation here: 
https://www.powershelladmin.com/wiki/Create_cryptographically_secure_and_pseudorandom_data_with_PowerShell


Some code examples.

```
PS /home/joakim/Documents> Import-Module ./RandomData/                                              
PS /home/joakim/Documents> $RandomString = New-RandomData -LineLength 20 -Size 20 -StreamToSTDOUT
PS /home/joakim/Documents> $RandomString                                                         
4zffUVJbOl6GF8sbQOpu
PS /home/joakim/Documents> $HexKey = New-RandomData -LineLength 64 -Size 64 -StreamToSTDOUT -Random
RandomChar          RandomCharExclude   RandomFileNameGUID  
PS /home/joakim/Documents> $HexKey = New-RandomData -LineLength 64 -Size 64 -StreamToSTDOUT `
    -RandomChar @(@([char]'a'..[char]'f') + @([char]'0'..[char]'9'))      
PS /home/joakim/Documents> $HexKey                                                                                             24aac8116deb2d79b8796995ce2687f84d3bd092259473d24e42e274f7562e57


# Sizes are off by a smidge on Linux, probably due to \r being missing on this platform.

PS /home/joakim/Documents> mkdir randomdatatest                         
PS /home/joakim/Documents> cd randomdatatest
PS /home/joakim/Documents/randomdatatest> gci
PS /home/joakim/Documents/randomdatatest> Measure-Command { 
    New-RandomData -Count 100 -Size 8192 -LineLength 128 -Path (Get-Location) }
    | % TotalSeconds      
2.3546092
PS /home/joakim/Documents/randomdatatest> gci | select -first 10

    Directory: /home/joakim/Documents/randomdatatest

UnixMode   User             Group                 LastWriteTime           Size Name
--------   ----             -----                 -------------           ---- ----
-rw-rw-r-- joakim           joakim               8/6/2022 00:02           8128 random_file-001.txt
-rw-rw-r-- joakim           joakim               8/6/2022 00:02           8128 random_file-002.txt
-rw-rw-r-- joakim           joakim               8/6/2022 00:02           8128 random_file-003.txt
-rw-rw-r-- joakim           joakim               8/6/2022 00:02           8128 random_file-004.txt
-rw-rw-r-- joakim           joakim               8/6/2022 00:02           8128 random_file-005.txt
-rw-rw-r-- joakim           joakim               8/6/2022 00:02           8128 random_file-006.txt
-rw-rw-r-- joakim           joakim               8/6/2022 00:02           8128 random_file-007.txt
-rw-rw-r-- joakim           joakim               8/6/2022 00:02           8128 random_file-008.txt
-rw-rw-r-- joakim           joakim               8/6/2022 00:02           8128 random_file-009.txt
-rw-rw-r-- joakim           joakim               8/6/2022 00:02           8128 random_file-010.txt

PS /home/joakim/Documents/randomdatatest> gci | select -last 10 

    Directory: /home/joakim/Documents/randomdatatest

UnixMode   User             Group                 LastWriteTime           Size Name
--------   ----             -----                 -------------           ---- ----
-rw-rw-r-- joakim           joakim               8/6/2022 00:02           8128 random_file-091.txt
-rw-rw-r-- joakim           joakim               8/6/2022 00:02           8128 random_file-092.txt
-rw-rw-r-- joakim           joakim               8/6/2022 00:02           8128 random_file-093.txt
-rw-rw-r-- joakim           joakim               8/6/2022 00:02           8128 random_file-094.txt
-rw-rw-r-- joakim           joakim               8/6/2022 00:02           8128 random_file-095.txt
-rw-rw-r-- joakim           joakim               8/6/2022 00:02           8128 random_file-096.txt
-rw-rw-r-- joakim           joakim               8/6/2022 00:02           8128 random_file-097.txt
-rw-rw-r-- joakim           joakim               8/6/2022 00:02           8128 random_file-098.txt
-rw-rw-r-- joakim           joakim               8/6/2022 00:02           8128 random_file-099.txt
-rw-rw-r-- joakim           joakim               8/6/2022 00:02           8128 random_file-100.txt

PS /home/joakim/Documents/randomdatatest> 

```

Joakim Borger Svendsen. Svendsen Tech.
