## cMotion plugin: now playing 

cMotion_plugin_add_text "now_playing" "^(listening to|now playing|np:|grooves to)" 60 cMotion_plugin_text_now_playing "en"

proc cMotion_plugin_text_now_playing { nick host handle channel text } {
  if {[getFriendshipHandle $user] > 50} {
    cMotionDoAction $channel $nick "%VAR{nowPlaying}"
  } else {
    cMotionDoAction $channel $nick "%VAR{nowPlayingDislike}"
  }
  return 1
}

cMotion_abstract_register "nowPlaying"
cMotion_abstract_batchadd "nowPlaying" {
  "oh, I like that song"
  "[NP: %VAR{randomSongArtist} - %VAR{randomSongName}]"
  "/eyes %%"
  "%REPEAT{3:7:m}"
  "rock on!"
}

cMotion_abstract_register "nowPlayingDislike"
cMotion_abstract_batchadd "nowPlayingDislike" {
  "/plugs %hisher ears"
  "ugh"
  "how can you stand that stuff?"
  "who cares?"
  "SILENCE%colen"
}

cMotion_abstract_register "randomSongArtist"
cMotion_abstract_batchadd "randomSongArtist" {
  "Britney Spears"
  "U2"
  "Oasis"
  "Coldplay"
  "Megadeth"
  "U2"
  "Infected Mushroom"
  "The Cure"
  "Spice Girls"
  "Aphex Twin"
  "Justin Bieber"
  "The Rolling Stones"
  "Capitol City Jazz Ensemble"
  "Napalm Death"
  "Neil Diamond"
  "Brian Eno"
  "Wu-Tang Clan"
  "DJ %VAR{sillyThings}{strip}"
  "%ruser"
  "Unknown Artist"
  "Various Artists"
}

cMotion_abstract_register "randomSongName"
cMotion_abstract_batchadd "randomSongName" {
  "music for %PLURAL{%VAR{sillyThings}{strip}}"
  "%PLURAL{%VAR{sillyThings}{strip}} of desire"
  "ode to %VAR{sillyThings}"
  "that song about %VAR{sillyThings}"
  "fade to %VAR{basic_color}"
  "the sound of one hand clapping"
  "%VAR{sound} %VAR{sound} %VAR{sound}"
  "ode to %ruser"
  "shake your %VAR{bodypart}"
  "Untitled Track %NUMBER{20}"
}
