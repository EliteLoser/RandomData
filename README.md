# RandomData
Generates cryptographically secure or pseudorandom data. Can be used to generate keys and password with the -StreamToSTDOUT parameter and has comprehensive features for generating files with random data, of a specified size.

Works on Linux, but on a 8192 bytes specified file size I got 8064 as actual size. Guessing "\r" missing once per line is the difference. Might fix.

