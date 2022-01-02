# cMotion: admin plugin file for language mangement

proc cMotion_plugin_mgmt_language { handle { arg "" }} {
  global cMotionSettings
  if [regexp -nocase {remove (.+)} $arg matches lang] {
    if { $lang == $cMotionSettings(deflang) } {
      cMotion_putadmin "Cannot remove current language"
      return 0
    }
    cMotion_putadmin "Removing language $lang..."
    set langs [split $cMotionSettings(languages) ","]
    set newlangs [list]
    foreach language $langs {
      if {$lang != $language} {
        lappend newlangs $language
      }
    }
    if {[llength $newlangs] == 0} {
      set newlangs [list "en"]
    }
    set newlangstring [join $newlangs ","]
    set cMotionSettings(languages) $newlangstring
    cMotion_putadmin "cMotion: new languages are $newlangstring ... rehash to load"
    return 0
  }
  if [regexp -nocase {add (.+)} $arg matches lang] {
    set langs [split $cMotionSettings(languages) ","]
    foreach language $langs {
      if {$lang == $language} {
        cMotion_putadmin "Cannot add language already in list"
	return 0
      }
    }
    cMotion_putadmin "Adding language $lang..."
    append cMotionSettings(languages) ",$lang"
    cMotion_putadmin "cMotion: new languages are $cMotionSettings(languages) ... rehash to load"
    return 0
  }
  if [regexp -nocase {use (.+)} $arg matches lang] {
    cMotion_putadmin "Switching languages to $lang..."
    if [regexp $lang $cMotionSettings(languages)] {
      # step 1: flush the abstracts
      cMotion_abstract_flush
      # step 2: change the language in info
      set cMotionSettings(deflang) $lang
      # step 3: load the new abstracts
      cMotion_abstract_revive_language
    } else {
      cMotion_putadmin "Error! Language $lang not loaded"
    }
    return 0
  }
  #else list langs
  set langs "cMotion loaded languages: "
  foreach lang $cMotionSettings(languages) {
    append langs "$lang  "
  }
  cMotion_putadmin "$langs"
  cMotion_putadmin "Current language is $cMotionSettings(deflang)"
}
# register the plugin
cMotion_plugin_add_mgmt "lang" "^lang(uage)?" n "cMotion_plugin_mgmt_language" "any" "cMotion_plugin_mgmt_language_help"

proc cMotion_plugin_mgmt_language_help { } {
  			cMotion_putadmin "Switch languages:"
  			cMotion_putadmin "  .cMotion lang"
  			cMotion_putadmin "    show available and current language"
  			cMotion_putadmin "  .cMotion lang add <lang>"
  			cMotion_putadmin "    add a language"
  			cMotion_putadmin "  .cMotion lang remove <lang>"
  			cMotion_putadmin "    unload a language"
  			cMotion_putadmin "  .cMotion lang use <lang>"
  			cMotion_putadmin "    switch active language"
		return 0
}