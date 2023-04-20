# LDAP_TIME
Convert TIMESAMP string to Win32 LDAP FILETIME integer using RPG IV

           //  Program: LDAP_TIME
           
           //  Author:      R. Cozzi, Jr. (c) 2023 All rights reserved.
           
           //  Description: Convert a timestamp string
           //               to Win32 LDAP FILETIME integer
           //               That is, the number of nano-seconds
           //               since 01-JAN-1601.
           //  Parameters:
           //               RETURN VALUE  INT(20) (8-byte LDAP time integer)
           //               IN timestamp as a string CHAR(20)
           //                   FMT must be YYYY-MM-DD HH.MM.SS with 24-hour clock
           //               IN TimeZone of input timestamp DFT('UTC')
           //                   Choices are: 'LOCAL' or DFT('UTC')
           //                   When 'LOCAL' is specified, input timestamp
           //                   is adjuested to UTC time before returning
           //                   the LDAP integer value.
           
