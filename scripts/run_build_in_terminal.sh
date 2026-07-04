#!/bin/bash
/Users/manyashukla/flutter-realtime-chat/scripts/run_build_now.sh
EC=$?
echo $EC > /Users/manyashukla/flutter-realtime-chat/apks/build_exit_code.txt
exit $EC
