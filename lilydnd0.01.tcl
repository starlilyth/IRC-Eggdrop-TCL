# IRC DnD for Eggdrops by Lily (lily@disorg.net)
# This is a DND script for Eggdrop bots.

# SPEC
# User generation (msg)
# Character list - stats, items, (msg)
# dice roll commands (!perception) that would roll dice and use users modifiers. (pub)
# The channel would be +moderated and only players who have a character set up can !join or !leave the game, being set +v and -v when they do.

### Settings ###
# Set this to f allow friends in the bot to use dndrpg (+f flag)
# Set this to - if you want everyone to be able to.
set dndrpg(flags) "-|-"


###############################################
set dndrpg(version) "0.01"
setudef flag ldnd
package require sqlite3
set dnddbfile "./ldndrpg.db"
if {![file exists $dnddbfile]} {
  sqlite3 ddb $dnddbfile
    ddb eval {CREATE TABLE Characters(
      charname TEXT NOT NULL COLLATE NOCASE, race TEXT NOT NULL, align TEXT NOT NULL,
      updated INTEGER NOT NULL, player TEXT NOT NULL,
      level INTEGER NOT NULL, exp INTEGER NOT NULL, hp INTEGER NOT NULL, ac INTEGER NOT NULL,
      str INTEGER NOT NULL, con INTEGER NOT NULL, dex INTEGER NOT NULL, int INTEGER NOT NULL, wis INTEGER NOT NULL, cha INTEGER NOT NULL,
      items TEXT NOT NULL,
      )}
  ddb close
}


bind pub $dndrpg(flags) !setup checkdndrpg
proc checkdndrpg {nick uhost hand chan text} {
  if {channel get $chan ldnd} {
    global dndrpg dnddbfile
    sqlite3 ddb $dnddbfile


    ddb close
  }
}

bind pub $dndrpg(flags) !list dndrpgstats
proc dndrpgstats {nick uhost hand chan text} {
  if {channel get $chan ldnd} {
    global dndrpg dnddbfile
    sqlite3 ddb $dnddbfile
    if {[string match "" $text]} {
      foreach {charname race level} [ddb eval{SELECT charname, race, level FROM ldndrpg WHERE player=$uhost}] {
        puthelp "PRIVMSG $nick :Name: \002$charname\002  Race: $race  Level: $level"
      }
    } else {
      set word [string trim $text]
      set charcheck [ddb eval{SELECT player FROM ldndrpg WHERE charname=$word}]



      puthelp "PRIVMSG $nick :"
    }
    ddb close
  }
}



putlog "Lily DnD $dndrpg(version) loaded."

