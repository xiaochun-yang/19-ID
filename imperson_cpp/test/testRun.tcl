package require http

set iiii 0

proc myCB { s token } {
    upvar #0 $token state

    global iiii

    puts "iiii=$iiii"

    set data [gets $s]
    puts "===>{$data}"

    set n [string length $data]

    incr iiii
    if {$iiii == 10} {
        ####end
        #set state(status) ok
        puts $s "END"
    } elseif {$iiii < 10} {
        puts $s "word_$iiii"
    }
    flush $s

    return $n
}

proc checkHttpStatus { token } {
    set status [http::status $token]
    #puts "checkHttpStatus: status = $status"
    if {$status != "ok"} {
        puts "Web Server call returned: $status"
        puts "data: [http::data $token]"
        http::cleanup $token
        return -code error "web server call: $status"
    }
    #puts "checkHttpStatus: code = [http::code $token]"
    set ncode [http::ncode $token]
    if {![string is digit $ncode] || $ncode >= 400} {
        puts "data: [http::data $token]"
        set code [http::code $token]
        http::cleanup $token
        return -code error $code
    }
}

set url "http://localhost:61002//runExecutable?impExecutable=/home/blctl/a.out&impUser=blctl&impSessionID=D4C7E8E48D51422F8986DAE8821EF6A9&impKeepStdin=true"

set token [http::geturl $url \
-type application/octet-stream \
-timeout 8000 \
-query "1234567890\n" \
-handler myCB \
]
checkHttpStatus $token

puts "data: [http::data $token]"
http::cleanup $token

