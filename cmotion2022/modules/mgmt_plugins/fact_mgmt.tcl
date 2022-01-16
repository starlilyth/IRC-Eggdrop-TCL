# cMotion: admin plugin file for facts
proc cMotion_plugin_mgmt_fact { handle { arg "" }} {
  global cMotionFacts
  # fact show <type> <item>
  if [regexp -nocase {show ([^ ]+) ([^ ]+)} $arg matches type item] {
    if ![regexp ^(what|who)$ $type] {
      cMotion_putadmin "Valid types are \"who\" and \"what\""
      return 0
    }
    if {$item eq "*"} {
      set items [lsort [array names cMotionFacts]]
      set itemcount 0
      set factcount 0
      cMotion_putadmin "Known \"$type\" facts"
      foreach i $items {
        lassign [split $i ","] t subj
        if {$t eq $type} {
          cMotion_putadmin "$subj ($t): [llength $cMotionFacts($t,$subj)] facts"
          incr itemcount
          incr factcount [llength $cMotionFacts($t,$subj)]
        }
      }
      cMotion_putadmin "Total: $factcount facts about $itemcount \"$type\" items"
    } else {
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
    }
    return 0
  }
  # status
  if [regexp -nocase {status} $arg] {
    set items [lsort [array names cMotionFacts]]
    set itemcount 0
    set factcount 0
    foreach item $items {
      lassign [split $item ","] type subj
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
  if [regexp -nocase {forget ([^ ]+) ([^ ]+) ([^ ]+)} $arg matches type item fact] {
    if [info exists cMotionFacts($type,$item)] {
      if [string is double -strict $fact] {
        cMotion_putadmin "Deleting fact $fact about $item ($type)"
        cMotion_fact_forget_fact $type $item $fact
      } else {
        cMotion_putadmin "Fact must be a number"
      }
    } else {
      cMotion_putadmin "No facts found for $item ($type)"
    }
  return 0
  }
  # delete
  if [regexp -nocase {delete ([^ ]+) ([^ ]+)} $arg matches type item] {
    if [info exists cMotionFacts($type,$item)] {
      cMotion_putadmin "Deleting all facts about $item ($type)"
      cMotion_facts_delete_all $type $item
    } else {
      cMotion_putadmin "No facts found for $item ($type)"
    }
    return 0
  }
  #all else fails, list help
  cMotion_plugin_mgmt_fact_help
  return 0
}

proc cMotion_plugin_mgmt_fact_help { } {
  cMotion_putadmin "Manage facts in cMotion:"
  cMotion_putadmin "  .cmotion fact status"
  cMotion_putadmin "    Facts system status"
  cMotion_putadmin "  .cmotion fact show <type> <item>"
  cMotion_putadmin "    Fact details about an item"
  cMotion_putadmin "    Ex: '.cmotion fact show what cMotion'"
  cMotion_putadmin "    Use * for <item> to see all facts about <type>"
  cMotion_putadmin "  .cmotion fact forget <type> <item> <fact>"
  cMotion_putadmin "    delete a specific fact by number from an item"
  cMotion_putadmin "  .cmotion fact delete <type> <item>"
  cMotion_putadmin "    Remove all facts about <item> from mem and DB"
  cMotion_putadmin "  .cmotion fact save"
  cMotion_putadmin "    Manually saves in memory facts to DB"
  cMotion_putadmin "    (normally happens automatically)"
  return 0
}
# register the plugin
cMotion_plugin_add_mgmt "fact" "^fact" n "cMotion_plugin_mgmt_fact" "any" "cMotion_plugin_mgmt_fact_help"
