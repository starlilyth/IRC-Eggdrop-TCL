# cMotion: mgmt plugins for emotions mangement
# mood 
proc cMotion_mood_admin { handle { arg "" } } {
	global mood
	if {($arg == "") || ($arg == "status")} {
		#output our mood
		cMotion_putadmin "Current mood status:"
		foreach moodtype {happy lonely stoned} {
			cMotion_putadmin "  $moodtype: $mood($moodtype)"
		}
		return 0
	}
	if {$arg == "drift"} {
		cMotion_putadmin "Drifting mood values..."
		driftmood
		return 0
	}
	if {[regexp -nocase {set ([^ ]+) ([0-9]+)} $arg matches moodname moodval]} {
		if {[info tclversion] < 8.4} {
			cMotion_putadmin "Sorry, the mood set command needs TCL >= 8.4 :/"
			return
		}
		if {!([lsearch -inline {happy lonely stoned} $moodname] == $moodname)} {
			cMotion_putadmin "Unknown mood type '$moodname'"
			return 0
		}
		set mood($moodname) $moodval
		cMotion_putadmin "Mood '$moodname' changed to $moodval"
		return 0
	}

	cMotion_putadmin "use: mood \[status|drift|set <type> <value>\]"
	return 0
}

# mgmt help callback
proc cMotion_mood_admin_help { } {
	cMotion_putadmin "Controls the mood system:"
	cMotion_putadmin "  .cMotion mood [status]"
	cMotion_putadmin "    View a list of all moods and their values"
	cMotion_putadmin "  .cMotion mood set <name> <value>"
	cMotion_putadmin "    Set mood <name> to <value>. The neutral value is usually 0. Max/min is (-)30."
	cMotion_putadmin "  .cMotion mood drift"
	cMotion_putadmin "    Runs a mood tick."
}

if {$cMotion_testing == 0} {
	cMotion_plugin_add_mgmt "mood" "^mood" n cMotion_mood_admin "any" cMotion_mood_admin_help
}
#friendship
proc cMotion_plugin_mgmt_friends { handle { arg "" } } {
	if [regexp -nocase {show (.+)} $arg matches nick] {
		if {$nick == "all"} {
			cMotion_putadmin [getFriendsList]
			return 0
		}
		cMotion_putadmin "Friendship rating for $nick is [getFriendshipHandle $nick]%"
		return 0
	}
  if [regexp -nocase {set ([^ ]+) ([0-9]+)} $arg matches nick val] {
     setFriendshipHandle $nick $val
     cMotion_putadmin "Friendship rating for $nick is now [getFriendshipHandle $nick]%"
		return 0
  }  
  cMotion_putadmin "usage: friendship \[show|set\]"
}
cMotion_plugin_add_mgmt "friends" "^friends?(hip)?" n "cMotion_plugin_mgmt_friends" "any" "cMotion_plugin_mgmt_friends_help"
proc cMotion_plugin_mgmt_friends_help { } {
  			cMotion_putadmin "Lists cMotion's friendships"
  			cMotion_putadmin "  .cMotion friends show <nick>"
  			cMotion_putadmin "    Shows the rating for the user"
  			cMotion_putadmin "  .cMotion friends show -all"
  			cMotion_putadmin "    Shows A LOT OF OUTPUT!!1"
  			cMotion_putadmin "  .cMotion friends set <nick> <value>"
  			cMotion_putadmin "    Sets user's friendship rating"
  			cMotion_putadmin "Friendships are rated 0-100% with 50% being neutral. All users start on 50%."
  			cMotion_putadmin "Actions against the bot affect friendships; friendships drift back to 40 or 60% (depending"
  			cMotion_putadmin "on if they are lower or higher than those limits)."
		return 0
}
