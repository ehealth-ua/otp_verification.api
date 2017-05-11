#!/bin/sh
# `pwd` should be /opt/otp_verification_api
APP_NAME="otp_verification_api"

if [ "${DB_MIGRATE}" == "true" ]; then
  echo "[WARNING] Migrating database!"
  ./bin/$APP_NAME command "${APP_NAME}_tasks" migrate!
fi;
