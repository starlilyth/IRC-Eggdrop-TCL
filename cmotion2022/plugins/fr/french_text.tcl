# cMotion French example

cMotion_plugin_add_text "bof" "^bof$" 30 cMotion_plugin_text_bof "fr"
cMotion_plugin_add_text "alors" "^alors$" 30 cMotion_plugin_text_alors "fr"
cMotion_plugin_add_text "bonjour" "bonjour" 60 cMotion_plugin_text_bonjour "fr"
proc cMotion_plugin_text_bof { nick host handle channel text } {
    cMotionDoAction $channel "" "%VAR{FRENCH}"
    return 1
}
proc cMotion_plugin_text_alors { nick host handle channel text } {
    cMotionDoAction $channel "" "%VAR{FRENCH}"
    return 1
}
proc cMotion_plugin_text_bonjour { nick host handle channel text } {
    cMotionDoAction $channel "" "%VAR{FRENCH}"
    return 1
}
cMotion_abstract_register "FRENCH"
cMotion_abstract_register "french1"
cMotion_abstract_register "french2"
cMotion_abstract_register "french3"
cMotion_abstract_batchadd "FRENCH" { "%VAR{french1} %VAR{french2} %VAR{french3}" ]
cMotion_abstract_batchadd "french1" { "est-ce que je peux" "je prend" "je vais au" "ou sont les toilettes" "on m'a" "je vais manger" "bonjour" }
cMotion_abstract_batchadd "french2" { "ouvir la fenetre" "une douche" "manger" "baiser-vous plus vite" "un velo" "une lesbienne" }
cMotion_abstract_batchadd "french3" { "a dix heures" "dans la salle de bains" "sur la bus 264" "dans la collection noir" "une vie sexuelle" "ma tete" "ma fesse" "les chapeaux" }
