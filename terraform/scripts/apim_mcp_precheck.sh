#!/usr/bin/env bash
set -euo pipefail

json_escape() {
  local s="$1"
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\n'/ }
  printf '%s' "$s"
}

az_cli_installed="false"
az_logged_in="false"
apis_resource_type_available="false"
error_message=""

if ! command -v az >/dev/null 2>&1; then
  error_message="Azure CLI (az) is not installed or not on PATH."
else
  az_cli_installed="true"

  if az account show >/dev/null 2>&1; then
    az_logged_in="true"

    # Non-empty result means the APIM APIs resource type is available.
    if len="$(az provider show -n Microsoft.ApiManagement --query "resourceTypes[?resourceType=='service/apis'] | length(@)" -o tsv 2>/dev/null)"; then
      len="$(tr -d '[:space:]' <<<"$len")"
      if [[ "$len" =~ ^[0-9]+$ ]] && (( len > 0 )); then
        apis_resource_type_available="true"
      fi
    else
      error_message="Unable to query Microsoft.ApiManagement provider metadata."
    fi
  else
    error_message="Azure CLI is not logged in. Run 'az login' and retry."
  fi
fi

printf '{"az_cli_installed":"%s","az_logged_in":"%s","apis_resource_type_available":"%s","error_message":"%s"}\n' \
  "$az_cli_installed" \
  "$az_logged_in" \
  "$apis_resource_type_available" \
  "$(json_escape "$error_message")"
