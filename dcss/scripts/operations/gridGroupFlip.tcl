proc gridGroupFlip_initialize { } {
	global gOperation

    set gOperation(gridGroupFlip,parallel) 1
}
proc gridGroupFlip_start { command args } {
    switch -exact -- $command {
        flip_node {
            eval gridGroupFlipNode $args
        }
        default {
            return -code error "wrong command $command, only support flip_node"
        }
    }
}
