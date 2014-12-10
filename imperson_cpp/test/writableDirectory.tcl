set url "http://localhost:61001/writableDirectory?impDirectory=/data/blctl/impTest/dir1/dir2/dir3&impUser=blctl&impSessionID=5109983B335508928FE6B964FED8500D"

set token [httpsmb::geturl $url -timeout 8000]
checkHttpStatus $token

puts "data: [httpsmb::data $token]"
httpsmb::cleanup $token

