#!/usr/bin/env bash
#
# Fotografiert die Hauptbildschirme in hell und dunkel -- einmal je Build,
# damit der sichtbare Stand jedes Builds festgehalten ist (Spec 13).
#
#   scripts/screenshots.sh [AUSGABEORDNER]
#
# Baut fuer den Simulator, legt ein Beispielabonnement an und laeuft dann
# die Bildschirme ab. Die Dateien heissen <commit>-<bildschirm>-<modus>.png.
set -euo pipefail

OUT=${1:-screenshots}
BUNDLE_ID=${BUNDLE_ID:-com.example.healthwake}
DERIVED=${DERIVED:-build/simulator}
COMMIT=$(git rev-parse --short=7 HEAD 2>/dev/null || echo unknown)

XCODEGEN=${XCODEGEN:-xcodegen}
"$XCODEGEN" generate >/dev/null

UDID=$(xcrun simctl list devices available \
  | grep -E '^[[:space:]]+iPhone' \
  | head -1 \
  | sed -E 's/.*\(([0-9A-Fa-f-]{36})\).*/\1/')
if [ -z "$UDID" ]; then
  echo "Kein iPhone-Simulator verfuegbar." >&2
  exit 1
fi

echo "Simulator: $UDID"
xcodebuild build \
  -scheme HealthWake \
  -destination "id=$UDID" \
  -derivedDataPath "$DERIVED" \
  CODE_SIGNING_ALLOWED=NO \
  -quiet

APP=$(find "$DERIVED/Build/Products" -maxdepth 3 -name "HealthWake.app" | head -1)
[ -n "$APP" ] || { echo "Keine gebaute App gefunden." >&2; exit 1; }

xcrun simctl boot "$UDID" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$UDID" >/dev/null
xcrun simctl uninstall "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl install "$UDID" "$APP"

# Beispieldaten direkt in den Datenordner der App legen. Ohne sie zeigen
# alle Bildschirme nur den Leerzustand -- und der sagt nichts ueber den Build.
CONTAINER=$(xcrun simctl get_app_container "$UDID" "$BUNDLE_ID" data)
SUPPORT="$CONTAINER/Library/Application Support/HealthWake"
mkdir -p "$SUPPORT/samples"

# Zeitpunkte: Abonnements und Warteschlange halten Sekunden seit 2001,
# Protokoll und Werte ISO-8601 (siehe Sources/Models/JSONCoding.swift).
NOW_EPOCH=$(date -u +%s)
REF=$((NOW_EPOCH - 978307200))
ISO=$(date -u -r "$NOW_EPOCH" +%Y-%m-%dT%H:%M:%S.000Z)

NOTIFICATION_CONFIG=$(printf '{"titleTemplate":"{{typeName}}","bodyTemplate":"{{value}} {{unit}} from {{source}}"}' | base64)
HTTP_CONFIG=$(printf '{"urlTemplate":"https://example.com/hook","method":"POST","headers":{},"bodyTemplate":"{\\"value\\": {{value}}}","keychainHeaderName":null}' | base64)

cat > "$SUPPORT/subscriptions.json" <<JSON
[{"id":"AAAAAAAA-0000-0000-0000-000000000001",
  "typeIdentifier":"HKQuantityTypeIdentifierBloodGlucose",
  "isEnabled":true,
  "filter":{"threshold":{"above":{"_0":200}},"allowedSourceNames":[]},
  "actions":[
    {"id":"BBBBBBBB-0000-0000-0000-000000000001","actionTypeID":"notification","configData":"$NOTIFICATION_CONFIG","isEnabled":true},
    {"id":"BBBBBBBB-0000-0000-0000-000000000002","actionTypeID":"httpPost","configData":"$HTTP_CONFIG","isEnabled":true}],
  "anchorData":null,
  "lastSampleAt":$((REF - 600)),
  "lastTriggeredAt":$((REF - 600)),
  "authorizationRequested":true,
  "createdAt":$((REF - 86400))},
 {"id":"AAAAAAAA-0000-0000-0000-000000000002",
  "typeIdentifier":"HKQuantityTypeIdentifierBodyMass",
  "isEnabled":true,
  "filter":{"threshold":{"none":{}},"allowedSourceNames":[]},
  "actions":[],
  "anchorData":null,
  "lastSampleAt":null,
  "lastTriggeredAt":null,
  "authorizationRequested":true,
  "createdAt":$((REF - 3600))}]
JSON

cat > "$SUPPORT/log.json" <<JSON
[{"id":"CCCCCCCC-0000-0000-0000-000000000001","date":"$ISO","kind":"actionSucceeded","message":"Notification ran for Blood Glucose","typeIdentifier":"HKQuantityTypeIdentifierBloodGlucose","actionTypeID":"notification"},
 {"id":"CCCCCCCC-0000-0000-0000-000000000002","date":"$ISO","kind":"sampleReceived","message":"Blood Glucose: 212 mg/dL from Dexcom","typeIdentifier":"HKQuantityTypeIdentifierBloodGlucose"},
 {"id":"CCCCCCCC-0000-0000-0000-000000000003","date":"$ISO","kind":"actionFailed","message":"HTTP Request failed: status(500)","typeIdentifier":"HKQuantityTypeIdentifierBloodGlucose","actionTypeID":"httpPost"},
 {"id":"CCCCCCCC-0000-0000-0000-000000000004","date":"$ISO","kind":"deliveryEnabled","message":"Delivery switched on, watching from now"}]
JSON

cat > "$SUPPORT/samples/HKQuantityTypeIdentifierBloodGlucose-$(date -u +%Y-%m).jsonl" <<JSON
{"sampleUUID":"DDDDDDDD-0000-0000-0000-000000000001","typeIdentifier":"HKQuantityTypeIdentifierBloodGlucose","typeName":"Blood Glucose","value":212,"unit":"mg/dL","date":"$ISO","sourceName":"Dexcom"}
{"sampleUUID":"DDDDDDDD-0000-0000-0000-000000000002","typeIdentifier":"HKQuantityTypeIdentifierBloodGlucose","typeName":"Blood Glucose","value":104,"unit":"mg/dL","date":"$ISO","sourceName":"Dexcom"}
JSON

mkdir -p "$OUT"
for MODE in light dark; do
  xcrun simctl ui "$UDID" appearance "$MODE" >/dev/null
  for SCREEN in types detail action log settings; do
    xcrun simctl terminate "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
    xcrun simctl launch "$UDID" "$BUNDLE_ID" -startScreen "$SCREEN" >/dev/null
    sleep 4
    xcrun simctl io "$UDID" screenshot "$OUT/$COMMIT-$SCREEN-$MODE.png" >/dev/null
    echo "$COMMIT-$SCREEN-$MODE.png"
  done
done
xcrun simctl terminate "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
echo "Fertig: $OUT"
