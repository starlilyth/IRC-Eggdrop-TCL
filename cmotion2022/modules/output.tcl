# Output functions

# init our counters
cMotion_counter_init "output" "lines"
cMotion_counter_init "output" "irclines"
set cMotion_output_delay 0

## cMotionDoAction ###########################################################
proc cMotionDoAction {channel nick text {moreText ""} {noTypo 0} {urgent 0} } {
  cMotion_putloglev 5 * "cMotionDoAction($channel,$nick,$text,$moreText,$noTypo)"
  global cMotionInfo cMotionCache cMotionSettings cMotion_SLEEP
  set cMotion_output_delay 0
  set cMotionCache($channel,last) 1
  #check our global toggle
  global cMotionGlobal
  if {$cMotionGlobal == 0} {return 0}
  # check if we're asleep
  if {$cMotionSettings(asleep) == $cMotion_SLEEP(ASLEEP)} {return 0}
  if [regexp "^\[#!\].+" $channel] {
    set channel [string tolower $channel]
		if {![channel get $channel cMotion]} {
      cMotion_putloglev d * "cMotion: aborting cMotionDoAction ... $channel not allowed"
      return 0
    }
  }
  if {$cMotionInfo(silence) == 1} { return 0 }
  catch {
    if {$cMotionInfo(adminSilence,$channel) == 1} { return 0 }
  }
  cMotion_counter_incr "output" "lines"
  switch [rand 3] {
    0 { }
    1 { set nick [string tolower $nick] }
    2 { set nick "[string range $nick 0 0][string tolower [string range $nick 1 end]]" }
  }
  #do this first
  set text [cMotionDoInterpolation $text $nick $moreText $channel]
  set multiPart 0
  if [string match "*%|*" $text] {
    set multiPart 1
    # we have many things to do
    set thingsToSay ""
    set loopCount 0
    set blah 0
    #make sure we get the last section
    set text "$text%|"
    while {[string match "*%|*" $text]} {
			set origtext $text
      set sentence [string range $text 0 [expr [string first "%|" $text] -1]]
      if {$sentence != ""} {
        if {$blah == 0} {
          set thingsToSay [list $sentence]
          set blah 1
        } else {
          lappend thingsToSay $sentence
        }
      }
      set text [string range $text [expr [string first "%|" $text] + 2] end]
			if {$text == $origtext} {
        putlog "cMotion ALERT! Bailed in cMotionDoAction with $text. Lost output."
        return 0
      }
    }
  }
  if {$multiPart == 1} {
#    foreach lineIn $thingsToSay {
#      set temp [cMotionSayLine $channel $nick $lineIn $moreText $noTypo $urgent]
#      if {$temp == 1} {
#        cMotion_putloglev 1 * "cMotion: cMotionSayLine returned 1, skipping rest of output"
        #1 stops continuation after a failed %bot[n,]
#        break
#      }
#    }
    set typosDone [cMotion_plugins_settings_get "output:typos" "typosDone" "" ""]
    cMotion_putloglev 2 * "cMotion: typosDone (multipart) is !$typosDone!"
    if {$typosDone != ""} {
      cMotion_plugins_settings_set "output:typos" "typosDone" "" "" ""
      if {[rand 2] == 0} {
        cMotionDoAction $channel "" "%VAR{typoFix}" "" 1
      }
      cMotion_plugins_settings_set "output:typos" "typos" "" "" ""
    }
    return 0
  }
  cMotionSayLine $channel $nick $text $moreText $noTypo $urgent
  set typosDone [cMotion_plugins_settings_get "output:typos" "typosDone" "" ""]
  cMotion_putloglev 2 * "cMotion: typosDone is !$typosDone!"
  if {$typosDone != ""} {
    cMotion_plugins_settings_set "output:typos" "typosDone" "" "" ""
    if {[rand 2] == 0} {
      cMotionDoAction $channel "" "%VAR{typoFix}" "" 1
    }
    cMotion_plugins_settings_set "output:typos" "typos" "" "" ""
  }
  return 0
}

proc cMotionDoInterpolation { line nick moreText { channel "" }} {
  global botnick 
  cMotion_putloglev 5 * "cMotionDoInterpolation..."
  if [string match "*%noun*" $line] {
    set line [cMotionInsertString $line "%noun" "%VAR{sillyThings}"]
  }
  cMotion_putloglev 4 * "doing VAR processing"
  set lastloop ""
  while {[regexp -nocase {%VAR\{([^\}]+)\}(\{strip\})?} $line matches BOOM clean]} {
    set replacement [cMotion_abstract_get $BOOM]
    if {$clean != ""} {set replacement [cMotion_strip_article $replacement]}
    regsub -nocase "%VAR\{$BOOM\}$clean" $line $replacement line
	if {$lastloop == $line} {
      putlog "cMotion: ALERT! looping too much in %VAR code with $line (no change since last parse)"
      set line "/has a tremendous error while trying to sort something out :("
	  break
	}
	set lastloop $line
  }
  set loops 0
  cMotion_putloglev 4 * "doing SETTING processing"
  while {[regexp "%SETTING\{(.+?)\}" $line matches settingString]} {
    set var ""
    if [regexp {([^:]+:[^:]+):([^:]+):([^:]+):([^:]+)} $settingString matches plugin setting ch ni] {
      set var [cMotion_plugins_settings_get $plugin $setting $ch $ni]
    }
    incr loops
    if {$loops > 10} {
      putlog "cMotion: ALERT! looping too much in %SETTING code with $line"
      set line "/has a tremendous error while trying to infer the meaning of life :("
    }
    if {$var == ""} {
      putlog "cMotion: ALERT! couldn't find setting $settingString (dropping output)"
      return ""
    }
    set line [cMotionInsertString $line "%SETTING{$settingString}" $var]
  }
  set loops 0
  cMotion_putloglev 4 * "doing NUMBER processing"
  set padding 0
  while {[regexp "%NUMBER\{(\[0-9\]+)\}(\{(\[0-9\]+)\})?" $line matches numberString paddingOpt padding]} {
    set var [cMotion_get_number [cMotion_rand_nonzero $numberString]]
		if {$padding > 0} {
			set fmt "%0$padding"
			append fmt "u"
			set var [format $fmt $var]
		}
    incr loops
    if {$loops > 10} {
      putlog "cMotion: ALERT! looping too much in %NUMBER code with $line"
      set line "/has a tremendous error while trying to think of a number :("
    }
    set line [cMotionInsertString $line "%NUMBER\\{$numberString\\}(\\{\[0-9\]+\\})?" $var]
	set padding 0
  }
  set loops 0
  cMotion_putloglev 4 * "doing TIME processing"
  while {[regexp "%TIME\{(\[a-zA-Z0-9 -\]+)\}" $line matches timeString]} {
	cMotion_putloglev 2 * "found timestring $timeString"
	set origtime $timeString
	regsub -nocase {^-([0-9]) minutes?$} $timeString "\\1 minutes ago" timeString
	set var [clock scan $timeString]
	set var [clock format $var -format "%I:%M %p"]
	cMotion_putloglev 2 * "using time $var"
	incr loops
	if {$loops > 10} {
	  putlog "cMotion: ALERT! looping too much in %TIME code with %line"
	  set line "/has a tremendous error while trying to do complex time mathematics :("
	}
	set line [cMotionInsertString $line "%TIME\\{$origtime\\}" $var]
  }
  cMotion_putloglev 4 * "doing misc interpolation processing for $line"
  set line [cMotionInsertString $line "%%" $nick]
  set line [cMotionInsertString $line "%pronoun" [getPronoun]]
  set line [cMotionInsertString $line "%himherself" [getPronoun]]
  set line [cMotionInsertString $line "%me" $botnick]
  set line [cMotionInsertString $line "%colen" [cMotionGetColenChars]]
  set line [cMotionInsertString $line "%hishers" [getHisHers]]
  set line [cMotionInsertString $line "%heshe" [getHeShe]]
  set line [cMotionInsertString $line "%hisher" [getHisHer]]
  set line [cMotionInsertString $line "%2" $moreText]
  set line [cMotionInsertString $line "%percent" "%"]
  cMotion_putloglev 4 * "done misc"
  #ruser:
  set loops 0
  while {[regexp "%ruser(\{(\[^\}\]+)\})?" $line matches param condition]} {
    set ruser [cMotion_choose_random_user $channel $condition]
    if {$condition == ""} {
      set findString "%ruser"
    } else {
      set findString "%ruser$param"
    }
    regsub $findString $line $ruser line
    incr loops
    if {$loops > 10} {
      putlog "cMotion: ALERT! looping too much in %ruser code with $line"
      return ""
    }
  }
  cMotion_putloglev 4 * "cMotionDoInterpolation returning: $line"
  return $line}

proc cMotionInterpolation2 { line } {
	cMotion_putloglev 5 * "cMotionInterpolation2 ($line)"
  #owners
  set loops 0
  while {[regexp -nocase "%OWNER\{(.*?)\}" $line matches BOOM]} {
    incr loops
    if {$loops > 10} {
      putlog "cMotion: ALERT! looping too much in %OWNER code with $line"
      set line "/has a tremendous error while trying to sort something out :("
    }
    # set line [cMotionInsertString $line "%OWNER\{$BOOM\}" [cMotionMakePossessive $BOOM]]
    regsub -nocase "%OWNER\{$BOOM\}" $line [cMotionMakePossessive $BOOM] line
  }
  set loops 0
  while {[regexp -nocase "%VERB\{(.*?)\}" $line matches BOOM]} {
    incr loops
    if {$loops > 10} {
      putlog "cMotion: ALERT! looping too much in %VERB code with $line"
      set line "/has a tremendous error while trying to sort something out :("
    }
    # set line [cMotionInsertString $line "%VERB\{$BOOM\}" [cMotionMakeVerb $BOOM]]
    regsub -nocase "%VERB\{$BOOM\}" $line [cMotionMakeVerb $BOOM] line
  }
  set loops 0
  while {[regexp -nocase "%PLURAL\{(.*?)\}" $line matches BOOM]} {
    incr loops
    if {$loops > 10} {
      putlog "cMotion: ALERT! looping too much in %PLURAL code with $line"
      set line "/has a tremendous error while trying to sort something out :("
    }
    # set line [cMotionInsertString $line "%PLURAL\{$BOOM\}" [cMotionMakePlural $BOOM]]
    regsub -nocase "%PLURAL\{$BOOM\}" $line [cMotionMakePlural $BOOM] line
  }
  set loops 0
  while {[regexp -nocase "%REPEAT\{(.+?)\}" $line matches BOOM]} {
    incr loops
    if {$loops > 10} {
      putlog "cMotion: ALERT! looping too much in %REPEAT code with $line"
      set line "/has a tremendous error while trying to sort something out :("
    }
		set replacement [cMotionMakeRepeat $BOOM]
    regsub -nocase "%REPEAT\\{$BOOM\\}" $line $replacement line
  }
  return $line}

proc cMotionSayLine {channel nick line {moreText ""} {noTypo 0} {urgent 0} } {
  cMotion_putloglev 5 * "cMotionSayLine: channel = $channel, nick = $nick, line = $line, moreText = $moreText, noTypo = $noTypo"
  global mood cMotionSettings cMotionOriginalInput cMotion_output_delay
  set line [cMotionInterpolation2 $line]
  #if it's a %STOP, abort this
  if {$line == "%STOP"} {
    set line ""
    return 1
  }
  if [regexp {%DELAY\{([0-9]+)\}} $line matches delay] {
	  set cMotion_output_delay $delay
	  cMotion_putloglev d * "Changing output delay to $delay"
	  set line ""
  }
  if {$mood(stoned) > 3} {
    set st [rand 3]
    if {$st == 0} {
      set line "$line man.."
    } else {
      if {$st == 1} {
        set line "$line dude..."
      }
    }
  }
  # Run the plugins :D
  if {$noTypo == 0} {
    set plugins [cMotion_plugin_find_output $cMotionSettings(deflang)]
    if {[llength $plugins] > 0} {
      foreach callback $plugins {
        cMotion_putloglev 1 * "cMotion: output plugin: $callback..."
        catch {
          set result [$callback $channel $line]
        } err
		cMotion_putloglev 3 * "cMotion: returned from output $callback ($result)"
        if [regexp "1�(.+)" $result matches line] {
          break
        }
		if {$result == ""} {
			return 0
		}
        set line $result
      }
    }
  }
  #make sure the line wasn't set to blank by a plugin (may be trying to block output)
  if {($line == "") || [regexp "^ +$" $line]} {
    return 0
  }
	if {[string index $line end] == " "} {
		set line [string range $line 0 end-1]
	}
  #check if this line matches the last line said on IRC
  global cMotionThisText
  if [string match -nocase $cMotionThisText $line] {
    cMotion_putloglev 1 * "cMotion: my output matches the trigger, dropping"
    return 0
  }
	#protect this block - it'll generate an error if noone's talked yet, and then
	#we try an admin plugin
	if [info exists cMotionOriginalInput] {
		if [string match -nocase $cMotionOriginalInput $line] {
			cMotion_putloglev 1 * "my output matches the trigger, dropping"
			return 0
		}
	}
  set line [cMotionInsertString $line "%slash" "/"]
	global cMotion_output_delay
  if [regexp "^/" $line] {
    #it's an action
    mee $channel [string range $line 1 end] $urgent
  } else {
    if {$urgent} {
      cMotion_queue_add_now [chandname2name $channel] $line
    } else {
      cMotion_queue_add [chandname2name $channel] $line $cMotion_output_delay
    }
  }
  return 0
}

proc cMotionInsertString {line swapout toInsert} {
	cMotion_putloglev 5 * "cMotionInsertString ($line, $swapout, $toInsert)"
  set loops 0
  set inputLine $line
  while {[regexp $swapout $line]} {
    regsub $swapout $line $toInsert line
    incr loops
    if {$loops > 10} {
      putlog "cMotion: ALERT! Bailed in cMotionInsertString with $inputLine (created $line) (was changing $swapout for $toInsert)"
      set line "/has a tremendous failure :("
      return $line
    }
  }
  return $line
}

# cMotion_choose_random_user
#
# selects a random user from a channel
# condition is one of:
#   * "" - anyone
#   * male, female - pick by gender
#   * friend, enemy - pick by if we're friends
#   * prev - return previously chosen user
proc cMotion_choose_random_user { channel condition } {
  cMotion_putloglev 5 * "cMotion_choose_random_user ($channel, $condition)"
  global cMotionCache
  set users [chanlist $channel]
  set acceptable [list]
  #check if we want the previous ruser
  if {$condition == "prev"} {
    set what ""
    catch {
      set what [array get cMotionCache "lastruser"]
    }
    cMotion_putloglev 4 * "accept: prev ($what)"
# hmm
    return 0
  }
  foreach user $users {
    cMotion_putloglev 4 * "eval user $user"
    #is it me?
    if [isbotnick $user] { continue }
    #get their handle
    set handle [nick2hand $user $channel]
    cMotion_putloglev 4 * "  handle: $handle"
    #unless we're looking for any old user, we'll need handle
    if {(($handle == "") || ($handle == "*")) && ($condition != "")} {
      cMotion_putloglev 4 * "  --reject: no handle"
      continue
    }
    #else, if we're accepting anyone and they don't have a handle, then use nick
    if {(($handle == "") || ($handle == "*")) && ($condition == "")} {
      cMotion_putloglev 4 * "  ++accept: $user (no handle)"
      lappend acceptable $user
      continue
    }
    if [matchattr $handle b] {
      cMotion_putloglev 4 * "  --reject: not a user"
      continue
    }
    switch $condition {
      "" {
        cMotion_putloglev 4 * "  ++accept: any"
        lappend acceptable $handle
        continue
      }
      "male" {
        if {[getuser $handle XTRA gender] == "male"} {
          cMotion_putloglev 4 * "  ++accept: male"
          lappend acceptable $handle
          continue
        }
      }
      "female" {
        if {[getuser $handle XTRA gender] == "female"} {
          cMotion_putloglev 4 * "  ++accept: female"
          lappend acceptable $handle
          continue
        }
      }
      "friend" {
        if {[getFriendshipHandle $user] > 50} {
          cMotion_putloglev 4 * "  ++accept: friend"
          lappend acceptable $handle
          continue
        }
      }
      "enemy" {
        if {[getFriendshipHandle $user] < 50} {
          cMotion_putloglev 4 * "  ++accept: enemy"
          lappend acceptable $handle
          continue
        }
      }
    }
  }
  cMotion_putloglev 4 * "acceptable users: $acceptable"
  if {[llength $acceptable] > 0} {
    set user [pickRandom $acceptable]
    set index "lastruser"
    set cMotionCache($index) $user
    return $user
  } else {
    if {$condition != ""} {
      return [cMotion_choose_random_user $channel ""]
    } else {
      return ""
    }
  }
}


## Wash nick
#    Attempt to clean a nickname up to a proper name
#
proc cMotionWashNick { nick } {
	cMotion_putloglev 5 * "cMotionWashNick ($nick)"
  #remove leading
  regsub {^[|`_\[]+} $nick "" nick
  #remove trailing
  regsub {[|`_\[]+$} $nick "" nick
  return $nick
}

proc cMotionTransformNick { target nick {host ""} } {
	cMotion_putloglev 5 * "cMotionTransformNick($target, $nick, $host)"
  set newTarget [cMotionTransformTarget $target $host]
  if {$newTarget == "me"} {
    set newTarget $nick
  }
  return $newTarget
}

proc cMotionTransformTarget { target {host ""} } {
	cMotion_putloglev 5 * "cMotionTransformTarget($target, $host)"
  global botnicks
  if {$target == "me"} {
    set himself {\m(your?self|}
    append himself $botnicks
    append himself {)\M}
    if [regexp -nocase $himself $target] {
      set target [getPronoun]
    }
  }
  return $target
}

proc getPronoun {} {
	cMotion_putloglev 5 * "getPronoun"
  global cMotionSettings
  if {$cMotionSettings(gender) == "male"} { return "himself" }
  if {$cMotionSettings(gender) == "female"} { return "herself" }
  return "their self"
}

proc getHisHers {} {
	cMotion_putloglev 5 * "getHisHers"
  global cMotionSettings
  if {$cMotionSettings(gender) == "male"} { return "his" }
  if {$cMotionSettings(gender) == "female"} { return "hers" }
  return "theirs"
}

proc getHisHer {} {
	cMotion_putloglev 5 * "getHisHer"
  global cMotionSettings
  if {$cMotionSettings(gender) == "male"} { return "his" }
  if {$cMotionSettings(gender) == "female"} { return "her" }
  return "their"
}

proc getHeShe {} {
	cMotion_putloglev 5 * "getHeShe"
  global cMotionSettings
  if {$cMotionSettings(gender) == "male"} { return "he" }
  if {$cMotionSettings(gender) == "female"} { return "she" }
  return "they"
}

proc mee {channel action {urgent 0} } {
	cMotion_putloglev 5 * "mee ($channel, $action, $urgent)"
  set channel [chandname2name $channel]
  if {$urgent} {
    cMotion_queue_add_now $channel "\001ACTION $action\001"
  } else {
    cMotion_queue_add $channel "\001ACTION $action\001"
  }
}

proc cMotionMakePossessive { text { altMode 0 }} {
	cMotion_putloglev 5 * "cMotionMakePossessive ($text, $altMode)"
  if {$text == ""} {return "someone's"}
  if {$text == "me"} {
    if {$altMode == 1} {return "mine"}
    return "my"
  }
  if {$text == "you"} {
    if {$altMode == 1} {return "yours"}
    return "your"
  }
  if [regexp -nocase "s$" $text] {return "$text'"}
  return "$text's"
}

proc cMotionMakeRepeat { text } {
	cMotion_putloglev 5 * "cMotionMakeRepeat ($text)"
  if [regexp {([0-9]+):([0-9]+):(.+)} $text matches min max repeat] {
		cMotion_putloglev 4 * "cMotionMakeRepeat: min = $min, max = $max, text = $repeat"
    set diff [expr $max - $min]
    if {$diff < 1} {
    	set diff 1
    }
    set count [rand $diff]
    set repstring [string repeat $repeat $count]
    append repstring [string repeat $repeat $min]
    return $repstring
  }
	cMotion_putloglev 4 * "cMotionMakeRepeat: no match (!), returning nothing"
  return ""
}

proc cMotion_strip_article { text } {
	cMotion_putloglev 5 * "cMotion_strip_article ($text)"
		regsub "(an?|the|some) " $text "" text
		return $text
}

proc cMotionMakeVerb { text } {
	cMotion_putloglev 5 * "cMotionMakeVerb ($text)"
  if [regexp -nocase "(s|x)$" $text matches letter] {
    return $text
  }
  if [regexp -nocase "^(.*)y$" $text matches root] {
    set verb $root
    append verb "ies"
    return $verb
  }
  append text "s"
  return $text
}

proc chr c {
    if {[string length $c] > 1 } { error "chr: arg should be a single char"}
	#   set c [ string range $c 0 0]
	  set v 0;
	  scan $c %c v; return $v
}

proc cMotionMakePlural { text } {
  cMotion_putloglev 5 * "cMotionMakePlural ($text)"
  if [regexp -nocase "(us|is|x|ch)$" $text] {
    append text "es"
    return $text
  }
  if [regexp -nocase "s$" $text] {return $text}
  if [regexp -nocase "^(.*)f$" $text matches root] {
    set plural $root
    append plural "ves"
    return $plural
  }
  if [regexp -nocase "^(.*)y$" $text matches root] {
    set plural $root
    append plural "ies"
    return $plural
  }
  append text "s"
  return $text
}

proc cMotionGetColenChars {} {
	cMotion_putloglev 5 * "cMotionGetColenChars"
  set randomChar "!$!%!*!@!#!~!"
  set randomChars [split $randomChar {}]
  set length [expr [rand 6] + 1]
  set line "!"
  while {$length > 0} {
    incr length -1
    append line [pickRandom $randomChars]
  }
  regsub -all "%%" $line "%percent" line
  return $line}

proc pickRandom { list } {
	cMotion_putloglev 5 * "pickRandom ($list)"
  return [lindex $list [rand [llength $list]]]}

cMotion_putloglev d * "cMotion: output module loaded"
