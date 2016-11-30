0 REM 99 Bottles of beer for TBASIC V0.4+
0 REM this code 'almost' works with C64, with slight modifications

10 FOR beers = 99 TO 0
20 IF beers == 0 THEN GOSUB 400
21 IF beers == 1 THEN GOSUB 300
22 IF beers == 2 THEN GOSUB 200
23 IF beers > 2 THEN GOSUB 100
60 PRINT ""
70 NEXT beers
80 END

100 REM Plural beers
101 PRINT beers ; " bottles of beer on the wall, " ; beers ; " bottles of beer."
102 PRINT "Take one down and pass it around, " ; beers - 1 ; " bottles of beer on the wall."
103 RETURN

200 REM Plu-Singular beers
201 PRINT beers ; " bottles of beer on the wall, " ; beers ; " bottles of beer."
202 PRINT "Take one down and pass it around, " ; beers - 1 ; " bottle of beer on the wall."
203 RETURN

300 REM Singu-nil beers
301 PRINT beers ; " bottle of beer on the wall, " ; beers ; " bottle of beer."
302 PRINT "Take one down and pass it around, no more bottles of beer on the wall."
303 RETURN

400 REM nil beers
401 PRINT "No more bottles of beer on the wall, no more bottles of beer."
402 PRINT "Go to the store and buy some more, 99 bottles of beer on the wall."
403 RETURN