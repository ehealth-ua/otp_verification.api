#!/bin/sh
# `pwd` should be /opt/otp_verification_api
APP_NAME="otp_verification_api"

if [ "${DB_MIGRATE}" == "true" ]; then
  echo "[WARNING] Migrating database!"
  ./bin/$APP_NAME command "Elixir.OtpVerification.ReleaseTasks" migrate!
fi;
