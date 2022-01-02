# cMotion plugin: stoner 
# "random" plugin responds to "random or uh, forgot, dunno
# general stoner moments. will respond with random stoner moment statement
cMotion_plugin_add_text "stonerrandom" "random|((i )forg(e|o)t)|((mwa)?ha(ha)+)|uh(m+)(h+)|(I )(dun(no|o))" 30 cMotion_plugin_text_stoner_moment "en"
proc cMotion_plugin_text_stoner_moment { nick host handle channel text } {
	cMotionDoAction $channel "" "%VAR{randomStoner}"
	return 1
}

# "munchie" plugin responds to "munchie" and variations of "munchie"
cMotion_plugin_add_text "stonermunchie" "munchie|munch+(ee|y)(ies|ed)" 25 cMotion_plugin_text_stoner_munchie "en"
proc cMotion_plugin_text_stoner_munchie { nick host handle channel text } {
	cMotionDoAction $channel "" "%VAR{randomMunchie}"
	return 1
}


# random "munchie" responses... 
cMotion_abstract_register "randomMunchie" {
	"munchie %VAR{smiles}"
	"munchie munchie mmmuuuunnnchiiieee munchie"
	"i like munchies"
	"ooooooooooOOOOOooooo munchie"
	"yaaaaaaay! munchies"
	"mmmmmm Im so hungry!"
	"I like pop tarts!"
	"you said munchie %VAR{smiles}"
}

# random stoner phrases
cMotion_abstract_register "randomStoner" {
    "must be time to smoke more"
    "dont look at me!"
    "I dont know either"
    "did I miss something?"
	"did you start a bowl without me?"
	"oh yeah, thats right."
	"have you seen my pants?"
	"wheres the lighter?"
	"WICKED%colen"
	"have you the green bud?"
	"and then we laughed.. I guess you had to be there."
	"you've been testing your bong, havent you"
	"so... much... fun!"
	"I uh.. think maybe... I mighta forgot."
	"aaah, the stink of green"
	"i'm not giving up... i'll outsmoke you all%colen"
	"woah, wait. hold on just a minute..."
	"this is not cool"
	"TASTE THE RAINBOW%colen"
	"i have a plan... an amazing plan"
	"i will call you... stoner"
	"behold the bong of wonder"
	"HEY! pass that over here!"
	"yes, yes."
	"yes... wait a minute... no."
	"thank you.. i love you"
	"i had no idea"
	"you're on fire"
	"and then, we went home. the end."
	"does your mom know where you are?"
	"not funny."
	"WHERES MY TOAST?"
	"FAIL!"
	"failboats!"
	"%VAR{sound}"
}
