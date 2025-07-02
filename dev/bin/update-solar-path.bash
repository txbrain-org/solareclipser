#!/usr/bin/env bash
PROJECT_ROOT_FULL_PATH=$(pwd)
PROJECT_SOLAR_PATH='lib/solar901'
PROJECT_SOLAR_FULL_PATH="$PROJECT_ROOT_FULL_PATH/$PROJECT_SOLAR_PATH"

if [[ ! -d "$PROJECT_SOLAR_FULL_PATH" ]]; then
    echo "Error: $PROJECT_SOLAR_FULL_PATH does not exist."
    exit 1
fi

if [[ ! -f "$PROJECT_SOLAR_PATH/solar" ]]; then
    echo "Error: $PROJECT_SOLAR_PATH/solar does not exist."
    exit 1
fi

sed -i "s|SOLAR_BIN=.*|SOLAR_BIN=$PROJECT_SOLAR_FULL_PATH/bin|" "$PROJECT_SOLAR_PATH/solar"
sed -i "s|SOLAR_LIB=.*|SOLAR_LIB=$PROJECT_SOLAR_FULL_PATH/lib|" "$PROJECT_SOLAR_PATH/solar"

printf "ln -sf %s /usr/local/bin/solar\n" "$PROJECT_SOLAR_FULL_PATH/solar"
sudo ln -sf "$PROJECT_SOLAR_FULL_PATH/solar" "/usr/local/bin/solar"
