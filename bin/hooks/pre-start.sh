#!/bin/sh

if [ "${DB_MIGRATE}" == "true" ]; then
  echo "[WARNING] Migrating database!"
  ./bin/otp_verification_api command "Elixir.Core.ReleaseTasks" migrate
fi;
