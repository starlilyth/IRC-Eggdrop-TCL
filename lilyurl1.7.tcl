# URL 2 IRC by Lily (https://github.com/starlilyth)
# Scans links in IRC channels and returns titles and tinyurl, and logs to a webpage. 
# Will tag weblog entries NSFW if that appears in the line with the link.
# Has duplicate link detection - displays newest entry only, with link count and poster list.
# For Eggdrop bots. Has been tested on eggdrop 1.9.1.
# Requires TCL8.4 or greater with http, htmlparse and tls, and the sqlite3 tcl lib. (not mysql!) 
# For deb/ubuntu, the packages needed are tcllib and libsqlite3-tcl. Adjust for your flavor. 

# You must ".chanset #channel +url2irc" for each chan you wish to use this in. 

# This needs to be set to a bot writable dir for the web log pages. 
set url2irc(path) /var/www/html/urllog      ;# path to bot writable dir for web log pages

# YouTube link ignore. Set true to not display YouTube links (still writes to log)
set url2irc(ytignore) true

# Optional space separated list of domains/URLs/keywords to ignore. Entries are * expanded both ways, you have been warned.
set url2irc(iglist) "rotten.com lemonparty.org decentsite.tld/somepath/terriblepicture.jpg"

# You may want to change these, but they are set pretty well. 
set url2irc(maxdays) 7           ;# maximum number of days to save on log page
set url2irc(tlength) 90	         ;# minimum url length for tinyurl (tinyurl is 18 chars..)
set url2irc(pubmflags) "-|-" 	   ;# user flags required for use
# Fine tuning, safe to ignore. 
set url2irc(ignore) "bdkqr|dkqr" ;# user flags script will ignore 
set url2irc(length) 12	 		     ;# minimum url length for title (12 chars is the shortest url possible, equalling all)
set url2irc(clength) 90			     ;# log page url display length
set url2irc(delay) 2 			       ;# minimum seconds between use
set url2irc(timeout) 90000 		   ;# geturl timeout
set url2irc(maxsize) 1048576     ;# max page size in bytes

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
# 15 - logger index.html 20110311 
# 16 - cleanups, 1.0 version for egghelp. 
# 1.2 - fixed shortlink redirects, dbfile varname change, 20120821
# 1.3 - integrated google search. 20120821
# 1.4 - fixed google search 20131217
# 1.5 - fixed redir/reloc. YouTube ignore flag. added output colors for some urls. 20150825
#     - Removed google search; they wont support anything that does not show ads.
# 1.6 - updated user agent string. 20211221
# 1.7 - updated user agent, added error handling, html charset header, comments.
#     - fixed: TLS, redirection, metadata case, title regexp, tinyurl, yt ignore. 20230323
#     - TLS solution found at: http://forum.egghelp.org/viewtopic.php?t=20503
# TODO: sticky/hide, urlsearch?

################################################

package require http
package require htmlparse
package require tls
package require sqlite3
set url2irc(last) 111
set url2irc(agent) "Mozilla/5.0 (Macintosh; Intel Mac OS X 13_1) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"
set udbfile "./urllog.db"
setudef flag url2irc
bind pubm $url2irc(pubmflags) {*://*} pub_url2irc

proc pub_url2irc {nick host user chan text} {
global url2irc
global udbfile
global botnick
set url2irc(redirects) 0
  if {([channel get $chan url2irc]) && ([expr [unixtime] - $url2irc(delay)] > $url2irc(last)) && (![matchattr $user $url2irc(ignore)])} {
    regsub "#" $chan "" cname
    # set NSFW flag
    if {[string match -nocase "*nsfw*" $text]} { set lflag  NSFW } else { set lflag {} }
    foreach word [split $text] {
      # get URL
      if {[string length $word] >= $url2irc(length) && [regexp {^(f|ht)tp(s|)://} $word] && ![regexp {://([^/:]*:([^/]*@|\d+(/|$))|.*/\.)} $word]} {
        # check for ingored
        foreach item $url2irc(iglist) {
          if {[string match "*$item*" $word]} {return 0}
        }
        set url2irc(last) [unixtime]
        # tinyurl
        if {[string length $word] >= $url2irc(tlength)} {
          set newurl [tinyurl $word]
        } else { set newurl "" }
        # get the title
        set urtitle [urltitle $word]
        set lTime [clock seconds]
        # add database entry
        sqlite3 ldb $udbfile
          ldb eval {CREATE TABLE IF NOT EXISTS urllog (lTime INTEGER,lchan TEXT,lnick TEXT,lurl TEXT,ltitle TEXT,lflag TEXT)}
          ldb eval {INSERT INTO urllog (lTime, lchan, lnick, lurl, ltitle, lflag)VALUES($lTime,$cname,$nick,$word,$urtitle,$lflag)}
        ldb close
        # output formatting
        if {[regexp -nocase {(youtube|youtu.be)} $word] && $url2irc(ytignore) eq true} {break}
        regsub -all "YouTube" $urtitle "\00301,00You\00300,04Tube\003" urtitle
        regsub -all "Google" $urtitle "\00302G\00304o\00308o\00302g\00303l\00304e\003" urtitle
        regsub -all "Imgur" $urtitle "\00309,01Imgur\003" urtitle
        if {[regexp {i.imgur} $word]} { 
          regsub {.*} $urtitle "\00309,01Imgur: $urtitle\003" urtitle
        }
        if {[regexp {twitter} $word]} {
          regsub {.*} $urtitle "\00311,01Twitter: $urtitle\003" urtitle
        }
        # channel output
        if {[string length $newurl]} {
          puthelp "PRIVMSG $chan :\002$urtitle\002 ( $newurl ), linked by $nick"
        } else { puthelp "PRIVMSG $chan :\002$urtitle\002, linked by $nick" }
      }
    }
    # web page output
    if {[file isdirectory $url2irc(path)] && [file writable $url2irc(path)]} {
      sqlite3 ldb $udbfile
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
      putlog  "Web log path not valid! Not writing html files."
    }
  }
}

proc tls:socket args {
   set opts [lrange $args 0 end-2]
   set host [lindex $args end-1]
   set port [lindex $args end]
   ::tls::socket -servername $host {*}$opts $host $port
}

proc urltitle {url} {
global url2irc
  set agent $url2irc(agent)
  if {[info exists url] && [string length $url]} {
    # get metadata
    ::http::register https 443 tls:socket
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
    if {[info exists meta(Location)]} {
      set meta(location) $meta(Location)
    }
    while {[info exists meta(location)] && [incr url2irc(redirects)] < 10} {
      set location $meta(location)
      # location can be relative, get domain if missing
      if {![string match -nocase "https://*" $location]} {
        regexp {(https://.*?/).*?} $url match host
        set location $host$location
      }
      set startloc $location
      # get new location
      ::http::register https 443 tls:socket
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
      # putlog "RELOC: $url2irc(redirects) : $location"
    }

    # process content type and length
    if {[info exists meta(Content-Type)]} {
      set meta(content-type) $meta(Content-Type)
    }
    if {[info exists meta(content-type)]} {
      set content_type [lindex [split $meta(content-type) ";"] 0]
    } else {
      set content_type "Unknown"
    }
    if {[info exists meta(Content-Length)]} {
      set meta(content-length) $meta(Content-Length)
    }
    if {[info exists meta(content-length)]} {
      set content_length $meta(content-length)
    } else {
      set content_length 0
    }
    # get page data
    if {$content_length <= $url2irc(maxsize) && [string match -nocase "text/*" $content_type]} {
      ::http::register https 443 tls:socket
      set http [::http::config -useragent $agent]
      if {[catch {::http::geturl $url -timeout $url2irc(timeout)} http]} {
        set status [::http::status $http]
        return $status
      }
      set data [split [::http::data $http] \n] ; ::http::cleanup $http
    }

    # parse title from data
    set title ""
    if {[info exists data] && [regexp -nocase {<title.*?>(.*?)</title>} $data match title]} {
      set title [::htmlparse::mapEscapes $title]
      regsub -all {[\{\}\\]} $title "" title
      regsub -all " +" $title " " title
      set title [string trim $title]
      return $title
    } else {
      if {[info exists data]} {
        putlog "URL2IRC: $url title data not matched"
      }
      return "$content_type"
    }
  } else {
    return "URL ERROR"
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

putlog "URL 2 IRC v1.7 script loaded.."
