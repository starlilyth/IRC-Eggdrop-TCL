# cMotion: admin plugin file for facts
proc cMotion_plugin_mgmt_fact { handle { arg "" }} {
  global cMotionFacts
  # fact show <type> <item>
  if [regexp -nocase {show ([^ ]+) ([^ ]+)} $arg matches type item] {
    if [info exists cMotionFacts($type,$item)] {
      set known $cMotionFacts($type,$item)
      cMotion_putadmin "Known '$type' facts about '$item':"
      set count 0
      foreach fact $known {
        cMotion_putadmin "$count: $fact"
        incr count
      }
    } else {
      cMotion_putadmin "No facts found for $item ($type)"
    }
    return 0
  }
  # status
  if [regexp -nocase {status} $arg] {
    set items [lsort [array names cMotionFacts]]
    set itemcount 0
    set factcount 0
    cMotion_putadmin "Known facts: <item> (<type>)"
    foreach item $items {
      lassign [split $item ","] type subj
      cMotion_putadmin "$subj ($type): [llength $cMotionFacts($item)] facts"
      incr itemcount
      incr factcount [llength $cMotionFacts($item)]
    }
    cMotion_putadmin "Total: $factcount facts about $itemcount items"
    return 0
  }
  # save
  if [regexp -nocase {save} $arg] {
    cMotion_putadmin "Saving facts..."
    cMotion_facts_save
    return 0
  }
  # forget
  if [regexp -nocase {forget ([^ ]+) ([^ ]+)} $arg matches type item] {
    cMotion_facts_forget_all $type $item
    return 0
  }
  #all else fails, list help
  cMotion_putadmin "Try .cmotion help fact"
  return 0
}

proc cMotion_plugin_mgmt_fact_help { } {
  cMotion_putadmin "Manage facts in cMotion:"
  cMotion_putadmin "  .cmotion fact status"
  cMotion_putadmin "    Facts system status"
  cMotion_putadmin "  .cmotion fact show <type> <item>"
  cMotion_putadmin "    Fact details about an item"
  cMotion_putadmin "    Ex: '.cmotion fact show what cMotion'"
  cMotion_putadmin "  .cmotion fact save"
  cMotion_putadmin "    Saves in memory facts to DB"
  cMotion_putadmin "  .cmotion fact forget <type> <item>"
  cMotion_putadmin "    Removes in memory facts about <item>"
  return 0
}
# register the plugin
cMotion_plugin_add_mgmt "fact" "^fact" n "cMotion_plugin_mgmt_fact" "any" "cMotion_plugin_mgmt_fact_help"
