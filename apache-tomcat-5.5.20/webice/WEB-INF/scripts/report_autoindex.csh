#!/bin/csh -f

set SCRIPT_DIR = `dirname $0`
setenv WEBICE_TOPIC "webice autoindexing images at beamline"
set keyword = "autoindexing images at beamline"
$SCRIPT_DIR/report_search_text.csh $keyword

