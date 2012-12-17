#package require Itcl
#namespace import ::itcl::*
package require DCSRaster

### we want to allow user to flip during collectRaster,
### so it has to move out of rasterRunsConfig and moved here.
### rasterRunsConfig is a blocking operation.

proc rasterRunsFlip_initialize {} {
	global gOperation
    #enable parallel calling
    set gOperation(rasterRunsFlip,parallel) 1
}
proc rasterRunsFlip_start { command args } {
    switch -exact -- $command {
        flip_node {
            ### this is allowed even when collectRaster is running
            eval rasterRunsFlipNode $args
        }
        default {
            return -code error "wrong command: $command"
        }
    }
}
