#!/usr/bin/env bash

# Terminate already running bar instances
killall -q polybar

# Launch bar1 and bar2
# echo "---" | tee -a /tmp/polybar1.log /tmp/polybar2.log
echo "___" >> /tmp/polybar1.log

~/.config/polybar/scripts/universal_launch.sh 2>> /tmp/polybar1.log

echo "Bars launched..." >> /tmp/polybar1.log

