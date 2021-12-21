# Decision script for Eggdrop bots
# USAGE: "BOTNICK, this or that"

# 05 Remove reverse for TCL < 8.5
# TODO
# $name in choicex regsub somehow
# more than two choices (detect comma or 'or' seperated)
# bias keyword list?
# alternate answer list? boths, yes/noss
# substitution list? anything>something, you>I, is my>your * is (is my bong dead or..), I am > you are, does/do

#####
bind pubm -|- {* or *} decide_forme
proc decide_forme {nick uhost hand chan text} {
  global botnick
  set firstword [lindex $text 0]
  if {[regexp -nocase "$botnick\[\[:punct:\]\]" $firstword]} {
    regsub -nocase "$botnick\[\[:punct:\]\]" $text BOTNAME text
    regexp {^BOTNAME (.*?) or (.*?)$} $text - choice1 choice2
    if {[regexp -nocase {^(should|can|will|do|are) (you) } $choice1]} { 
      putserv "PRIVMSG $chan :Im just a bot"
    } 
    regsub {[[:punct:]]$} $choice1 "" choice1
    regsub {[[:punct:]]$} $choice2 "" choice2
    if {[regexp -nocase {^(should|can|will|do|are) (I|they|it) } $choice2]} { 
      regsub -nocase " I " $choice2 " you " choice2
      set choice2 "[lreverse [lrange "$choice2" 0 1]] [lrange "$choice2" 2 end]"
    } elseif {[regexp -nocase {^(should|can|will|do|are) (I|they|it) } $choice1]} { 
      regsub -nocase " I " $choice1 " you " prefix
      set prefix "[lreverse [lrange "$prefix" 0 1]]"
      set choice2 "$prefix $choice2"
    }
    if {[regexp -nocase {^(should|can|will|do|are) (I|they|it) } $choice1]} { 
      regsub -nocase " I " $choice1 " you " choice1
      set choice1 "[lreverse [lrange "$choice1" 0 1]] [lrange "$choice1" 2 end]"
    }
  #    putserv "PRIVMSG $chan :$choice1 or $choice2, hmm.."
    lappend answers $choice1 $choice2 
    if {![regexp {[[:print:]]} $answers]} { return 0 }
    set answer [lindex $answers [expr {int(rand()*[llength $answers])}]]
    putserv "PRIVMSG $chan :$nick, $answer."
  }
}
putlog "lilydecide05 script loaded.."
