#!/usr/bin/env bash
# Thin wrapper to run the Workjournal CLI login flow.
# Used by agents that activate the journal skill and need to authenticate.
exec npx --yes @workjournal/cli login "$@"
