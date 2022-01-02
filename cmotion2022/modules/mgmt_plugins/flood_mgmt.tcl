# cMotion: admin plugin file for flood mangement
### mgmt version
proc cMotion_plugin_mgmt_flood { handle { arg "" } } {
  global cMotion_flood_info cMotion_flood_last cMotion_flood_lasttext cMotion_flood_undo
  #flood show <handle>
  if [regexp -nocase {show ([^ ]+)} $arg matches handle] {
    cMotion_putadmin "cMotion: Flood for $handle is [cMotion_flood_get $handle]"
		cMotion_putadmin "cMotion: flood: last text for $handle was $cMotion_flood_lasttext($handle)"
		cMotion_putadmin "cMotion: flood: last callback for $handle was $cMotion_flood_last($handle)"
    return 0
  }
  #flood set <handle> <n>
  if [regexp -nocase {set ([^ ]+) (.+)} $arg matches handle value] {
    set cMotion_flood_info($handle) $value
    cMotion_putadmin "cMotion: flood for $handle set to 0"
    return 0
  }
  #status
  if [regexp -nocase {status} $arg] {
    set handles [array names cMotion_flood_info]
    cMotion_putadmin "cMotion: current flood info:"
    foreach handle $handles {
      cMotion_putadmin "$handle: [cMotion_flood_get $handle]"
    }
    return 0
  }
  #all else fails, list help
  cMotion_putadmin "usage: flood \[show|set|status\]"
  return 0
}
cMotion_plugin_add_mgmt "flood" "^flood" n "cMotion_plugin_mgmt_flood" "any" "cMotion_plugin_mgmt_flood_help"
proc cMotion_plugin_mgmt_flood_help { } {
  			cMotion_putadmin "Manage the flood protection system:"
  			cMotion_putadmin "  .cMotion flood status"
  			cMotion_putadmin "    show all tracked flood scores"
  			cMotion_putadmin "  .cMotion flood show <nick>"
  			cMotion_putadmin "    show score for <nick> (case sensitive)"
  			cMotion_putadmin "  .cMotion flood set <nick> <value>"
  			cMotion_putadmin "    set score for <nick> to <value>"
		return 0
  		}
