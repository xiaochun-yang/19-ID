proc inlineSnapshot_initialize { } {
}
proc inlineSnapshot_start { user session_id filename } {
    if { [catch {
        set url [::config getStr video.snapshotInlineUrl]
        set token [http::geturl $url -timeout 12000]
        checkHttpStatus $token
        set result [http::data $token]
        http::cleanup $token
        impWriteFile $user $session_id $filename $result
    } err] } {
        log_error inline camera snapshot failed: $err
        return -code error $err
    }

}
