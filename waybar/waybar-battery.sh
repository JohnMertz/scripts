#!/bin/bash

# Wrapper for ACPI to simplify interaction with waybar element

# Get full battery info
ACPI=$(acpi -b | head -n 1)

# Seperate out the different details
STATUS=$(echo $ACPI | cut -d':' -f2 | sed 's/^\s\([^,]*\),.*/\1/')
LEVEL=$(echo $ACPI | cut -d',' -f2 | sed 's/\s//g' | sed 's/%.*$//')
TIME=$(echo $ACPI | cut -d',' -f3 | cut -d' ' -f 2)

# Prepare for JSON output
CLASS="unknown"

# If no arguent was provided, just print human-friendly status
if [[ -z $1 ]]; then
  echo "$STATUS $LEVEL ($TIME)"

# 'bar' prints Waybar-friendly JSON
elif [[ $1 == bar ]]; then
  # Prepare pretty status indicator
  case "$STATUS" in
  # If discharging
  "Discharging")
    # Set "class" for waybar CSS
    CLASS="discharging"
    # Determine remaining battery and pick best icon
    case "$LEVEL" in
    [8-9][0-9])
      STATUS=" "
      ;;
    [6-7][0-9])
      STATUS=" "
      ;;
    [4-5][0-9])
      STATUS=" "
      ;;
    [2-3][0-9])
      STATUS=" "
      ;;
    1[0-9])
      CLASS="low"
      STATUS=" "
      ;;
    [1-9])
      CLASS="critical"
      STATUS=" "
      ;;
    *)
      STATUS="? "
      ;;
    esac
    ;;
  # "Not charging" can indicate that we are above a charging threshold, or there is insufficient
  # power to actually charge, or there is no battery. Treat this the same as just running on AC.
  "Not charging")
    CLASS="ac"
    STATUS=" "
    TIME="ꝏ "
    ;;
  # When full we are running on AC and the battery (if there is one) will never die.
  "Full")
    CLASS="ac"
    STATUS=" "
    TIME="ꝏ "
    ;;
  # ACPI doesn't provide an estimated change time. Treat this the same as AC with a different ICON.
  "Charging")
    CLASS="charging"
    STATUS="🗲"
    TIME="ꝏ "
    ;;
  # Occasionally ACPI fails to give a coherent status, especially right after a (un)plug event
  *)
    STATUS="✘"
    ;;
  esac
  # Output JSON
  printf '{"text":"%b%%","icon":"%b ","percentage":"%b","tooltip":"Time until discharged: %b","class":"%b"}' "${STATUS}  ${LEVEL}" $STATUS $LEVEL "$TIME" $CLASS

# 'notify' provides the human-friendly status as a notify-send notification
elif [[ $1 == 'notify' ]]; then
  notify-send Battery "$(echo $ACPI | cut -d':' -f2- | sed 's/\s//')"

else
  echo "invalid option $1"
fi
