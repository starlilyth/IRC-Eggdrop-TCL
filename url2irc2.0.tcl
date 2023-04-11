# URL 2 IRC by Lily (https://github.com/starlilyth)
# Scans links in IRC channels and returns titles and tinyurl, and logs to a webpage. 
# Will tag weblog entries NSFW if that appears in the line with the link.
# Has duplicate link detection - displays newest entry only, with link count and poster list.
# For Eggdrop bots. Has been tested on eggdrop 1.9.1.
# You must ".chanset #channel +url2irc" for each chan you wish to use this in.
# Requires TCL8.4 or greater with tcllib, tcltls, and the sqlite3 tcl library. (not mysql!)
# For deb/ubuntu, the packages needed are tcllib and libsqlite3-tcl. Adjust for your flavor. 
#
# YouTube search is an optional component. Enable it by adding a Google/YouTube API key
# Get your key here: https://developers.google.com/youtube/v3/getting-started

# This needs to be set to a bot writable directory for the web log pages.
set url2irc(path) /var/www/html/urllog

# Google/YouTube API key. Put your key in quotes to enable !yt searching and extended YouTube info
#set url2irc(apikey) ""
set url2irc(apikey) "AIzaSyC6UyHZcKppXxNn9aPUc-pQhikDAqcKTfo"

# Use ASCII colors?
set url2irc(color) true

# Show runtime: "(11s ago)".
set url2irc(runtime) true

# Optional space separated list of domains/URLs/keywords to ignore. Entries are * expanded both ways, you have been warned.
set url2irc(iglist) "rotten.com lemonparty.org terriblepicture.jpg"

# You may want to change these, but they are set pretty well. 
set url2irc(maxdays) 7           ;# maximum number of days to save on log page
set url2irc(tlength) 90	         ;# minimum url length for tinyurl (tinyurl is 18 chars..)
set url2irc(pubmflags) "-|-" 	   ;# user flags required for use

# Fine tuning, safe to ignore. 
set url2irc(ignore) "bkq|kq"     ;# user flags script will ignore
set url2irc(length) 12	 		     ;# minimum url length for title (12 chars is the shortest url possible, equalling all)
set url2irc(clength) 90			     ;# log page url display length
set url2irc(delay) 2 			       ;# minimum seconds between use
set url2irc(timeout) 90000 		   ;# geturl timeout
set url2irc(maxsize) 1500000     ;# max page size in bytes
set url2irc(debug) false         ;# show error handling

# 01 - Basic features set 20090521 
# 02 - Build logger web page function and title regexp cleanup 20101130
# 05 - Fix logger for multiple chans, user agent string, web dir check 20101204
# 07 - s/regexp/htmlparse/, truncate long url display on log page 20101212
# 09 - some ::http cleanup volunteered by Steve (thanks!) 20110220: Check Content-Type; only get title for text pages 
#    - under maxsize, otherwise display mime-type. Follow http redirect (not meta refresh or javascript).
# 10 - converted to sqlite3, main loop cleanup 20110305
# 11 - secure URL handler, NSFW tagger 20110308
# 12 - site blacklist, comment cleanup, chanflag removal (just one now) 20110309
# 14 - post counts, day dividers, dupe detection - display newest w/ counter and poster list, carryover NSFW flag. 20110310
# 1.2 - fixed shortlink redirects, dbfile varname change, 20120821
# 1.3 - integrated google search. 20120821
# 1.5 - fixed redir/reloc. YouTube ignore flag. added output colors for some urls. 20150825
#     - Removed google search; they wont support anything that does not show ads.
# 1.7 - updated user agent, added html charset, error handling, comments.
#     - fixed: TLS, redirection, metadata case, title regexp, tinyurl, yt ignore. 20230323
#     - TLS solution found at: http://forum.egghelp.org/viewtopic.php?t=20503
# 1.8 - JS only sites output, color flag, runtime output, code optimization, error handling. 20230328
# 2.0 - file name change, integrated youtube details and search function - 20230410

# No edits below here unless you will submit a patch.
################################################

package require http
package require htmlparse
package require json
package require tls
package require sqlite3
set url2irc(udbfile) "./urllog.db"
set url2irc(agent) "Mozilla/5.0 (Macintosh; Intel Mac OS X 13_1) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"
set url2irc(last) 111
setudef flag url2irc

bind pubm $url2irc(pubmflags) {*://*} pub_url2irc
proc pub_url2irc {nick host user chan text} {
  global url2irc
  if {([channel get $chan url2irc]) && ([expr [unixtime] - $url2irc(delay)] > $url2irc(last)) && (![matchattr $user $url2irc(ignore)])} {
    set url2irc(starttime) [clock seconds]
    # set NSFW flag
    if {[string match -nocase "*nsfw*" $text]} { set lflag  NSFW } else { set lflag {} }
    # get URL
    foreach word [split $text] {
      if {[string length $word] >= $url2irc(length) && [regexp {^http(s|)://} $word] && ![regexp {://([^/:]*:([^/]*@|\d+(/|$))|.*/\.)} $word]} {
        set url2irc(last) [unixtime]

        # check for ignored
        foreach item $url2irc(iglist) {if {[string match "*$item*" $word]} {return 0}}

        # get the title
        if {[regexp -nocase {(youtube|youtu.be)} $word] && ($url2irc(apikey) ne "")} {
          set urltitle [yt_title $word]
        } else {
          set urltitle [get_title $word]
        }

        # add database entry
        set lTime [clock seconds]
        regsub "#" $chan "" cname
        sqlite3 ldb $url2irc(udbfile)
          ldb eval {CREATE TABLE IF NOT EXISTS urllog (lTime INTEGER,lchan TEXT,lnick TEXT,lurl TEXT,ltitle TEXT,lflag TEXT)}
          ldb eval {INSERT INTO urllog (lTime, lchan, lnick, lurl, ltitle, lflag)VALUES($lTime,$cname,$nick,$word,$urltitle,$lflag)}
        ldb close

        # tinyurl
        if {[string length $word] >= $url2irc(tlength)} {
          set shorturl [tinyurl $word]
        } else { set shorturl "" }

        # channel output
        set verbs "linked by"
        chanout $nick $chan $urltitle $shorturl $verbs

        # web page update
        htmlout $chan

      }
    }
  }
}

bind pub $url2irc(pubmflags) !yt yt_search
proc yt_search {nick host user chan text} {
  global url2irc
  if {$url2irc(apikey) ne ""} {
    if {([channel get $chan url2irc]) && ([expr [unixtime] - $url2irc(delay)] > $url2irc(last)) && (![matchattr $user $url2irc(ignore)])} {
      set url2irc(starttime) [clock seconds]
      set url2irc(last) [unixtime]

      #set url
      regsub -all {\s+} $text "%20" urltext
      set url "https://www.googleapis.com/youtube/v3/search?part=snippet&fields=items(id(videoId),id(channelId),snippet(title))&key=$url2irc(apikey)&q=$urltext&maxResults=1"

      # get data
      ::http::register https 443 tls_socket
      set http [::http::config -useragent $url2irc(agent)]
      if {[catch {::http::geturl $url -timeout $url2irc(timeout)} http]} {
        set status [::http::status $http]
        set staterr $http
        putlog "URL2IRC: $status using Google API for $text - $staterr"
        return "$status - could not get data for $text"
      }
      set data [::http::data $http] ; ::http::cleanup $http

      # process data
      if {[info exists data]} {
        # parse json
        set ids [dict get [json::json2dict $data] items]
        set id [lindex $ids 0 1 1]
        set type [lindex $ids 0 1 0]
        if {$type eq "channelId"} {
          # channel
          set shorturl "https://www.youtube.com/channel/$id"
          set urltitle [lindex $ids 0 3 1]
          set urltitle [::htmlparse::mapEscapes $urltitle]
          append urltitle " - YouTube"
        } else {
          # use yt_title function to get full details
          set shorturl "https://youtu.be/$id"
          set urltitle [yt_title $shorturl]
        }

        # add database entry
        set lTime [clock seconds]
        regsub "#" $chan "" cname
        if {[string match -nocase "*nsfw*" $urltitle]} { set lflag  NSFW } else { set lflag {} }
        sqlite3 ldb $url2irc(udbfile)
          ldb eval {CREATE TABLE IF NOT EXISTS urllog (lTime INTEGER,lchan TEXT,lnick TEXT,lurl TEXT,ltitle TEXT,lflag TEXT)}
          ldb eval {INSERT INTO urllog (lTime, lchan, lnick, lurl, ltitle, lflag)VALUES($lTime,$cname,$nick,$shorturl,$urltitle,$lflag)}
        ldb close

        #channel output
        set verbs "found for"
        chanout $nick $chan $urltitle $shorturl $verbs

        # web page update
        htmlout $chan

      } else {
        if {$url2irc(debug) eq true} {
          putlog "URL2IRC: No data returned for $text"
        }
      }
    }
  }
}

proc get_title {url} {
  global url2irc
  set agent $url2irc(agent)
  if {[info exists url] && [string length $url]} {
    # get metadata
    ::http::register https 443 tls_socket
    set http [::http::config -useragent $agent]
    if {[catch {::http::geturl $url -timeout $url2irc(timeout) -validate 1} http]} {
      # timeout will say timeout, not error
      set status [::http::status $http]
      set staterr $http
      putlog "URL2IRC: $status getting metadata for $url - $staterr"
      return "$status - could not get metadata"
    }
    array set meta [::http::meta $http] ; ::http::cleanup $http

    # process redirection
    if {[info exists meta(Location)]} {set meta(location) $meta(Location)}
    set url2irc(redirects) 0
    while {[info exists meta(location)] && [incr url2irc(redirects)] < 10} {
      set location $meta(location)
      # location can be relative, get domain if missing
      if {![string match -nocase "https://*" $location]} {
        regexp {(https://.*?/).*?} $url match host
        set location $host$location
      }
      set startloc $location
      # get new location
      ::http::register https 443 tls_socket
      set http [::http::config -useragent $agent]
      if {[catch {::http::geturl $location -timeout $url2irc(timeout) -validate 1} http]} {
        set status [::http::status $http]
        set staterr $http
        putlog "URL2IRC: $url redirect failed - $staterr"
        return $status
      }
      array set meta [::http::meta $http] ; ::http::cleanup $http
      # process NEW metadata
      if {[info exists meta(Location)]} {
        set meta(location) $meta(Location)
      }
      if {![string match -nocase "https://*" $meta(location)]} {
        regexp {(https://.*?/).*?} $url match host
        set location $host$meta(location)
      }
      # break if we are looping
      if {$startloc eq $location} {
        set url $startloc
        break 
      }
    }

    # process content type and length
    if {[info exists meta(Content-Type)]} {set meta(content-type) $meta(Content-Type)}
    if {[info exists meta(content-type)]} {
      set content_type [lindex [split $meta(content-type) ";"] 0]
    } else {
      set content_type "Unknown"
    }
    if {[info exists meta(Content-Length)]} {set meta(content-length) $meta(Content-Length)}
    if {[info exists meta(content-length)]} {
      set content_length $meta(content-length)
    } else {
      set content_length 0
    }

    # get html page data
    if {$content_length <= $url2irc(maxsize) && [string match -nocase "text/*" $content_type]} {
      ::http::register https 443 tls_socket
      set http [::http::config -useragent $agent]
      if {[catch {::http::geturl $url -timeout $url2irc(timeout)} http]} {
        set status [::http::status $http]
        return $status
      }
      set data [split [::http::data $http] \n] ; ::http::cleanup $http
    }
    # parse title from html data
    if {[info exists data] && [regexp -nocase {<title.*?>(.*?)</title>} $data match title]} {
      set title [::htmlparse::mapEscapes $title]
      regsub -all {[\{\}\\]} $title "" title
      regsub -all " +" $title " " title
      regsub -all "';" $title "'" title
      regsub -all "\";" $title "\"" title
      regsub -all "&;" $title "&" title
      set title [string trim $title]
      # Thanks, Google.
      if {![string match "302 Moved" $title]} {
        return $title
      }
    }

    # some diagnotics if we are still here
    if {$url2irc(debug) eq true} {
      if {$content_length > $url2irc(maxsize) && [string match -nocase "text/*" $content_type]} {
        putlog "URL2IRC: $url exceeded maxsize ($content_length > $url2irc(maxsize)"
      }
      if {[info exists data]} {
        putlog "URL2IRC: $url title data not matched"
      } elseif {![regexp -nocase {(youtube)} $url]} {
        putlog "URL2IRC: $url is type $content_type"
      }
    }

    # Some sites/pages incorrectly require JavaScript or cookie acceptance to render any title.
    # This provides a sitename if no title was returned.
    if {[regexp -nocase {i.imgur} $url]} {return "Imgur \[$content_type\]"}
    if {[regexp -nocase {imgur} $url]} {return "Imgur"}
    if {[regexp -nocase {twitter} $url]} {return "Twitter"}
    if {[regexp -nocase {(youtube|youtu.be)} $url]} {return "YouTube"}
    if {[regexp -nocase {(google|goo.gl)} $url]} {return "Google"}

    # if we still have not returned a title yet
    return "$content_type"

  } else {
    return "URL ERROR"
  }
}

proc yt_title {word} {
  global url2irc
  set url2irc(starttime) [clock seconds]
  set url2irc(last) [unixtime]

  # get id
  regexp -nocase {(?:youtube.com\/watch\?.*v=|youtu.be\/)([\w-]{11})} $word match id
  if {![info exists id]} {
    set urltitle [get_title $word]
    return $urltitle
  }
  set url "https://www.googleapis.com/youtube/v3/videos?id=$id&key=$url2irc(apikey)&part=snippet,statistics,contentDetails&fields=items(snippet(title,channelTitle,publishedAt),statistics(viewCount),contentDetails(duration))"

  # get data
  ::http::register https 443 tls_socket
  set http [::http::config -useragent $url2irc(agent)]
  if {[catch {::http::geturl $url -timeout $url2irc(timeout)} http]} {
    set status [::http::status $http]
    set staterr $http
    putlog "URL2IRC: $status using Google API for $text - $staterr"
    return "$status - could not get data for $text"
  }
  set data [::http::data $http] ; ::http::cleanup $http

  # process data
  if {[info exists data]} {
    # parse json
    set ids [dict get [json::json2dict $data] items]
    # get the title, user, viewcount
    set title [lindex $ids 0 1 3]
    set user [lindex $ids 0 1 5]
    set views [lindex $ids 0 5 1]
    regsub -all {\d(?=(\d{3})+($|\.))} $views {\0,} views
    # published date
    set pubiso [lindex $ids 0 1 1]
    set pubiso [string map {"T" " " ".000Z" "" "Z" ""} $pubiso]
    set pubtime [clock format [clock scan $pubiso] -format {%b %d %Y}]
    # duration
    set isotime [lindex $ids 0 3 1]
    if { [string index $isotime 0] == "0" || $isotime == "P0D" } {
      set isotime "live"
    } else {
      # for m00nie..
      regexp -all {P(?:(\d+)D)?T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?} $isotime match ydays yhours ymins ysecs
      if {$ysecs == ""} {set ysecs "00"} else {set ysecs [format "%02d" $ysecs]}
      if {$ymins == ""} {set ymins "00"}
      if {$yhours == ""} {
        set isotime "$ymins:$ysecs"
      } else {
        set ymins [format "%02d" $ymins]
        set isotime "$yhours:$ymins:$ysecs"
      }
      if {$ydays != ""} {set isotime "${ydays}d $isotime"}
    }
    # output
    return "$title \[$isotime\] (by $user on $pubtime : $views views) - YouTube"
  }
}

proc tinyurl {url} {
  global url2irc
  set agent $url2irc(agent)
  if {[info exists url] && [string length $url]} {
    set http [::http::config -useragent $agent]
    # tinyurl does not work with httpS - in 2023
    set http [::http::geturl "http://tinyurl.com/create.php" -query [::http::formatQuery "url" $url] -timeout $url2irc(timeout)]
    set data [split [::http::data $http] \n] ; ::http::cleanup $http
    for {set index [llength $data]} {$index >= 0} {incr index -1} {
      if {[regexp {href="https://tinyurl\.com/\w+"} [lindex $data $index] url]} {
        return [string map { {href=} "" \" "" } $url]
      }
    }
  }
 return ""
}

proc chanout {nick chan urltitle shorturl verbs} {
  global url2irc
  if {$url2irc(color) eq true} {
    # channel output formatting (colors)
    # Color reference: https://clients.sisrv.net/knowledgebase/137/EggDrop-colors-and-formatting-codes.html
    regsub -all "YouTube" $urltitle "\00301,00You\00300,04Tube\003" urltitle
    regsub -all "Google" $urltitle "\00302,15G\00304o\00308o\00302g\00303l\00304e\003" urltitle
    regsub -all "Facebook" $urltitle "\00302Facebook\003" urltitle
    regsub -all "Imgur" $urltitle "\00309Imgur\003" urltitle
    regsub -all "Twitter" $urltitle "\00311Twitter\003" urltitle
  }
  # channel output
  set runtime ""
  set totaltime [expr [clock seconds] - $url2irc(starttime)]
  if {$url2irc(runtime) eq true} {set runtime "(${totaltime}s ago)"}
  if {[string length $shorturl]} {
    puthelp "PRIVMSG $chan :\002$urltitle\002\017 ( $shorturl ), $verbs $nick $runtime"
  } else {
    puthelp "PRIVMSG $chan :\002$urltitle\002\017, $verbs $nick $runtime"
  }
}

proc htmlout {chan} {
  global url2irc
  global botnick
  if {[file isdirectory $url2irc(path)] && [file writable $url2irc(path)]} {
    regsub "#" $chan "" cname
    sqlite3 ldb $url2irc(udbfile)
    # update database
    set rtime [expr [clock seconds] - ($url2irc(maxdays) * 86400)]
    ldb eval {DELETE FROM urllog WHERE lTime < $rtime}
    set logday 0000
    # write channel page
    set htmlpage [ open "$url2irc(path)/$cname.html" w+ ]
    puts $htmlpage "<!DOCTYPE html><html><head><meta charset=\"utf-8\"><meta http-equiv=\"refresh\" content=\"600\" /><title>URL Log for $chan</title><head>"
    set lcount [ldb eval {SELECT COUNT(distinct lurl) FROM urllog where lchan = $cname}]
    set tdays [expr (([clock seconds] - [ldb eval {SELECT lTime FROM urllog where lchan = $cname order by rowid asc limit 1}]) / 86400) +1]
    puts $htmlpage "<body bgcolor=white><p><h1>URL Log for $chan</h1>$lcount URLs in $tdays days<br><small>This page reloads itself every 5 minutes.<br>Go back to the <a href=\"./index.html\">Index</a></small></p><p>Date - Time - <i>Nick</i> - URL<br><b>Title</b>"
    foreach lrowid [ldb eval {SELECT rowid FROM urllog WHERE lchan = $cname order by rowid desc}] {
      set lrurl [ldb eval {SELECT lurl FROM urllog where rowid = $lrowid }]
      set lrucount [ldb eval {SELECT COUNT(1) FROM urllog where lurl = $lrurl AND lchan = $cname}]
      set lrnick [ldb eval {SELECT DISTINCT lnick FROM urllog where lurl = $lrurl AND lchan = $cname}]
      if {$lrucount > 1 } {
        if {[ldb eval {SELECT rowid from urllog where lurl = $lrurl AND lchan = $cname order by rowid desc limit 1}]!=$lrowid} {
          continue } else {
          regsub -all " " $lrnick "/" lrnick
          set plrnick "linked $lrucount times by $lrnick"
        }
      } else {set plrnick $lrnick}
      set lrtitle [ldb onecolumn {SELECT ltitle FROM urllog where rowid = $lrowid }]
      set lrTime [ldb eval {SELECT lTime FROM urllog where rowid = $lrowid }]
      set tstamp [clock format $lrTime -format {%b. %d - %H:%M}]
      # NSFW tag
      if {[ldb eval {SELECT COUNT(1) FROM urllog where lurl = $lrurl AND lchan = $cname and lflag like '%NSFW%'}]} {
        set lrf " - (marked <font color=\"red\"><b>NSFW</b></font>)"} else {set lrf ""}
      if {[string length $lrurl] >=$url2irc(clength)} {
        set plrurl "[string replace $lrurl $url2irc(clength) end ] ..."
      } else { set plrurl $lrurl }
      if {[clock format $lrTime -format {%m%d}] != $logday} {
        set plogday [clock format $lrTime -format {%A %B %d}]
        puts $htmlpage "<p><center><b>$plogday</b></center></p><hr>"
        set logday [clock format $lrTime -format {%m%d}]
      }
      puts $htmlpage "<p>$tstamp - <i>$plrnick</i> - <a href=\"$lrurl\">$plrurl</a><br><b>$lrtitle</b>$lrf<hr>"
    }
    puts $htmlpage "<center><small><b>URL 2 IRC</b> by Lily (<a href=\"https://github.com/starlilyth\" target=\"_blank\">https://github.com/starlilyth</a>)</small></center></body></html>"
    close $htmlpage
    # write index page
    set indexpage [ open "$url2irc(path)/index.html" w+ ]
    puts $indexpage "<!DOCTYPE html><html><head><meta charset=\"utf-8\"><meta http-equiv=\"refresh\" content=\"600\" /><title>URL Log Index for $botnick</title><head>"
    set ilcount [ldb eval {SELECT COUNT(distinct lurl) FROM urllog}]
    set ichanc [ldb eval {SELECT COUNT(distinct lchan) FROM urllog}]
    puts $indexpage "<body bgcolor=white><p><h1>URL Log Index for $botnick</h1>$ilcount URLs in $ichanc channels<br><small>This page reloads itself every 5 minutes.</small></p><hr>"
    foreach chanid  [ldb eval {SELECT distinct lchan FROM urllog}] {
      set ilcount [ldb eval {SELECT COUNT(distinct lurl) FROM urllog where lchan = $chanid}]
      set ilTime [ldb eval {SELECT lTime from urllog where lchan = $chanid order by rowid desc limit 1}]
      set itstamp [clock format $ilTime -format {%B %d at %H:%M}]
      set iltitle [ldb onecolumn {SELECT ltitle from urllog where lchan = $chanid order by rowid desc limit 1}]
      puts $indexpage "<p><a href=\"./$chanid.html\">\#$chanid</a> - $ilcount URLs - last link posted $itstamp<br>Last link title: <b>$iltitle</b></p><hr>"
    }
    puts $indexpage "<center><small><b>URL 2 IRC</b> by Lily (<a href=\"https://github.com/starlilyth\" target=\"_blank\">https://github.com/starlilyth</a>)</small></center></body></html>"
    close $indexpage
    ldb close
  } else {
    putlog "URL2IRC: Web log path not valid! Not writing html files."
  }
}

proc tls_socket {args} {
   set opts [lrange $args 0 end-2]
   set host [lindex $args end-1]
   set port [lindex $args end]
   ::tls::socket -servername $host {*}$opts $host $port
}

putlog "URL 2 IRC v2.0 script loaded"

