# cMotion text plugins
# plugins should return 1 if they trigger, and 2 if they trigger without output
# (i.e. return 2 to not increment flood)
# they should return 0 if they don't trigger

# cMotion_plugin_add_text  "name"  "regexp"  %  cMotion_plugin_text_<name>  "lang"
# proc cMotion_plugin_text_<name> { nick host handle channel text } {
#    cMotionDoAction $channel $nick "OUTPUT HERE"
#    return 1
#}

cMotion_plugin_add_text "mmm" "mmm+" 25 cMotion_plugin_text_mmm "en"
cMotion_plugin_add_text "mmmbot" "mmm+ $botnicks" 50 cMotion_plugin_text_mmm "en"
proc cMotion_plugin_text_mmm { nick host handle channel text } {
    cMotionDoAction $channel $nick "%VAR{smiles}"
    return 1
}
cMotion_plugin_add_text "oww" "^(ow+|ouch|ie+)" 50 cMotion_plugin_text_oww "en"
proc cMotion_plugin_text_oww { nick host handle channel text } {
    cMotionDoAction $channel $nick "%VAR{awwws}"
    return 1
}
cMotion_plugin_add_text "url-img" {(http|ftp)://([[:alnum:]]+\.)+[[:alnum:]]{2,3}.+\.(jpg|jpeg|gif|png)} 25 cMotion_plugin_text_url-img "en"
proc cMotion_plugin_text_url-img { nick host handle channel text } {
    cMotionDoAction $channel $nick "%VAR{rarrs}"
    return 1
}
### 
cMotion_plugin_add_text "url-gen" {(http|ftp)://([[:alnum:]]+\.)+[[:alnum:]]{2,3}} 50 cMotion_plugin_text_url-gen "en"
proc cMotion_plugin_text_url-gen { nick host handle channel text } {
    cMotionDoAction $channel $nick "%VAR{bookmarks}"
    return 1
}
cMotion_abstract_register "bookmarks" {
  "%VAR{smiles}"
  "/bookmarks"
  "i have that bookmarked"
  "i saw that on %VAR{socialmedia}"
}
#
cMotion_plugin_add_text "here" "^any ?(one|body) (here|alive|talking)" 40  cMotion_plugin_text_here "en"

proc cMotion_plugin_text_here { nick host handle channel text } {
    cMotionDoAction $channel $nick "%VAR{here_responses}"
    return 1
}
cMotion_abstract_register "here_responses" {
  "%VAR{nos}"
}
#
cMotion_plugin_add_text "wassup" "^wa+((ss+)|(zz+))u+p+(!*)?$" 40 cMotion_plugin_text_wassup "en"
proc cMotion_plugin_text_wassup { nick host handle channel text } {
    cMotionDoAction $channel $nick "%VAR{wassups}"
    return 1
}
cMotion_abstract_register "wassups" {
  "wa%REPEAT{4:12:z}aa%REPEAT{4:8:h}!"
  "wa%REPEAT{4:12:s}aaa!"
  "wha%REPEAT{4:12:z}ahh!"
}
#
cMotion_plugin_add_text "oops" "^(oops|who+ps|whups|doh |d\'oh)" 40 cMotion_plugin_text_oops "en"
proc cMotion_plugin_text_oops { nick host handle channel text } {
    cMotionDoAction $channel $nick "%VAR{ruins}"
    return 1
}
cMotion_abstract_register "ruins" {
  "nice work." 
  "%VAR{unsmiles}" 
  "You broke it!" 
  "Now you've done it." 
  "now what?" 
  "oh thats just great" 
  "good job." 
  "good work." 
  "way to go!"
  "Did you touch it? I told you not to touch it!"
}
#
cMotion_plugin_add_text "lucks" "wish me (good )?luck" 90 cMotion_plugin_text_lucks "en"
proc cMotion_plugin_text_lucks { nick host handle channel text } {
    cMotionDoAction $channel $nick "%VAR{lucks}"
    return 1
}
cMotion_abstract_register "lucks" {
  "Luck!" 
  "good luck!" 
  "bad luck!%|I mean uh, good luck!" 
  "best, %%" 
  "who needs luck? You got *skillz*, %%" 
  "/crosses fingers for %%" 
}
#
cMotion_plugin_add_text "only4" {^only [0-9]+} 80 cMotion_plugin_text_only4 "en"
proc cMotion_plugin_text_only4 { nick host handle channel text } {
    cMotionDoAction $channel $nick "%VAR{only4}"
    return 1
}
cMotion_abstract_register "only4" {
  "are you sure it wasn't %NUMBER{100}?" 
  "that's a lot, really" 
  "that's not very many" 
  "only?"
}
#
cMotion_plugin_add_text "dude" "^dude$" 40 cMotion_plugin_text_dudesweet "en"
cMotion_plugin_add_text "sweet" "^sweet$" 40 cMotion_plugin_text_dudesweet "en"
cMotion_plugin_add_text "totally" "^totally$" 40 cMotion_plugin_text_dudesweet "en"
proc cMotion_plugin_text_dudesweet { nick host handle channel text } {
    cMotionDoAction $channel $nick "%VAR{dudesweet}"
    return 1
}
cMotion_abstract_register "dudesweet" {
  "Dude!"
  "Dewd"
  "Dude sweet"
  "Sweet dude"
  "D%REPEAT{3:8:u}de!"
  "Sweet!"
  "Schweet!"
  "Sw%REPEAT{3:8:e}t!"
  "Totally sweet"
  "Totally dude"
  "Totally sweet dude"
  "Dude totally"
}
#
cMotion_plugin_add_text "woot" {^[a-zA-Z0-9]+[!1~]+$} 5 cMotion_plugin_text_woot "en"
proc cMotion_plugin_text_woot { nick host handle channel text } {
  if [regexp {^([a-zA-Z0-9]+)[!1~]+$} $text matches word] {
    cMotionDoAction $channel $word "%VAR{woots}"
    return 1
  }
}
cMotion_abstract_register "woots" {
  "i like %%"
  "\\o/"
  "%REPEAT{3:7} %%"
  "\\o/ %%"
  "hurrah"
  "wh%REPEAT{3:7:e} %%"
  "%VAR{smiles}"
}
#
cMotion_plugin_add_text "thatsright" "%botnicks: (i see|ri+ght|ok|all? ?right|whatever)" 60 cMotion_plugin_text_thatsright "en"
proc cMotion_plugin_text_thatsright { nick host handle channel text } {
    cMotionDoAction $channel $nick "%VAR{thatsright}"
    return 1
}
cMotion_abstract_register "thatsright" {
  "really, it's true %VAR{unsmiles}" 
  "it's true%colen" 
  "I wouldn't lie to you, %%" 
  "why you don't believe me?"
  "%VAR{unsmiles}"
}
#
cMotion_plugin_add_text "no-mirc" "mirc" 40 cMotion_plugin_text_no-mirc "en"
proc cMotion_plugin_text_no-mirc { nick host handle channel text } {
    cMotionDoAction $channel $nick "%VAR{nomirc}" 
    return 1
}
cMotion_abstract_register "nomirc" {
  "irssi > mIRC" 
  "<3 irssi" 
  "mmm irssi" 
  "irssi > *"
}
#
cMotion_plugin_add_text "wb" "^(re|wb|welcome back) %botnicks" 85 cMotion_plugin_text_wb "en"

proc cMotion_plugin_text_wb { nick host handle channel text } {
  cMotionDoAction $channel "" "re"
  driftFriendship $nick 1
  return 1
}
#
cMotion_plugin_add_text "nn" "(nn|gn|nite|night|nite ?nite),? (%botnicks|all)$" 100 cMotion_plugin_text_nn en
proc cMotion_plugin_text_nn { nick host handle channel text } {
  cMotionDoAction $channel $nick "%VAR{nn}"
  return 1
}
cMotion_abstract_register "nn" {
  "nn %VAR{unsmiles}" 
  "nn"  
  "nite" 
  "night" 
  "nn %%" 
  "sleep well" 
  "sweet dreams"
}
