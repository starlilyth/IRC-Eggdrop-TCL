# cMotion plugin irc_join.tcl 
# TODO: better logic - check if user was bounced. check for dupe nick by nick, not just handle. tbqh, needs to track its own friends, not use bot entries (aka $handle). 
proc cMotion_plugins_irc_default_join { nick host handle channel text } { 
  #if the user isban then dont bother
  if {([ischanban $nick $channel])|([matchattr $handle +k $channel]) == 1 } {
    cMotion_putloglev 2 d "dropping greeting for $nick on $channel as user is banned"
    return 0
  }
	#has something happened since we last greeted?
	set lasttalk [cMotion_plugins_settings_get "system:join" "lasttalk" $channel ""]
	#if 1, we greeted someone last
	#if 0, someone has said something since
	if {$lasttalk == 1} {
		cMotion_putloglev 2 d "dropping greeting for $nick on $channel because it's too idle"
		return 0
	}
	# check if the user is already in the channel - probably means they've joined a 2nd client
	# or that they're about to ping out or something
	set count 0
	foreach n [chanlist $channel] {
		if {[nick2hand $n $channel] == $handle} {
			# we have a match
			incr count
		}
	}	
	if {$count >= 2} {
		cMotion_putloglev d * "$nick has $count matching handles in $channel, so not greeting"
		return 1
	}
	global botnick mood
	set chance [rand 10]
	set greetings [cMotion_abstract_all "greetings"]
	set lastLeft [cMotion_plugins_settings_get "system:join" "lastleft" $channel ""]
	if {[cMotion_setting_get "friendly"] == "2"} {
		# don't greet anyone
		return 0
	}
	if {$handle != "*"} {
		if {![rand 10]} {
			set greetings [concat $greetings [cMotion_abstract_all "insult_joins"]]
		}
		if {$nick == $lastLeft} {
			set greetings [cMotion_abstract_all "welcomeBacks"]
			cMotion_plugins_settings_set "system:join" "lastleft" $channel "" ""
		}
		cMotionGetHappy
		cMotionGetUnLonely
	} else {
		#don't greet people we don't know
		if {[cMotion_setting_get "friendly"] != 1} {
			return 0
		}
	}
	#set nick [cMotion_cleanNick $nick $handle]
	if {[getFriendship $nick] < 30} {
		set greetings [cMotion_abstract_all "dislike_joins"]
	}
	if {[getFriendship $nick] > 75} {
		set greetings [concat $greetings [cMotion_abstract_all "bigranjoins"]]
	}
	cMotionDoAction $channel $nick [pickRandom $greetings]
	cMotion_plugins_settings_set "system:join" "lastgreeted" $channel "" $nick
	cMotion_plugins_settings_set "system:join" "lasttalk" $channel "" 1
	return 1
}

cMotion_plugin_add_irc_event "default join" "join" ".*" 40 "cMotion_plugins_irc_default_join" "en"

cMotion_abstract_register "bigranjoins"
cMotion_abstract_batchadd "bigranjoins" { "there you are, %%" "BOOM!" "%%%colen" "%%!" "%% %VAR{smiles}" "oh yay! it's %% %VAR{smiles}" }

cMotion_abstract_register "insult_joins"
cMotion_abstract_batchadd "insult_joins" { "who are you, again?" "you again?" "you came back?" "woah, didn't think I would see %% again..." "oh look what the cat dragged in..." "oh damn, I gotta go, %% is here" }

cMotion_abstract_register "dislike_joins"
cMotion_abstract_batchadd "dislike_joins" { "oh no, it's %%" "aw, it's %%" "oh noes it's %% %VAR{unsmiles}" "must be time to clean the catbox..." "bbl" }
