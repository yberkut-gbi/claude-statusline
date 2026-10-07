#!/bin/sh
# Remove the status line on macOS / Linux. Windows: use uninstall.ps1.
exec sh "$(dirname "$0")/install.sh" --uninstall
