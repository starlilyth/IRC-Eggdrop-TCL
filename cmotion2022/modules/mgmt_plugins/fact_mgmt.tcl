# cMotion: admin plugin file for facts
proc cMotion_plugin_mgmt_fact { handle { arg "" }} {
  global cMotionFacts
  # fact show <type> <name>
  if [regexp -nocase {show ([^ ]+) ([^ ]+)} $arg matches t name] {
    set known $cMotionFacts($t,$name)
    cMotion_putadmin "Known '$t' facts about: $name"
    set count 0
    foreach fact $known {
      cMotion_putadmin "$count: $fact"
      incr count
    }
    return 0
  }
  # status
  if [regexp -nocase {status} $arg] {
    set items [lsort [array names cMotionFacts]]
    set itemcount 0
    set factcount 0
    #cMotion_putadmin "Known facts:"
    foreach item $items {
      #cMotion_putadmin "$item ([llength $cMotionFacts($item)])"
      incr itemcount
      incr factcount [llength $cMotionFacts($item)]
    }
    cMotion_putadmin "Total: $factcount facts about $itemcount items"
    return 0
  }
  # save
  if [regexp -nocase {save} $arg] {
    cMotion_putadmin "saving facts..."
    cMotion_facts_save
    return 0
  }

  #all else fails, list help
  cMotion_putadmin {use: fact [show <type> <name>|status]}
  return 0
}
# register the plugin
cMotion_plugin_add_mgmt "fact" "^fact" n "cMotion_plugin_mgmt_fact" "any"