#!/bin/bash

if type "xrandr"; then
  # Get the number of connected monitor
  num_connected=$(xrandr --query | grep " connected" | wc -l)

  # Log the number of connected monitors
  echo "$num_connected monitors are connected" >> /tmp/bspwm.log

  # Check the number of connected monitors and perform actions accordingly
  if [ "$num_connected" -eq 3 ]; then
    bspc monitor DP-1 -d 1 2 3
    bspc monitor HDMI-1 -d 4 5 6
    bspc monitor DVI-D-1 -d 7 8 9
  elif [ "$num_connected" -eq 2 ]; then
    # TODO change the names of monitors !!!
    bspc monitor DVI-D-1 -d 1 2 3 4 5
    bspc monitor HDMI-1 -d 6 7 8 9
  elif [ "$num_connected" -eq 1 ]; then
    bspc monitor primary -d 1 2 3 4 5 6 7
  fi
else
  echo "executin default workspace" >> /tmp/bspwm.log

  bspc monitor primary -d 1 2 3 4 5 6 7
fi

