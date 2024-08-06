#!/bin/bash

echo "universal_launch" >> /tmp/polybar1.log

if type "xrandr"; then
  monitors_list=$(xrandr --query | grep " connected" | cut -d" " -f1)

  echo "available monitors: $monitors_list" >> /tmp/polybar1.log

  for m in $monitors_list; do
    echo "launch polybar for $m monitor" >> /tmp/polybar1.log

    MONITOR=$m polybar --reload single &
  done
else
  echo "xrandr is not detected" >> /tmp/polybar1.log

  polybar --reload single
fi

