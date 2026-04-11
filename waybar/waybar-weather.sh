#!/usr/bin/env bash

URL="https://old.john.me.tz/weather/weather.json"

curl $URL -o ${HOME}/.local/state/latest_weather 2>/dev/null
RAW="$(cat ${HOME}/.local/state/latest_weather | jq -r '.current | .weather[0]')"
MAIN="$(cat ${HOME}/.local/state/latest_weather | jq -r '.current | .weather[0] | .main')"
DESC="$(cat ${HOME}/.local/state/latest_weather | jq -r '.current | .weather[0] | .description')"
ICON="$(cat ${HOME}/.local/state/latest_weather | jq -r '.current | .weather[0] | .icon')"
WIND="$(cat ${HOME}/.local/state/latest_weather | jq -r '.current | .wind_speed')"
WDEG="$(cat ${HOME}/.local/state/latest_weather | jq -r '.current | .wind_deg')"
TEMP="$(cat ${HOME}/.local/state/latest_weather | jq -r '.current | .feels_like')"
TEMP=$(bc <<<"$TEMP-273.15" | cut -d '.' -f 1)

if [[ $WDEG -gt 337 ]]; then
  WDIR=North
elif [[ $WDEG -gt 292 ]]; then
  WDIR=North-West
elif [[ $WDEG -gt 247 ]]; then
  WDIR=West
elif [[ $WDEG -gt 202 ]]; then
  WDIR=South-West
elif [[ $WDEG -gt 157 ]]; then
  WDIR=South
elif [[ $WDEG -gt 112 ]]; then
  WDIR=South-East
elif [[ $WDEG -gt 67 ]]; then
  WDIR=East
elif [[ $WDEG -gt 22 ]]; then
  WDIR=North-East
else
  WDIR=North
fi

if [[ $ICON == '01d' ]]; then
  ICON="☀"
elif [[ $ICON == '01n' ]]; then
  ICON="☾"
elif [[ $ICON == '02d' ]]; then
  ICON="🌤"
elif [[ $ICON == '02n' ]]; then
  ICON="☁"
elif [[ $ICON == '03d' ]]; then
  ICON="🌥"
elif [[ $ICON == '03n' ]]; then
  ICON="☁"
elif [[ $ICON == '04d' ]]; then
  ICON="🌥"
elif [[ $ICON == '04n' ]]; then
  ICON="☁"
elif [[ $ICON == '09d' ]]; then
  ICON="🌧"
elif [[ $ICON == '09n' ]]; then
  ICON="🌧"
elif [[ $ICON == '10d' ]]; then
  ICON="🌦"
elif [[ $ICON == '10n' ]]; then
  ICON="🌧"
elif [[ $ICON == '11d' ]]; then
  ICON="⛈"
elif [[ $ICON == '11n' ]]; then
  ICON="⛈"
elif [[ $ICON == '13d' ]]; then
  ICON="❄"
elif [[ $ICON == '13n' ]]; then
  ICON="❄"
elif [[ $ICON == '50d' ]]; then
  ICON="🌫"
elif [[ $ICON == '50n' ]]; then
  ICON="🌫"
else
  ICON="？"
fi

echo '{"text": "'$ICON'  '$TEMP'°C", "tooltip": "Condition: '$DESC', Wind: '$WIND'km/h '$WDIR'", "class": "'$MAIN'"}'

#⛈  - Thunderstorm
#🌤 - Partly Cloudy
#🌥 - Sun and Cloud
#🌦 - Rain and Sun
#🌧 - Rain
#🌨 - Snow
#🌩 - Lightning
#🌪 - Tornado
#🌫 - Mist
#❄ - Snow
#★ - Clear night stars
