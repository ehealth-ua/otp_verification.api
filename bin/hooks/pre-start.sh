#!/bin/sh

if [[ "${DB_MIGRATE}" == "true" && -f "./bin/otp_verification_api" ]]; then
  echo "[WARNING] Migrating database!"
  ./bin/otp_verification_api command "Elixir.Core.ReleaseTasks" migrate
fi;
