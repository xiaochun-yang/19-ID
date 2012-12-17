#!/bin/csh -f

set SCRIPT_DIR = `dirname $0`

$SCRIPT_DIR/report_count_users.csh
$SCRIPT_DIR/report_ave_login_per_day.csh


setenv WEBICE_TOPIC "webice exporting strategy to beamline"
set keyword = "exporting run definition to beamline"
$SCRIPT_DIR/report_search_text.csh $keyword | awk '/Total/{print $0;}'

setenv WEBICE_TOPIC "webice data collection"
set keyword = "DcsActiveClient.collectWeb sending msg: gtos_start_operation collectWeb"
$SCRIPT_DIR/report_search_text.csh $keyword | awk '/Total/{print $0;}'
