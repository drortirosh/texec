#!/bin/sh
#this script runs inside the "testrunner" docker image, to execute the test command.
#input parameters defined in "runbundler.yml"
# TESTRUNNER_OUTFILE - base name of output (xml,json) files, created in "/output" folder
# TESTRUNNER_ARGS - extra pytest command-line args
# ETH_RPC_URL, BUNDLER_URL, ENTRYPOINT - passed to pytest params
# VERBOSE - 1 for script debugging
test -n "$VERBOSE" && set -x


if [ -z "$2" ] ; then
    echo "usage: $0 {test|p2ptest} {outfile} {pytest args}"
    exit 1
fi

cmd=$1
shift
outfile=$1
shift
args="$*"

outxml=/output/$outfile.xml
outjson=/output/$outfile.json

#set -o pipefail
cmd="pdm $cmd --tb=short -rA -W ignore::DeprecationWarning
    --url $BUNDLER_URL 
    --ethereum-node $ETH_RPC_URL
    --entry-point $ENTRYPOINT 
    -o junit_logging=all 
    -o junit_log_passing_tests=false 
    -o junit_suite_name=`basename $outfile` 
    --junit-xml $outxml 
    $args
    "

$cmd

test -r $outxml && xq . $outxml > $outjson
echo created $outxml $outjson
cat $outjson | jq '.testsuites.testsuite | { "@name", "@tests", "@errors", "@failures", "@skipped", "@time" }' -c