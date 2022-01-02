# cMotion plugin irc_quit.tcl 
proc cMotion_plugins_irc_default_quit { nick host handle channel text } { 
	#has something happened since we last spoke?
	set lasttalk [cMotion_plugins_settings_get "system:join" "lasttalk" $channel ""]
	if {[cMotion_setting_get "friendly"] == "2"} {return 0}
	if {$handle == "*"} {
		if {[cMotion_setting_get "friendly"] != 1} {return 0}
	}
	if {[cMotionIsFriend $nick]} {
		set output "%VAR{departs-nice}"
	} else {
		set output "%VAR{departs-nasty}"
	}
	# check if the handle is still in the channel
	set count 0
	foreach n [chanlist $channel] {
		if {[nick2hand $n $channel] == $handle} {
			# we have a match
			incr count
		}
	}
	# note: this is 2 not 1 because this event is fired BEFORE eggdrop processes the part/quit
	if {$count == 2} {
		cMotion_putloglev d * "$nick has $count matching handles in $channel, so not saying bye"
		return 0
	}
	#don't do anything if it looks like an error
	if [regexp -nocase "(k-?lined|d-?lined|ircd?\.|error|reset|timeout|closed|peer|\.net|timed|eof|lost)" $text] {
		return 0
	}
	#if 1, we greeted someone last
	#if 0, someone has said something since
	if {$lasttalk == 1} {
		#cMotion_putloglev 2 d "dropping depart for $nick on $channel because it's too idle"
		cMotion_putloglev d * "dropping depart for $nick on $channel because it's too idle"
		return 0
	}
	cMotionDoAction $channel $nick $output
	cMotion_plugins_settings_set "system:join" "lasttalk" $channel "" 1
	cMotion_plugins_settings_set "system:join" "lastleft" $channel "" $nick
	cMotion_plugins_settings_set "system:join" "lastgreeted" $channel "" $nick

	return 1
}
cMotion_plugin_add_irc_event "default quit" "quit" ".*" 15 "cMotion_plugins_irc_default_quit" "en"
cMotion_plugin_add_irc_event "default part" "part" ".*" 15 "cMotion_plugins_irc_default_quit" "en"

cMotion_abstract_register "departs-nice"
cMotion_abstract_batchadd "departs-nice" { "bye %%" "later %% %VAR{smiles}" "I miss %% already" "never enough time in the day.." }

cMotion_abstract_register "departs-nasty"
cMotion_abstract_batchadd "departs-nasty" { "i don't like them" "i hope they don't come back" "%%: AND DON'T COME BACK!" "%%: don't let the door hit your ass on the way out%|because I don't want ass-prints on my new door!" }
