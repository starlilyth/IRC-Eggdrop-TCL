	 - cMotion - 
cMotion is a tcl program for linux eggdrop bots on IRC. 
It attempts to roughly simulate a person. Its best use is as a hostess/greeter bot. 

QUICKSTART: The cmotion directory where this file is should be in eggdrop/scripts of your 
bot. The end of your conf file should have: source scripts/cmotion/cMotion.tcl
You should look at and edit the settings.tcl file in this directory, then rehash your bot. 
Do the following in dcc chat with your bot: .chanset #channelname +cmotion
where #channelname is the channel you want it to operate in, of course :p
The bot should respond to "hello <botname>" in channel. 

-----
LICENSE -
ALL OF BMOTION WAS RELEASED UNDER GPL. Ergo, all of cMotion is covered under GPL.
Please forgive my lack of adherence to any requisite notices or inclusions; you should 
know how to look it up, and the previous sentences serve as notice of licensing as stated.
<TOS> By reading this sentence you have acknowledged the aforementioned. </TOS> :D 

The important bits were originally called bMotion, written by James "Off" Seward 
(JamesOff on EFNet). James appears to have left off coding in 2007, and the stats server 
for bMotion stopped responding in 2010.  This is my redo in 2012. 
I have cleaned up a lot of unused code, whitespace, files, etc. 
The plugin system was refactored, and it should be pretty easy to extend now. 
See PLUGIN_API.txt for more information.
There is no interbot anything - each bot is an island unto themselves. 
Some system files were condensed, and the file layout was changed some: 
cmotion
   |____
       cMotion.tcl
       settings.tcl
       data
         |____
             *-abstracts.tcl
       local
         |____
            abstracts
                |____
                    <langs>
       modules
         |____
            <systemfiles>.tcl
       plugins
         |____
             mgmt
             <langs>
              
Where <langs> are en, fr, and whatever other languages you make plugins for :) 
The data directory contains multiple files with the common and large list abstracts 
(instead of one giant file). Note the naming convention when adding files. 
Abstracts can also be put in the plugins, see PLUGIN_API.txt for more information. 
The local directory is where the abstracts are stored by the bot (for now). 
The modules directory contains the system files, and shouldnt need to be modified, unless
you have a great idea on how to improve the core, then please it share with me and Ill 
include it in future releases. :) 
The plugins dir contains the match/response plugins, and I encourage you to write some 
of your own to customize your bot. See PLUGIN_API.txt for more information.

Bot administration is done with .cmotion commands in dcc chat with the bot. 
For more help, do: .cmotion help 

Lily lily@disorg.net
