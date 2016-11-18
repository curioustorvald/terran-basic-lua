# To Make It Do More Things You Want

This is not an up-goer art! Brought to you by _O'Really? Press_.


## Usual things that people should follow

To check if it's a number, you use ```__checknumber```. To check if it's letters, you use ```__checkstring```. To check the type you'll get, you use ```__assert```.

When it comes to name your *word*s that explains orders to the computer, their name starts with ```_fn```, if it's about *mark*s, their name starts with ```_op```.


## To make it understand your new sets of words

You will be dealing with something called ```_TBASIC._FNCTION``` and ```_TBASIC.LUAFN```. Add the name of your word to ```_TBASIC._FNCTION```, and add a computer word to ```_TBASIC.LUAFN``` with your word name as a place-name. To make the computer *actually* understand your new *words*, is up to you.


## To make it understand your new sets of marks

Much the same as adding *word*s, but there's some different parts. You will add your *mark*s to ```_TBASIC._OPERATR``` and ```opprecedence```. Watch that ```opprecedence``` is ``````ordered``````, and you should know the order of your new *mark*s — which mark comes before yours and which comes after. Think hard that order and add your *mark* to its right place. If it's the "right-to-left" thing, also add yours to ```opassoc.rtl```.


## Just tell me how to do that!

Let's say you want to add a word ``````UPGOER``````. What it does is it takes a number, and say *Up-goer ```number``` goes up!* If you say ```UPGOER 5```, the computer will say ```Up-goer 5 goes up!```

Here's how it's done:

1. Add ```UPGOER``` to ```_TBASIC._FNCTION```.
2. Add this, ```UPGGOER = {_fnupgoer, 1}```, to ```_TBASIC.LUAFN```. Number ```1``` says it will take that number of things to do something.
3. Now in any lines upper than the line ```_TBASIC.LUAFN``` is, type this:

        local function _fnupgoer(n)
            print("Up-goer "..__checknumber(n).." goes up!")
        end
        
4. Done!


## Tell me more!

* ```__checknumber(number)``` gives you real number ```number``` if it can be written as a number. If not, computer will stop and say it didn't get a number.

* ```__checkstring(letters)``` gives you letters ```letters``` if it can be written as letters.

* ```__assert(thing, type)``` will check type of ```thing``` is a ```type```. If it is, computer will move on. If not, it will stop and say something.
