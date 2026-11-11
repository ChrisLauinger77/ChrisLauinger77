
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

FILE="paseo-plugins.txt"

command -v paseo >/dev/null || {
    echo "Fehler: paseo nicht gefunden"
    exit 1
}

[[ -f "$FILE" ]] || {
    echo "Fehler: plugins.txt fehlt"
    exit 1
}

# Einmal die installierten Plugin-IDs einlesen
installed=$(paseo plugin ls | awk 'NR > 1 {print $1}')

added=0
skipped=0
failed=0

while read -r name source _; do
    [[ -z "${name:-}" || "$name" == \#* ]] && continue

    if grep -Fxq "$name" <<< "$installed"; then
        echo "✓ $name bereits installiert"
        ((skipped+=1))
        continue
    fi

    echo "→ Installiere $name ($source)"

    if paseo plugin add "$source"; then
        ((added+=1))
    else
        echo "✗ Fehler bei $name"
        ((failed+=1))
    fi

done < "$FILE"

echo
echo "Synchronisierung abgeschlossen:"
echo "  Installiert: $added"
echo "  Vorhanden:   $skipped"
echo "  Fehler:      $failed"

((failed == 0))
