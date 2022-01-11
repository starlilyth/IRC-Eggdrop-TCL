## plugins engine

## ensure prior loads are cleared 
if [info exists cMotion_plugins_text] { unset cMotion_plugins_text }
set cMotion_plugins_text(dummy) "none"
if [info exists cMotion_plugins_action] { unset cMotion_plugins_action }
set cMotion_plugins_action(dummy) "none"
if [info exists cMotion_plugins_output] { unset cMotion_plugins_output }
set cMotion_plugins_output(dummy) "none"
if [info exists cMotion_plugins_irc_event] { unset cMotion_plugins_irc_event }
set cMotion_plugins_irc_event(dummy) "none"
# (.cMotion)
if [info exists cMotion_plugins_mgmt] { unset cMotion_plugins_mgmt }
set cMotion_plugins_mgmt(dummy) "none"

##############################################################################################################################
## Load a text plugin
proc cMotion_plugin_add_text { id match chance callback language} {
  global cMotion_plugins_text plugins cMotion_testing cMotion_noplugins
  if {$cMotion_testing == 0} {
    catch {
      set test $cMotion_plugins_text($id)
      cMotion_putloglev d * "cMotion: ALERT! text plugin $id is defined more than once"
      return 0
    }
  }
  if [cMotion_plugin_check_allowed "text:$id"] {
    set cMotion_plugins_text($id) "${match}¦${chance}¦${callback}¦${language}"
    cMotion_putloglev 2 * "cMotion: added text plugin: $id"
    append plugins "$id,"
    return 1
  }
  cMotion_putloglev d * "cMotion: ignoring disallowed text plugin $id"
	set cMotion_noplugins 1
}

## Find a text plugin
proc cMotion_plugin_find_text { text lang } {
  global cMotion_plugins_text botnicks
  set s [lsort [array names cMotion_plugins_text]]
  set result [list]
  foreach key $s {
    if {$key == "dummy"} { continue }
    set val $cMotion_plugins_text($key)
    set blah [split $val "¦"]
    set rexp [lindex $blah 0]
    set chance [lindex $blah 1]
    set callback [lindex $blah 2]
    set language [lindex $blah 3]
    if {[string match $lang $language] || ($language == "any")} {
      set rexp [cMotionInsertString $rexp "%botnicks" "${botnicks}"]
      if [regexp -nocase $rexp $text] {
        set c [rand 100]
        cMotion_putloglev 4 * "matched text:$key, chance is $chance, c is $c"
        if {$chance > $c} {
					cMotion_putloglev 4 * "chance is high enough, adding $callback"
          lappend result $callback
        }
      }
    }
  }
  return $result
}

## Load an action plugin
proc cMotion_plugin_add_action { id match chance callback language } {
  global cMotion_plugins_action plugins cMotion_testing cMotion_noplugins
  if {$cMotion_testing == 0} {
    catch {
      set test $cMotion_plugins_action($id)
      cMotion_putloglev d * "cMotion: ALERT! action plugin $id is defined more than once"
      return 0
    }
		if [cMotion_plugin_check_allowed "action:$id"] {
			set cMotion_plugins_action($id) "${match}¦${chance}¦${callback}¦$language"
			cMotion_putloglev 2 * "cMotion: added action plugin: $id"
			append plugins "$id,"
			return 1
		}
		cMotion_putloglev d * "cMotion: ignoring disallowed plugin action:$id"
		set cMotion_noplugins 1
	}
}

## Find an action plugin
proc cMotion_plugin_find_action { text lang } {
  global cMotion_plugins_action botnicks
  set s [lsort [array names cMotion_plugins_action]]
  set result [list]
  foreach key $s {
    if {$key == "dummy"} { continue }
    set val $cMotion_plugins_action($key)
    set blah [split $val "¦"]
    set rexp [lindex $blah 0]
    set chance [lindex $blah 1]
    set callback [lindex $blah 2]
    set language [lindex $blah 3]
    if {[string match $lang $language] || ($language == "any")} {
      set rexp [cMotionInsertString $rexp "%botnicks" "${botnicks}"]
      if [regexp -nocase $rexp $text] {
        set c [rand 100]
        cMotion_putloglev 4 * "matched action:$key, chance is $chance, c is $c"
        if {$chance > $c} {
		  cMotion_putloglev 4 * "chance is high enough, adding $callback"
          lappend result $callback
        }
      }
    }
  }
  return $result
}

## Load an output plugin
proc cMotion_plugin_add_output { id callback enabled language } {
  global cMotion_plugins_output plugins cMotion_testing cMotion_noplugins
  if {$cMotion_testing == 0} {
    catch {
      set test $cMotion_plugins_output($id)
      cMotion_putloglev d * "cMotion: ALERT! Output plugin $id is defined more than once"
      return 0
    }
		if [cMotion_plugin_check_allowed "output:$id"] {
			set cMotion_plugins_output($id) "${callback}¦${enabled}¦$language"
			cMotion_putloglev 2 * "cMotion: added output plugin: $id"
			append plugins "$id,"
			return 1
		}
		cMotion_putloglev d * "cMotion: ignoring disallowed plugin output:$id"
		set cMotion_noplugins 1
	}
}

## Find an output plugin
proc cMotion_plugin_find_output { lang } {
  global cMotion_plugins_output botnicks
  set s [array startsearch cMotion_plugins_output]
  set result [list]
  while {[set key [array nextelement cMotion_plugins_output $s]] != ""} {
    if {$key == "dummy"} { continue }
    set val $cMotion_plugins_output($key)
    set blah [split $val "¦"]
    set callback [lindex $blah 0]
    set enabled [lindex $blah 1]
    set language [lindex $blah 2]
    if {[string match $lang $language] || ($language == "any")} {
      if {$enabled == 1} {
        lappend result $callback
      }
    }
  }
  array donesearch cMotion_plugins_output $s
  return $result
}

## Load an irc event response plugin
proc cMotion_plugin_add_irc_event { id type match chance callback language } {
  if {![regexp -nocase "nick|join|quit|part|split" $type]} {
    cMotion_putloglev d * "cMotion: ALERT! IRC Event plugin $id has an invalid type $type"
    return 0
  }
  global cMotion_plugins_irc_event plugins cMotion_testing cMotion_noplugins
  if {$cMotion_testing == 0} {
    catch {
      set test $cMotion_plugins_irc_event($id)
      cMotion_putloglev d * "cMotion: ALERT! IRC Event plugin $id is defined more than once"
      return 0
    }
		if [cMotion_plugin_check_allowed "irc:$id"] {
			set cMotion_plugins_irc_event($id) "$type¦${match}¦$chance¦$callback¦$language"
			cMotion_putloglev 2 * "cMotion: added IRC event plugin: $id"
			append plugins "$id,"
			return 1
		}
		cMotion_putloglev d * "cMotion: ignoring disallowed plugin irc:$id"
		set cMotion_noplugins 1
	}
}

## Find an IRC Event response plugin plugin
proc cMotion_plugin_find_irc_event { text type lang } {
  if {![regexp -nocase "nick|join|quit|part|split" $type]} {
    cMotion_putloglev d * "cMotion: IRC Event search type $type is invalid"
    return 0
  }
  global cMotion_plugins_irc_event botnicks
  set s [lsort [array names cMotion_plugins_irc_event]]
  set result [list]
  foreach key $s {
    if {$key == "dummy"} { continue }
    set val $cMotion_plugins_irc_event($key)
    set blah [split $val "¦"]
    set etype [lindex $blah 0]
    set rexp [lindex $blah 1]
    set chance [lindex $blah 2]
    set callback [lindex $blah 3]
    set language [lindex $blah 4]
    if {[string match $type $etype]} {
      if {[string match $language $lang] || ($language == "any")} {
        if [regexp -nocase $rexp $text] {
          set c [rand 100]
          if {$chance > $c} {
            lappend result $callback
          }
        }
      }
    }
  }
  return $result
}


## Load mgmt plugin
proc cMotion_plugin_add_mgmt { id match flags callback { language "" } { helpcallback "" } } {
  global cMotion_plugins_mgmt plugins cMotion_testing cMotion_noplugins
  if {$cMotion_testing == 0} {
    catch {
      set test $cMotion_plugins_mgmt($id)
      cMotion_putloglev d * "cMotion: ALERT! mgmt plugin $id is defined more than once ($cMotion_testing)"
      return 0
    }
		if [cMotion_plugin_check_allowed "mgmt:$id"] {
			set cMotion_plugins_mgmt($id) "${match}¦${flags}¦${callback}¦${helpcallback}"
			cMotion_putloglev 2 * "cMotion: added mgmt plugin: $id"
			append plugins "$id,"
			return 1
		}
		cMotion_putloglev d * "cMotion: ignoring disallowed plugin mgmt:$id"
		set cMotion_noplugins 1
	}
}

## Find mgmt plugin
proc cMotion_plugin_find_mgmt { text } {
  global cMotion_plugins_mgmt
  set s [array startsearch cMotion_plugins_mgmt]
  while {[set key [array nextelement cMotion_plugins_mgmt $s]] != ""} {
    if {$key == "dummy"} { continue }
    set val $cMotion_plugins_mgmt($key)
    set blah [split $val "¦"]
    set rexp [lindex $blah 0]
    set flags [lindex $blah 1]
    set callback [lindex $blah 2]
    if [regexp -nocase $rexp $text] {
      array donesearch cMotion_plugins_mgmt $s
      return "${flags}¦$callback"
    }
  }
  array donesearch cMotion_plugins_mgmt $s
  return ""
}

#find a mgmt plugin's help callback
proc cMotion_plugin_find_mgmt_help { name } {
  global cMotion_plugins_mgmt
  set s [array startsearch cMotion_plugins_mgmt]
  while {[set key [array nextelement cMotion_plugins_mgmt $s]] != ""} {
    if {$key == "dummy"} { continue }
    if [string match -nocase $name $key] {
    	set blah [split $cMotion_plugins_mgmt($key) "¦"]
  	  set helpcallback [lindex $blah 3]
  	  array donesearch cMotion_plugins_mgmt $s
	    return $helpcallback
	  }
  }
  array donesearch cMotion_plugins_mgmt $s
  return ""
}

###############################################################################

proc cMotion_plugin_check_depend { depends } {
  #pass a string in the format "type:plugin,type:plugin,..."
  if {$depends == ""} {return 1}
  set result 1
  set blah [split $depends ","]
  foreach depend $blah {
    set blah2 [split $depend ":"]
    set t [lindex $blah2 0]
    set id [lindex $blah2 1]
    set a "cMotion_plugins_$t"
    upvar #0 $a ar
    cMotion_putloglev 1 * "cMotion: checking $a for $id ..."
    set temp [array names ar $id]
    if {[llength $temp] == 0} {
      set result 0
      cMotion_putloglev d * "cMotion: Missing dependency $t:$id"
    }
  }
  return $result
}

###############################################################################

proc cMotion_plugin_check_allowed { name } {
  #pass a string in the format "type:plugin"
  #setting in config should be "type:plugin,type:plugin,..."
  global cMotionSettings
  set disallowed ""
  catch {
    set disallowed $cMotionSettings(noPlugin)
  }
  if {$disallowed == ""} {return 1}
  cMotion_putloglev 4 * "cMotion: checking $name against $disallowed"
  set blah [split $disallowed " "]
  foreach plugin $blah {
    if {$plugin == $name} {
      return 0
    }
  }
  return 1
}

################################################################################

## Load the plugins
## mgmt
set mfiles [glob -nocomplain "$cMotionModules/mgmt_plugins/*_mgmt.tcl"]
foreach m $mfiles {
  cMotion_putloglev 1 * "cMotion: loading mgmt plugin file $m"
  catch {
    source $m
  }
}

## plugins by lang
set languages [split $cMotionSettings(languages) ","]
foreach cMotion_language $languages {
  cMotion_putloglev 2 * "cMotion: loading $cMotion_language plugins"
  foreach type {text action output irc_event} {
    set tfiles [glob -nocomplain "$cMotionPlugins/$cMotion_language/*_$type.tcl"]
    foreach t $tfiles {
        cMotion_putloglev 1 * "cMotion: loading ($cMotion_language) plugin file $t"
        catch {
          source $t
        } err
      if {($err ne "") && ($cMotion_testing == 0)} {
  			putlog "Possible error in plugin file $t - error: $err"
  		}
    }
  }
}

################################################################################

### null plugin routine for faking plugins
proc cMotion_plugin_null { {a ""} {b ""} {c ""} {d ""} {e ""} } {
  return 0
}

# cMotion_plugin_history_add
#
# adds a plugin name to the history list, keeping the list to 10 items
# will not add the plugin if the last one is identical
proc cMotion_plugin_history_add { channel type plugin } {
	global cMotionPluginHistory
	set historyEntry "$channel:$type:$plugin"
	if {$historyEntry == [lindex $cMotionPluginHistory end]} {
		cMotion_putloglev 2 * "Skipping duplicate plugin history entry $historyEntry"
		return 0
	}
	cMotion_putloglev 2 * "Added $historyEntry to plugin history"
	lappend cMotionPluginHistory $historyEntry
	if {[llength $cMotionPluginHistory] > 10} {
		set cMotionPluginHistory [lreplace $cMotionPluginHistory end-10 end]
	}
	return 1
}

# cMotion_plugin_history_check
#
# returns 0 if the plugin hasn't fired recently in the channel
# else returns position in list
proc cMotion_plugin_history_check { channel type plugin } {
	global cMotionPluginHistory
	return [expr [lsearch $cMotionPluginHistory "$channel:$type:$plugin"] + 1]
}

## plugins settings
if {![info exists cMotion_plguins_settings]} {
  set cMotion_plugins_settings(dummy,setting,channel,nick) "dummy"
}

proc cMotion_plugins_settings_set { plugin setting channel nick val } {
  global cMotion_plugins_settings
  if {$nick == ""} { set nick "_" }
  if {$channel == ""} { set channel "_" }
  if {$setting == ""} { 
    cMotion_putloglev d * "cMotion: $plugin tried to save without giving a setting name"
    return 0
  }
  if {$plugin == ""} { 
    cMotion_putloglev d * "cMotion: Unknown plugin trying to save a setting"
    return 0
  }
  set nick [string tolower $nick]
  set channel [string tolower $channel]
  set setting [string tolower $setting]
  set plugin [string tolower $plugin]
  if {$plugin == "dummy"} {
    return ""
  }
  cMotion_putloglev 2 * "cMotion: Saving plugin setting $setting,$channel,$nick -> $val (from plugin $plugin)"
  set cMotion_plugins_settings($plugin,$setting,$channel,$nick) $val
  return 0
}

proc cMotion_plugins_settings_get { plugin setting channel nick } {
  global cMotion_plugins_settings
  if {$nick == ""} { set nick "_" }
  if {$channel == ""} { set channel "_" }
  if {$setting == ""} { 
    cMotion_putloglev d * "cMotion: $plugin tried to get without giving a setting name"
    return 0
  }
  if {$plugin == ""} { 
    cMotion_putloglev d * "cMotion: Unknown plugin trying to get a setting"
    return 0
  }
	set nick [string tolower $nick]
	set channel [string tolower $channel]
	set setting [string tolower $setting]
	set plugin [string tolower $plugin]
  if {$plugin == "dummy"} {return ""}
  if [info exists cMotion_plugins_settings($plugin,$setting,$channel,$nick)] {
    return $cMotion_plugins_settings($plugin,$setting,$channel,$nick)
  }
  cMotion_putloglev 1 * "cMotion: plugin $plugin tried to get non-existent value $setting,$channel,$nick"
  return ""
}

# cMotion: mgmt plugin for plugin management
#register the plugin
cMotion_plugin_add_mgmt "plugin" "^plugin" n "cMotion_plugin_mgmt_plugins" "any" "cMotion_plugin_mgmt_plugin_help"

proc cMotion_plugin_mgmt_plugins { handle { arg "" }} {
  #plugin remove <type> <id>
  if [regexp -nocase {remove ([^ ]+) (.+)} $arg matches t id] {
    set full_array_name_for_upvar "cMotion_plugins_$t"
    upvar #0 $full_array_name_for_upvar TEH_ARRAY
    if [info exists TEH_ARRAY($id)] {
      unset TEH_ARRAY($id)
      cMotion_putadmin "Removed $t plugin $id."
    } else {
      cMotion_putadmin "Plugin ${t}:$id not found."
    }
    return 0
  }
  #enable a plugin
  if [regexp -nocase {enable ([^ ]+) (.+)} $arg matches t id] {
    if {$t == "output"} {
      cMotion_putadmin "Enabling output plugin $id..."
      global cMotion_plugins_output
      set details $cMotion_plugins_output($id)
      set blah [split $details "¦"]
      set callback [lindex $blah 0]
      set enabled [lindex $blah 1]
      set language [lindex $blah 2]
      if {$enabled == 1} {
        cMotion_putadmin "... it's already enabled."
        return 0
      }
      set cMotion_plugins_output($id) "$callback¦1¦$language"
      putlog "cMotion: INFO: Output plugin $id ($language) enabled"
      cMotion_putadmin "...done."
      return 0
    }
    #invalid plugin to enable
    cMotion_putadmin "That's not a valid plugin type."
  }
  #disable a plugin
  if [regexp -nocase {disable ([^ ]+) (.+)} $arg matches t id] {
    if {$t == "output"} {
      cMotion_putadmin "Disabling output plugin $id..."
      global cMotion_plugins_output
      set details $cMotion_plugins_output($id)
      set blah [split $details "¦"]
      set callback [lindex $blah 0]
      set enabled [lindex $blah 1]
      set language [lindex $blah 2]
      if {$enabled == 0} {
        cMotion_putadmin "... it's already disabled."
        return 0
      }
      set cMotion_plugins_output($id) "$callback¦0¦$language"
      putlog "cMotion: INFO: Output plugin $id disabled"
      cMotion_putadmin "...done"
      return 0
    }
    #invalid plugin to enable
    cMotion_putadmin "That's not a valid plugin type."
  }
  # plugin info
  if [regexp -nocase {info ([^ ]+) (.+)} $arg matches t id] {
    set full_array_name_for_upvar "cMotion_plugins_$t"
    upvar #0 $full_array_name_for_upvar TEH_ARRAY
    if [info exists TEH_ARRAY($id)] {
      cMotion_putadmin "Plugin details for ${t}:$id = $TEH_ARRAY($id)"
    } else {
      cMotion_putadmin "Plugin ${t}:$id not found."
    }
    return 0
  }
  # list the plugins
  if [regexp -nocase {list( (.+))?} $arg matches what re] {
  set total 0
    if {$re != ""} {
      cMotion_putadmin "Installed cMotion plugins (filtered for '$re'):"
    } else {
      cMotion_putadmin "Installed cMotion plugins:"
    }
    foreach t {text action output irc_event} {
			set arrayName "cMotion_plugins_$t"
			upvar #0 $arrayName cheese
			set plugins [array names cheese]
			set plugins [lsort $plugins]
			set a "\002$t\002: "
			set count 0
			foreach n $plugins {
				if {($re == "") || [regexp -nocase $re $n]} {
					if {[string length $a] > 5} {
						cMotion_putadmin "$a"
						set a "     "
					}
					if {$n != "dummy"} {
						incr count
						incr total
						if {$t == "output"} {
							set details $cheese($n)
							set blah [split $details "¦"]
							set enabled [lindex $blah 1]
							if {$enabled} {
								append a "$n\[on\], "
							} else {
								append a "$n\[off\], "
							}
						} else {
							append a "$n, "
						}
					}
				}
			}
			set a [string range $a 0 [expr [string length $a] - 3]]
			if {($re != "") && $count} {
				cMotion_putadmin "$a ($count)\n"
			}
		}
		cMotion_putadmin "Total plugins: $total"
		return 0
	}
  #all else fails, give usage:
  cMotion_putadmin "Try: .cmotion help plugin"
  return 0
}
proc cMotion_plugin_mgmt_plugin_help { } {
  			cMotion_putadmin "Manage plugins:"
  			cMotion_putadmin "  .cmotion plugin list \[<search terms>\]"
  			cMotion_putadmin "    List all plugins. If optional search terms are given,"
  			cMotion_putadmin "    list is filtered. Can potentially generate lots of output"
  			cMotion_putadmin "  .cmotion plugin remove <type> <name>"
  			cMotion_putadmin "    Unload a plugin. (To reload, rehash)."
  			cMotion_putadmin "  .cmotion plugin enable <type> <name>"
  			cMotion_putadmin "    Enable a plugin. Currently only output type supports this."
  			cMotion_putadmin "  .cmotion plugin disable <type> <name>"
  			cMotion_putadmin "    Disable a plugin. Currently only output type supports this."
  			cMotion_putadmin "  .cmotion plugin info <type> <name>"
  			cMotion_putadmin "    Display internal information for plugin. This won't mean much"
  			cMotion_putadmin "    unless you know how cMotion plugins are defined."
  		}

	return 0
}

cMotion_putloglev d * "cMotion: plugins module loaded"
