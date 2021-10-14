#!/bin/bash

battery=BAT0

echo - | awk "{printf \"%.1f\", \
$(( \
  $(cat /sys/class/power_supply/$battery/current_now) * \
  $(cat /sys/class/power_supply/$battery/voltage_now) \
)) / 1000000000000 }" ; echo " W "
