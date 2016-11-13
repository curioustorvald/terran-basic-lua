0 REM Star-twinkling superpasta
0 REM You are NOT supposed to code like this!
0 REM Test features: GOTO, GOSUB, boolean literals and their evaluation

10 PRINT "GOSUB test"
11 PRINT ""
12 TWINKLED = FALSE
20 GOTO 100
100 PRINT "Twinkle twinkle little star"
101 IF TWINKLED THEN GOTO 4666
110 IF NOT TWINKLED THEN GOSUB 4666
120 IF TWINKLED THEN GOTO 100
2048 PRINT "Up above the world so high"
2049 RETURN
4666 PRINT "How I wonder what you are"
4667 IF NOT TWINKLED THEN GOSUB 2048
4668 IF TWINKLED THEN END
5000 PRINT "Like a diamond in the sky"
5001 TWINKLED = TRUE
5002 RETURN
