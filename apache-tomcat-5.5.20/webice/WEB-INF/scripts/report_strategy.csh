#!/bin/csh -f

set SCRIPT_DIR = `dirname $0`
setenv WEBICE_TOPIC "webice exporting strategy to beamline"
set keyword = "exporting run definition to beamline"
$SCRIPT_DIR/report_search_text.csh $keyword

