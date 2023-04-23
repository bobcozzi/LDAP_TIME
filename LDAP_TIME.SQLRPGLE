         ctl-opt  MAIN(LDAP_TIME)
                  actgrp(*CALLER) option(*nodebugIO : *srcstmt) ;

           //-----------------------------------------------------------
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
           //-----------------------------------------------------------


          // ----- BEGIN PROTOTYPE
           // This is the PROTOTYPE to call LDAP_TIME
           // Copy/paste it into your RPG program
           // and then call this program using syntax like this:
           //    LDAP_TIME( rtnTime : '<timestamp-char-string>' : 'LOCAL');

         dcl-pr LDAP_TIME extpgm('LDAP_TIME');
            ldapInt int(20);
            ts  char(26) Const;
            tz  char(10) Const OPTIONS(*NOPASS);
         end-pr;
          // ----- END of PROTOTYPE


         dcl-proc LDAP_TIME;
           dcl-pi LDAP_TIME;
              ldapInt int(20);
              inDTS   char(26) Const;
              tz      char(10) Const OPTIONS(*NOPASS);
           end-pi;


           dcl-s LDAP_NANO_SECS uns(10) inz(10000000);

           dcl-s LDAP_EPOC_SECS uns(20);
           dcl-s USER_TS_SECS   uns(20);

           dcl-s TS_FMT        char(22) inz('YYYY-MM-DD-HH24.MI.SS');
           dcl-s CEE_DTS_FMT   char(20) inz('YYYY-MM-DD-HH.MI.SS');
           dcl-s LDAP_EPOC_DTS char(20) inz('1601-01-01-00.00.00');

           dcl-S TIMEZONE   varchar(10);
           dcl-s ts_string  char(26);
           dcl-s dts timestamp(0);


           dcl-ds feedback_t Qualified Template;
             msgsev uns(5); // unsigned short int
             msgno  uns(5); // unsigned short int
             bit_flags char(1);  // 0-1 CASE; 2-4 Severity; 5-7 Control
             facility_ID char(3);
             I_S_Info  uns(10);  // unsigned int
           end-ds;
           dcl-s secs float(8);
           dcl-ds utc_offset_t Qualified Template Inz;
             hours   int(10);
             minutes int(10);
             seconds float(8);
           end-ds;
           dcl-ds utc_o LikeDS(UTC_OFFSET_T) Inz(*LIKEDS);
           dcl-ds fc likeDS(feedback_t) inz;

             // CEE API Prototypes to do date to seconds conversion
             // Note that these are inline functions and very fast
           dcl-pr CEESECS OPDESC EXTPROC('CEESECS');
             in_TM_string  char(256) OPTIONS(*VARSIZE);
             in_TM_pattern char(256) OPTIONS(*VARSIZE);
             tm_struct     float(8);
             fc            likeDS(feedback_t) OPTIONS(*OMIT);
           end-pr;

           dcl-pr CEEUTCO OPDESC EXTPROC('CEEUTCO');
             hrs  int(10);
             mins int(10);
             secs float(8);
             fc   likeDS(feedback_t) OPTIONS(*OMIT);
           end-pr;


           exec sql set option commit=*NONE, naming=*SYS;

             // Convert the input timestamp string to a true timestamp value
           dts = %TimeStamp(inDTS : *ISO : 0);

             // Convert the DTS timestamp to a string of a known format
           exec SQL values varchar_format( :dts , :ts_FMT) into :ts_string;

              // Get LDAP EPOC time in Seconds (fixed value)
           CEESECS( LDAP_EPOC_DTS : CEE_DTS_FMT : SECS : FC);
           LDAP_EPOC_SECS = SECS;

              // Get the user-specified date in Seconds
           CEESECS( TS_STRING : CEE_DTS_FMT : SECS : FC);
           USER_TS_SECS = SECS;

           if ( %PARMS() >= %ParmNum(tz));
             exec sql values upper(:tz) into :TIMEZONE;
             // If the DATE is in the LOCAL time, convert
             // the time to UTC by adding in the difference.
             // Note that the offset is negative so we
             // subtract it, negating the negative and thus
             // adding it to the user-timestamp seconds.
             if (%SUBST(TIMEZONE:1:1) = 'L');
               CEEUTCO(utc_o.hours : utc_o.minutes : utc_o.seconds : fc);
               USER_TS_SECS -= utc_o.seconds;
             endif;
           endif;
                // Subtract out the number of seconds
                // between IBM DATE EPOC => 14 October 1582
                // and the LDAP EPOC     => 01 January 1601
           USER_TS_SECS -= LDAP_EPOC_SECS;
                // Convert the Secons to Nano-Seconds
           ldapInt =  %uns(USER_TS_SECS * LDAP_NANO_SECS);

         end-proc;
