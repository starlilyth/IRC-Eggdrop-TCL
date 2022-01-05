# cMotion: mgmt plugin file for abstracts
proc cMotion_plugin_mgmt_abstract { handle { arg "" }} {
  # abstract show <name>
  if [regexp -nocase {show ([^ ]+)} $arg matches name] {
    set result [cMotion_abstract_all $name]
    # cMotion_putadmin "$result"
    cMotion_putadmin "Abstract $name has [llength $result] items."
    set i 0
    foreach a $result {
      cMotion_putadmin "$i: $a"
      incr i
    }
    return 0
  }
  # abstract status
  if [regexp -nocase {status} $arg] {
    global cMotion_abstract_contents cMotion_abstract_timestamps absdb
    cMotion_putadmin "cMotion abstract lists not in memory:"
    set absMem [lsort [array names cMotion_abstract_contents]]
    # count tables in the DB
    set total 0
    sqlite3 adb $absdb
    set tables [lsort [adb eval {SELECT name FROM sqlite_master WHERE type='table'}]]
    foreach table $tables {
      set abname [string range $table 7 end]
      if {[lsearch $absMem $abname] == -1 || [llength $absMem] == 0} {
        set itemCount [adb eval "SELECT COUNT() FROM $table"]
        cMotion_putadmin "$abname: $itemCount items"
      }
      incr total
    }
    cMotion_putadmin "\ncMotion abstract lists in memory:"
    # abstract lists in the array
    set mem 0
    foreach abst $absMem {
      set diff [expr [clock seconds]- $cMotion_abstract_timestamps($abst)]
      cMotion_putadmin "$abst: [llength [cMotion_abstract_all $abst]] items, $diff seconds since used"
      incr mem
    }
    cMotion_putadmin "\n$total total abstract lists, $mem loaded into memory"
    return 0
  }
  # abstract delete
  if [regexp -nocase {delete (.+) (.+)} $arg matches name index] {
    cMotion_putadmin "Deleting element $index from abstract $name...\r"
    cMotion_abstract_delete $name $index
    return 0
  }
  # abstract gc
  if [regexp -nocase {gc} $arg matches] {
    cMotion_putadmin "Garbage collecting..."
    cMotion_abstract_gc
    return 0
  }
  # abstract flush
	if [regexp -nocase "flush" $arg] {
		cMotion_abstract_flush
		cMotion_putadmin "Flushing all abstracts from memory"
		return 0
	}
  #all else fails, list help
	cMotion_putadmin "Try .cmotion help abstract"
  return 0
}

proc cMotion_plugin_mgmt_abstract_help { } {
	cMotion_putadmin "Manage abstracts in cMotion."
	cMotion_putadmin "  .cMotion abstract show <abstract>"
	cMotion_putadmin "    List the contents of an abstract (Potentially much output!)"
	cMotion_putadmin "  .cMotion abstract status"
	cMotion_putadmin "    List all abstracts and their status (Much ouput!)"
	cMotion_putadmin "  .cMotion abstract delete <abstract> <index>"
	cMotion_putadmin "    Delete an element from an abstract"
	cMotion_putadmin "    Index is 0-based; use the show command to find entries"
	cMotion_putadmin "  .cMotion abstract gc"
	cMotion_putadmin "    Force a garbage collection of abstracts (pages out unused ones)"
	cMotion_putadmin "  .cMotion abstract flush"
	cMotion_putadmin "    Flush all abstracts from memory. For changing lang on the fly."
	return 0
}
# register the plugin
cMotion_plugin_add_mgmt "abstract" "^abstract" n "cMotion_plugin_mgmt_abstract" "any" "cMotion_plugin_mgmt_abstract_help"
