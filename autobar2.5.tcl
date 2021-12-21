# AutoBar script for IRC by Lily <lily@disorg.net>
# Requires TCL8.4 or greater, and the sqlite3 tcl lib. (not mysql!) 
# For deb/ubuntu, that is the libsqlite3-tcl package. Adjust for your flavor. 
# V1 - 8/2012
# V2 - bstats, drink specials, nokitchen, menu formatting, ctrl channel. 
# V2.5 - round for the house/everyone
# TODO: !menu type full? fuzzy matching?
# random responses: when ordering the special; tip beg, backhand compliments. 
# with toast = random toast, birthday, random output?
# timer - too many in an hour = cutoff 
# recipes - scrape webtender
# shot type = shotcall, video poker wins drink 
set autobar(ctrlch) "#bongpoke"
set autobar(notify) "Y"
# --------------------------------------------
set autobar(vers) 2.5
setudef flag autobar
package require sqlite3
set bdbfile "./autobar.db"
bind pub -|- !order border_proc
bind pub -|- !menu bmenu_proc
bind pub -|- !bedit bedit_proc
bind pub -|- !bstats bstats_proc
bind time - "50 * * * *" btime_proc

proc border_proc {nick uhost hand chan text} {
  if {[string match "*+autobar*" [channel info $chan]]} {  
    global bdbfile autobar
    if {$text == "help"} {
     puthelp "PRIVMSG $chan :\001ACTION gives $nick the !menu\001"
     bmenu_proc $nick $uhost $hand $chan $text
     return 0
    }
    sqlite3 bdb $bdbfile
    if {$text == ""} {
      puthelp "PRIVMSG $chan :\001ACTION gets a $autobar(dspecial) for $nick, and offers them the !menu\001"
      return 0
    }
    if {[regexp -nocase "for" $text]} {
      regexp {^(.*?) for (.*?)$} $text - order guest
    } {
      set order $text
      set guest $nick
    }  
    set order [string trim $order]
    set guest [string trim $guest]
    regsub -nocase {^(a|the|some) } $order "" order
    set bround "false"
    if {[regexp -nocase {^round} $order]} {
      set bround "true"
      regsub -nocase {^(round|round of)} $order "" order       
      set order [string trim $order]
      if {$order == ""} {
        set order [bdb onecolumn {SELECT item FROM autobar where type='draft' ORDER BY RANDOM() LIMIT 1}]
      }
    } 
	if {[regexp -nocase {(drink|beer|draft|bottle|shot|special)s?$} $order]} {
	  regsub -nocase {(s?$)} $order "" order
      switch -nocase $order drink {
        set order [bdb onecolumn {SELECT item FROM autobar where type='mixed' ORDER BY RANDOM() LIMIT 1}]
      } beer {
        set order [bdb onecolumn {SELECT item FROM autobar where type='draft' OR type ='bottle' ORDER BY RANDOM() LIMIT 1}]
      } draft {
        set order [bdb onecolumn {SELECT item FROM autobar where type='draft' ORDER BY RANDOM() LIMIT 1}]
      } bottle {
        set order [bdb onecolumn {SELECT item FROM autobar where type='bottle' ORDER BY RANDOM() LIMIT 1}]
      } shot {
        set order [bdb onecolumn {SELECT item FROM autobar where type='shot' ORDER BY RANDOM() LIMIT 1}]
      } special {
        set order $autobar(dspecial)                
      }
    }
    set imatch [bdb onecolumn {SELECT item FROM autobar WHERE item=$order}]
    if {[string match -nocase $order $imatch]} {
	# do magic
      set now [clock seconds]
      bdb eval {UPDATE autobar SET otime=$now WHERE item=$imatch}
      bdb eval {UPDATE autobar SET ocount=ocount+1 WHERE item=$imatch}
      set otype [bdb onecolumn {SELECT type FROM autobar WHERE item=$order}]
      if {[regexp -nocase {(the house|everyone|the bar)} $guest]} { set bround "true" }
      if {$bround == "true"} { 
        if {$otype == "Food"} { set imatch $autobar(nokitchen) } {
          switch -nocase $otype Mixed {
        puthelp "PRIVMSG $chan :\001ACTION sets up glasses on the bar and mixes up a batch of $imatch's for $guest\001"          
          } Bottle { 
            puthelp "PRIVMSG $chan :\001ACTION starts opening bottles of $imatch and passing them out to everyone\001"
          } Draft { 
            puthelp "PRIVMSG $chan :\001ACTION starts filling glasses with $imatch and setting them up on the bar\001"
          } Shot { 
            puthelp "PRIVMSG $chan :\001ACTION gets the $imatch bottle out and lines up some shotglasses for everyone\001"
          }
        bdb close 
        return 0
        }
      }
      switch -nocase $otype Mixed {
        puthelp "PRIVMSG $chan :\001ACTION grabs some bottles from the bar, mixes up a $imatch and serves it to $guest\001"
      } Bottle {
        puthelp "PRIVMSG $chan :\001ACTION pulls a $imatch bottle out of the ice, pops the top and puts it in front of $guest\001"
      } Draft {
        puthelp "PRIVMSG $chan :\001ACTION pours a glass of $imatch from the tap and slides it down the bar to $guest\001"
      } Food { 
        if {$autobar(nokitchen) != $imatch} {
          puthelp "PRIVMSG $chan :\001ACTION puts a $imatch order into the kitchen\001"
          set friesaredone [after 120000 [list puthelp "privmsg $chan :$guest? Your $imatch order is ready!" ]]
        } {
          puthelp "PRIVMSG $chan :Sorry, we are out of $order right now."
        }
      } Shot {
        puthelp "PRIVMSG $chan :\001ACTION gets out the $imatch bottle and pours a shot for $guest, then asks \"Who else is in on this?\" \001"
      } Drugs {
        puthelp "PRIVMSG $chan :\001ACTION looks both ways, then pulls a $imatch out from under the bar, and slides it towards $guest\001"
      } default {
        puthelp "PRIVMSG $chan :\001ACTION gets $guest a $imatch\001"
      }
      if {$autobar(notify) == "Y"} {
        puthelp "PRIVMSG $autobar(ctrlch) :Served $imatch on $chan"
      }
    } {
      puthelp "PRIVMSG $chan :I'm sorry, $nick, I haven't heard of $order. Check the !menu and try again?"
      if {[string match -nocase $chan $autobar(ctrlch)] & [isop $nick $autobar(ctrlch)]} {
        puthelp "PRIVMSG $chan :You can add it with: \"!bedit add <type> $order\""
      }
      if {$autobar(notify) == "Y"} {
        puthelp "PRIVMSG $autobar(ctrlch) :$guest tried ordering $order on $chan"
      }
    }
    bdb close
  }
}

proc btime_proc {min hour day month year} {
  global bdbfile autobar
  sqlite3 bdb $bdbfile
  set autobar(dspecial) [bdb onecolumn {SELECT item FROM autobar where type = 'mixed' ORDER BY ocount, RANDOM() DESC LIMIT 1 OFFSET 15}]
  if {[bdb eval {select count(*) from autobar where type = 'food'}] > 1} {
    set autobar(nokitchen) [bdb onecolumn {SELECT item FROM autobar where type = 'food' ORDER BY RANDOM() LIMIT 1}]
  }
  bdb close
}
btime_proc * * * * *

proc bstats_proc {nick uhost hand chan text} {
  if {[string match "*+autobar*" [channel info $chan]]} {  
    global bdbfile autobar
    sqlite3 bdb $bdbfile
    set dtotal [bdb eval {select count(1) from autobar where type != 'drugs'}]
    foreach {type} [bdb eval {SELECT DISTINCT type FROM autobar where type != 'drugs'}] {
      set tcount [bdb eval {select count(1) from autobar where type=$type}] 
      append counts "$tcount $type, "
    }
    set counts [string trimright $counts ", "]
    set topo [bdb onecolumn {select item from autobar order by ocount desc limit 1}]
    set newo [bdb onecolumn {select item from autobar order by rowid desc limit 1}]
    puthelp "PRIVMSG $chan :There are $dtotal items in the bar: $counts. The current special is $autobar(dspecial). $topo is ordered the most. $newo is the newest addition. AutoBar V$autobar(vers)" 
  }   
} 
   
proc bmenu_proc {nick uhost hand chan text} {
  if {[string match "*+autobar*" [channel info $chan]]} {  
    global bdbfile autobar
    sqlite3 bdb $bdbfile
    foreach {stype} [bdb eval {SELECT distinct type FROM autobar where type != 'drugs' ORDER by ocount desc}] { lappend typelist $stype }
    puthelp "PRIVMSG $nick :You can order any item with \"!order Item Name\" in the channel:"
    
    foreach {type} $typelist {
      foreach {mitem} [bdb eval {select item from autobar where type=$type order by ocount desc limit 15}] {
        append menulist "\002$mitem\002, "
      }
      set menulist [string trimright $menulist ", "] 
      set itotal [bdb eval {select count(1) from autobar where type=$type}]
      if {$itotal >= 15} { 
        set newi 0
        foreach {ritem} [bdb eval {select item from autobar where type=$type order by otime desc LIMIT 10}] {
          if {![regexp $ritem $menulist]} {
            append rmenu "\002$ritem\002, "
            incr newi
          } { continue }   
        }
        set rmenu [string trimright $rmenu ", "] 
        if {$newi==0} {puthelp "PRIVMSG $nick :$type Menu: $menulist"} {
          set remi [expr $itotal-(15+$newi)]
          if {$remi != 0} {
            puthelp "PRIVMSG $nick :$type Menu: Most Requested - $menulist. Recently Ordered - $rmenu. (plus $remi others)"
          } {
            puthelp "PRIVMSG $nick :$type Menu: Most Requested - $menulist. Recently Ordered - $rmenu."
          }        
        }
      } {
        puthelp "PRIVMSG $nick :$type Menu: $menulist"
      }
      set menulist ""
      set rmenu ""
    }
    puthelp "PRIVMSG $nick :The current special is: \002$autobar(dspecial)\002. You can order it by name or with \"!order special\". Try \"!order drink\", \"!order beer\", or \"!order shot\" if you feel adventurous (or just lazy!) You can order for someone else using \"!order Item for nickname\"."
    bdb close
    if {[isop $nick $autobar(ctrlch)]} {
      puthelp "PRIVMSG $nick :As a control channel operator, you may also use the !bedit command. Do \"!bedit help\" in $autobar(ctrlch) for details."
      # drugs menu nere?
    }
    puthelp "PRIVMSG $nick :AutoBar $autobar(vers) by Lily <lily@disorg.net>"
  }    
}

proc bedit_proc {nick uhost hand chan text} {
  if {[string match "*+autobar*" [channel info $chan]]} {  
    global bdbfile autobar
    if {![isop $nick $autobar(ctrlch)]} {
      puthelp "PRIVMSG $chan :You dont have permission for that."
      return 0
    }  
    sqlite3 bdb $bdbfile
	if {$text == {} | [lindex $text 1] == {}} {
      foreach {type} [bdb eval {SELECT DISTINCT type FROM autobar where type != 'drugs'}] {
        append types "$type, "
      }
      set types [string trimright $types ", "]
      puthelp "privmsg $chan :Add items with \"!bedit add <type> Item Name\", where <type> is one of $types. Remove items with \"!bedit remove Item Name\"."
    } {    
      set cmd [lindex $text 0]
      if {[string match -nocase "remove" $cmd]} {
        set item [lrange $text 1 end]
        set itemmatch [bdb onecolumn {SELECT item FROM autobar WHERE item=$item}]
        if {[string match -nocase $item $itemmatch]} {
          bdb eval {DELETE FROM autobar WHERE item=$item}
          puthelp "privmsg $chan :$item removed from the menu."
        } {
          puthelp "privmsg $chan :I dont seem to have $item on the menu."
        }
      } {  
        set type [lindex $text 1]
        set item [lrange $text 2 end]
        set typematch [bdb eval {SELECT DISTINCT type FROM autobar}]
        set itemmatch [bdb onecolumn {SELECT item FROM autobar WHERE item=$item}]
        if {[string match -nocase "add" $cmd]} {   
		  if {$item == {} } {
		    puthelp "privmsg $chan :I didn't get all that, try again?"
          } elseif {[string match -nocase $item $itemmatch]} {
            puthelp "privmsg $chan :That item is already on the menu."
#type validation here. comment out to add new types. the default action is lame though. 
		  } elseif {![regexp -nocase $type $typematch]} {
            puthelp "privmsg $chan :That is an unrecognized type."
          } else {
            foreach word $item {lappend citem [string totitle $word]}
            set ctype [string totitle $type]            
            set now [clock seconds]
            bdb eval {INSERT INTO autobar(item, type, ocount, otime) VALUES ($citem, $ctype, 0, $now)}
            puthelp "privmsg $chan :$citem added to the menu as a $ctype item."
          }
        } {
          puthelp "privmsg $chan :I didn't understand you, sorry. Try \"!bedit help\"."
        }
      }
    }
    bdb close
  }
}

if {![file exists $bdbfile]} { 
  sqlite3 bdb $bdbfile
    set now [clock seconds]
    bdb eval {CREATE TABLE autobar(item TEXT COLLATE NOCASE, type TEXT COLLATE NOCASE, ocount INTEGER, otime INTEGER)}
    bdb eval {INSERT INTO autobar(item, type, ocount)VALUES("Bloody Mary", "Mixed", 10, $now)}
    bdb eval {INSERT INTO autobar(item, type, ocount)VALUES("Heineken", "Bottle", 6, $now)}
    bdb eval {INSERT INTO autobar(item, type, ocount)VALUES("Budweiser", "Draft", 8, $now)}
    bdb eval {INSERT INTO autobar(item, type, ocount)VALUES("Tequila", "Shot", 4, $now)}
    bdb eval {INSERT INTO autobar(item, type, ocount)VALUES("Nachos", "Food", 2, $now)}
    bdb eval {INSERT INTO autobar(item, type, ocount)VALUES("Coffee", "Other", 1, $now)}
    bdb eval {INSERT INTO autobar(item, type, ocount)VALUES("Joint", "Drugs", 1, $now)}
  bdb close
}
putlog "AutoBar $autobar(vers) loaded!"