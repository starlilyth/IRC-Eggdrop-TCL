# IRC DnD for Eggdrops by Lily (lily@disorg.net)
# This is a DND script for Eggdrop bots.

# SPEC
# User generation (msg)
# Character list - stats, items, (msg)
# dice roll commands (!perception) that would roll dice and use users modifiers. (pub)
# The channel would be +moderated and only players who have a character set up can !join or !leave the game, being set +v and -v when they do.

### Settings ###
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


bind pub $dndrpg(flags) !setup setupchar
proc setupchar {nick uhost hand chan text} {
  if {channel get $chan ldnd} {
    global dndrpg dnddbfile
    sqlite3 ddb $dnddbfile


    ddb close
  }
}

bind pub $dndrpg(flags) !list listchar
proc listchar {nick uhost hand chan text} {
  if {channel get $chan ldnd} {
    global dndrpg dnddbfile
    sqlite3 ddb $dnddbfile
    if {[string match "" $text]} {
      ddb eval {SELECT charname, race, level FROM ldndrpg WHERE player=$uhost} {
        puthelp "PRIVMSG $nick :Name: \002$charname\002  Race: $race  Level: $level"
      }
    } else {
      set word [string trim $text]
      set charcheck [ddb eval{SELECT player FROM ldndrpg WHERE charname=$word}]
      if ([string match $charcheck $uhost]) {
        ddb eval {SELECT * FROM ldndrpg WHERE charname=$word} {
          puthelp "PRIVMSG $nick :Name: \002$charname\002  Race: $race  Alignment: $align"
          puthelp "PRIVMSG $nick :ExP: $exp  Level: $level  HP: $hp  AC: $ac"
          puthelp "PRIVMSG $nick :Str: $str Con: $con Dex: $dex Int: $int Wis: $wis Cha: $cha"
          puthelp "PRIVMSG $nick :Items: $items"
        }
      }
    }
    ddb close
  }
}



putlog "Lily DnD $dndrpg(version) loaded."

