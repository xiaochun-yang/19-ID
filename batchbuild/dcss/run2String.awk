function skipToEmptyLine() {
    getline
    while ($0!="") {
        getline
    }
}

BEGIN {
    found_fillRun=0
    found_runsConfig=0
    found_autoDose=0
    found_collectWeb=0
    found_abortCollectWeb=0
    found_collect_config=0
    found_runExtra=0
    found_cassette_owner=0
}


{
    if ($0 != "END") print $0;
    if ($0 ~ /^run[0-9]+$/) {
        skipToEmptyLine()
        print "13"
        print "self runDefinition"
        print "1 1 1 1 1"
        print "0 1 1 1 1"
        print "inactive 0 0 test0 /data/ 1 Phi 1.00 2.00 1.00 180.00 1.0 100.00 40.0 0.0 1 12000.000 0.0 0.0 0.0 0.0 1 0"
        print ""
    } else if ($0 == "runs") {
        skipToEmptyLine()
        print "13"
        print "self standardString"
        print "1 1 1 1 1"
        print "0 1 1 1 1"
        print "0 0 0"
        print ""
    } else {
        if ($0 == "fillRun") found_fillRun=1
        if ($0 == "runsConfig") found_runsConfig=1
        if ($0 == "autoDose") found_autoDose=1
        if ($0 == "collectWeb") found_collectWeb=1
        if ($0 == "abortCollectWeb") found_abortCollectWeb=1
        if ($0 == "collect_config" ) found_collect_config=1
        if ($0 == "runExtra0" ) found_runExtra=1
        if ($0 == "cassette_owner" ) found_cassette_owner=1
    }
}
END {
    if (!found_fillRun) {
        print "fillRun"
        print "11"
        print "self fillRun"
        print "0 1 1 1 1"
        print "0 1 1 1 1"
        print ""
    }
    if (!found_runsConfig) {
        print "runsConfig"
        print "11"
        print "self runsConfig"
        print "0 1 1 1 1"
        print "0 1 1 1 1"
        print ""
    }
    if (!found_autoDose) {
        print "autoDose"
        print "11"
        print "self autoDose"
        print "0 1 1 1 1"
        print "0 1 1 1 1"
        print ""
    }
    if (!found_collectWeb) {
        print "collectWeb"
        print "11"
        print "self collectWeb"
        print "0 1 1 1 1"
        print "0 1 1 1 1"
        print ""
    }
    if (!found_abortCollectWeb) {
        print "abortCollectWeb"
        print "11"
        print "self abortCollectWeb"
        print "1 1 1 1 1"
        print "1 1 1 1 1"
        print ""
    }
    if (!found_collect_config) {
        print "collect_config"
        print "13"
        print "self standardString"
        print "1 1 1 1 1"
        print "0 0 0 0 0"
        print "0 0 0 0 0 0 0 0 0"
        print ""
    }
    if (!found_runExtra) {
        for (i=0; i<17; ++i) {
            print "runExtra" i
            print "13"
            print "self standardString"
            print "0 1 1 1 1"
            print "0 1 1 1 1"
            print "{} {} {} {} {} {} {}"
            print ""
        }
    }
    if (!found_cassette_owner) {
        print "cassette_owner"
        print "13"
        print "self standardString"
        print "1 1 1 1 1"
        print "0 0 0 0 0"
        print "{} {} {} {}"
        print ""
    }

    print "END"
}
