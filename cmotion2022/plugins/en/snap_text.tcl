## cMotion plugin: snap

cMotion_plugin_add_text "snap" "." 100 cMotion_plugin_text_snap "en"

proc cMotion_plugin_text_snap { nick host handle channel text } {
    if {[string length $text] < 5} {
        return 0
    }

    set ctime [clock seconds]
    
    if {
        ($text == [cMotion_plugins_settings_get "text:snap" $channel "" "text"]) &&
        ($nick != [cMotion_plugins_settings_get "text:snap" $channel "" "nick"]) &&
        ($ctime - [cMotion_plugins_settings_get "text:snap" $channel "" "time"] < 600)
    } {
        if {[rand 2]} {
            set othernick [cMotion_plugins_settings_get "text:snap" $channel "" "nick"]
            cMotionDoAction $channel $nick "%VAR{snaps}" $othernick
            cMotion_plugins_settings_set "text:snap" $channel "" "text" ""
            cMotion_plugins_settings_set "text:snap" $channel "" "nick" ""
            cMotion_plugins_settings_set "text:snap" $channel "" "time" 0
            return 1
        }
    }
    cMotion_plugins_settings_set "text:snap" $channel "" "text" $text
    cMotion_plugins_settings_set "text:snap" $channel "" "nick" $nick
    cMotion_plugins_settings_set "text:snap" $channel "" "time" $ctime
    return 0
}

cMotion_abstract_register "snaps" { "/joins in" "me too!" "/joins %% and %2" "/hands %ruser a bong too" ".imin !" }
