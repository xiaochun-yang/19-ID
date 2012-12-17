#!/bin/csh -f

set SCRIPT_DIR = `dirname $0`
setenv WEBICE_TOPIC "webice data collection"
set keyword = "DcsActiveClient.collectWeb sending msg: gtos_start_operation collectWeb"
$SCRIPT_DIR/report_search_text.csh $keyword
