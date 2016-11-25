# TBASIC: BASIC language for Lua and OpenComputers/ComputerCraft/more

Make BASIC great again

## Outline

This is a BASIC language and its interpreter written in Lua, which can be used with Plain Lua/[OpenComputers](https://oc.cil.li/index.php?/page/index.html)/[ComputerCraft](http://computercraft.info/).

The program will work with any Lua implementation that supports __Lua 5.2__ and higher (and Lua 5.1 with bit32 library). Tested with official Lua, __LuaJIT__, ComputerCraft (LuaJ) and OpenComputers (JNLua).

## Files

* ```TBASIC.lua```: Terran BASIC shell
* ```TBASEXEC.lua```: Terran BASIC interpreter
* ```TBASINCL.lua```: Terran BASIC interpreter library
* ```doc/TBASMAN.pdf```: Language manual. READ IT
* ```doc/TBASMAN.tex```: Source for the manual
* ```README.md```: Just read it
* ```LICENSE.md```: Also just read it


## How to Use

Run ```TBASIC.lua``` to get started.

* Prefix line numbers to input multiple-lined commands.
* Enter command without line number to execute the command right away. Any input program will left untouched.
* Enter ```RUN``` to execute the program you have written, enter ```LIST``` to see what have you enter to the buffer.
* After the ```RUN```, your program will still be there. Enter ```NEW``` to wipe out them.
* Made some mistakes? No worries, you can just overwrite by re-writing the line you wish to correct.


## Syntax

Syntax of the TBASIC is heavily influenced by [Commodore 64 BASIC](https://www.c64-wiki.com/index.php/BASIC#Overview_of_BASIC_Version_2.0_.28second_release.29_Commands); Line number based, GOTO-controlled (uh-oh, [sounds harmful](http://homepages.cwi.nl/~storm/teaching/reader/Dijkstra68.pdf)), has GOSUB, etc. What doesn't work is direct memory controls (PEEK/POKE, SYS) and graphic/sound related commands.


## How to Contribute

### Code
You clone it, make it great, and make a pull request.

### Documentation
You can also help improving the documentation by adding missing texts, correcting my bad English (if any), or making a translation for non-English speaker like me. Don't know how to use TeX? Just leave them as plain text/MS Word/Rich Text Format and I'll take care of them. (Note: HWP is not to be accepted. C'mon, what the f--k is HWP?)

### In general
If you have suggestions/bugs, feel free to report them to Issue Tracker.


## How it works

The interpreter is basically a stack-based machine, much like [FORTH](https://en.wikipedia.org/wiki/FORTH). Input commands are converted into [Reverse Polish Notation](https://en.wikipedia.org/wiki/Reverse_Polish_notation) using ```_G._TBASIC.TORPN()```, TORPN notates type of each token (function, operator, variable, string and number), and the interpreter executes RPN'd command token by token. More details are on the comments of the code.


## Disclaimer

This project is in its early stages, meaning most of the keywords are not implemented, already implemented features _are_ buggy.

Reference manual is work-in-progress.

If you are to distribute this Software to be used on the OpenComputers/ComputerCraft, AND ONLY WHEN YOU DISTRIBUTE THE VERBATIM COPY OF THE ESSENTIAL PARTS OF THIS SOFTWARE (following three files: ```TBASINCL.lua```, ```TBASEXEC.lua``` and ```TBASIC.lua```), you can distribute without the license file. If not (made some modifications and/or to be used on other software/games, even if you are the contributor of this Software), the above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
