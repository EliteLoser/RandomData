# RandomData
Generates cryptographically secure or pseudorandom data. Can be used to generate keys and passwords with the -StreamToSTDOUT parameter and has comprehensive features for generating files with random data, of a specified size.

Works on Linux, but on a 8192 bytes specified file size I got 8064 as actual size. Guessing "\r" missing once per line is the difference. Might fix.

Comprehensive online blog documentation here: https://www.powershelladmin.com/wiki/Create_cryptographically_secure_and_pseudorandom_data_with_PowerShell

```
PS /home/joakim> Save-Module -Name RandomData -Path /home/joakim/Documents
PS /home/joakim> ipmo ./Documents/RandomData                                      
PS /home/joakim> $Key = New-RandomData -LineLength 3096 -Size 3096 -StreamToSTDOUT
PS /home/joakim> $Key[0..10] -join ", "                                           
i, y, R, o, 7, 5, U, O, g, 2, r
PS /home/joakim> $Key2 = New-RandomData -LineLength 3096 -Size 3096 -StreamToSTDOUT -Random
RandomChar          RandomCharExclude   RandomFileNameGUID  
PS /home/joakim> $Key2 = New-RandomData -LineLength 3096 -Size 3096 -StreamToSTDOUT -RandomCharExclude "-", "_"
PS /home/joakim> $Key2.Length
3096

PS /home/joakim> -join $Key2                                                                                   
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


# Seeing some weird stuff when trying to limit to a-fA-F0-9... 
# brain not working right, probably, I'm getting rusty

PS /home/joakim> function tempqlfunc {$args}
PS /home/joakim> $KeyArrayLetters = tempqlfunc a A b B c C d D e E f F (0..9)
PS /home/joakim> $KeyArrayLetters -join ", "
a, A, b, B, c, C, d, D, e, E, f, F, System.Object[]
PS /home/joakim> $KeyArrayLetters = tempqlfunc a A b B c C d D e E f F 0 1 2 3 4 5 6 7 8 9
PS /home/joakim> $KeyArrayLetters -join ", "                                              
a, A, b, B, c, C, d, D, e, E, f, F, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
PS /home/joakim> $Key2 = New-RandomData -LineLength 3096 -Size 3096 -StreamToSTDOUT -RandomChar $KeyArrayLetters          PS /home/joakim> $Key2 = New-RandomData -LineLength 128 -Size 128 -StreamToSTDOUT -RandomChar $KeyArrayLetters  
PS /home/joakim> $Key2.Length
128
PS /home/joakim> -join $Key2
DabFF   aBA	ACacced	CcbACfBCAcacdbAeCFABbE	bebbbEcBbDeEDcaebCd	BEfFeBfCdbe
PS /home/joakim> 


```
