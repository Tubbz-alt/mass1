#!MC 800

$!LOOP |NUMZONES|

$!VARSET |Z| = |LOOP|

$!LOOP |NUMLINEMAPS|

$!LINEMAP [|LOOP|]  ASSIGN{ZONE = |Z|}
$!REDRAWALL

$!ENDLOOP

$!EXPORTSETUP
   EXPORTFNAME = "looper-|Z%03d|.png"
   EXPORTFORMAT = PNG
   CONVERTTO256COLORS = TRUE
   IMAGEWIDTH = 1024
   EXPORTREGION = ALLFRAMES
$!EXPORT

$!ENDLOOP
