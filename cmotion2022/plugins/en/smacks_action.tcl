## cMotion plugin: smacks

cMotion_plugin_add_action "smacks" "^(kicks|smacks|twats|injures|beats up|punches|hits|thwaps|slaps|pokes|kills|destroys) %botnicks" 100 cMotion_plugin_action_smacks "en"

proc cMotion_plugin_action_smacks { nick host handle channel text } {
  global botnicks
  if [regexp -nocase "(kicks|smacks|injures|beats up|punches|hits|thwaps|slaps|pokes|kills|destroys) ${botnicks}\\M" $text] {
  	if [regexp -nocase "slaps $botnicks around( a bit)? with a( large)? trout" $text] {
  		cMotionDoAction $channel $nick "%VAR{trouts}"
  		return 1
  	}
    cMotionGetSad
    cMotionGetUnLonely
    driftFriendship $nick -2
    cMotionDoAction $channel $nick "%VAR{slapped}"
    return 1
  }
}
cMotion_abstract_register "trouts"
cMotion_abstract_batchadd "trouts" {
	"/slaps %% back using a default menu command"
	"omg n00b"
	"omg so old"
	"mIrc sucks"
}
cMotion_abstract_register "slapped"
cMotion_abstract_batchadd "slapped" {
	"ow hey! that was my %VAR{bodypart} %VAR{unsmiles}"
	"/%VAR{smacks} %% back with %VAR{sillyThings}"
	"%VAR{frightens}"
	"%VAR{blownAways}"
	"hey! I am going to tell %ruser on you!"
}
cMotion_abstract_register "smacks"
cMotion_abstract_batchadd "smacks" { "smacks" "cuff" "hits" "pats" "slaps" "socks" "spanks" "chops" "clouts" "punches" "annihilates" "annuls" "axes" "butchers" "crushes" "damages" "defaces" "eradicates" "erases" "exterminates" "extinguishes" "gust" "impairs" "kills" "lays waste" "levels" "liquidates" "maims" "mutilates" "nukes" "nullifies" "quashes" "quells" "ravages" "ravishes" "razes" "ruins" "sabotages" "shatters" "slays" "smashes" "snuffs out" "stamps out" "suppresses" "torpedoes" "trashes" "wastes" "wipes out" "wrecks" "zaps" }