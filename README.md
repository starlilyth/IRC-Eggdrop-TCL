IRC-Eggdrop-TCL
===============

TCL scripts for use with Eggdrop IRC bots.

Developed originally on Eggdrop 1.6.x, but mostly tested with 1.9.x. I like sqlite3, so data storage for these scripts uses it. 

- URL2IRC: Scans links in IRC channels and returns titles and tinyurl, and logs to a webpage. 

  It will tag webpage entries NSFW if that appears in the line with the link.
  
  The wepage has dark mode, updated styling, and duplicate link detection - it displays the newest entry only, with link count and user list.

  Requires tcllib, tcltls, and the sqlite3 tcl library. (not mysql!) For deb/ubuntu, the sqlite3 package is libsqlite3-tcl. Adjust for your flavor. 

  Version 2.x has YouTube integration: provide your Google/YouTube API key for optional YouTube searching and expanded video details. 

  *MASSIVE UPDATES from version 1.6!* Please report any links that do not get titled or logged correctly. 

- lilykarma: A Karma database script for Eggdrop bots. It has flood control built in, and basic self-karma prevention. 

- lilydecide: A very basic 'this or that' script. 

- autobar: A robot bartender for all your virtual drinking needs. 

- cmotion2022: A rework of the BMotion bot, has been converted to use sqlite3 database instead of on disk files, plus lots of other cleanups.  (cmotion may need compat module is loaded on Eggdrop 1.9.x)

- lilyweather: A weather report scraper. Uses wunderground for data (has not been updated in some time and is probably broken, sorry) 


