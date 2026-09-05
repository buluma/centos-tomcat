#!/usr/bin/env bash
# Coverage for the Dockerfile GPG signer-derivation flow (Dockerfile line 36).
#
#   test_signature_flow.sh [-d <artifact-dir>]
#
# Uses a throwaway GNUPGHOME only; never touches the host keyring.
# Requires: gpg, awk, sha512sum (or shasum), wget or curl.

set -u

TOMCAT_MAJOR=10
TOMCAT_VERSION=10.1.59
BASE="https://downloads.apache.org/tomcat/tomcat-${TOMCAT_MAJOR}"
CDN="https://dlcdn.apache.org/tomcat/tomcat-${TOMCAT_MAJOR}/v${TOMCAT_VERSION}"
ARTDIR="${1:--d}"
OPTART="no"
if [ "${1:-}" = "-d" ]; then ART="$2"; OPTART=yes; else ART=""; fi

WORK="$(mktemp -d)"
GNUPGHOME="$WORK/gnupg"; mkdir -p "$GNUPGHOME"; chmod 700 "$GNUPGHOME"
export GNUPGHOME
trap 'rm -rf "$WORK"' EXIT

# The exact derivations used by the Dockerfile (mirror of Dockerfile line 36).
derive_signer() {  # $1=asc  $2=archive
    gpg --batch --status-fd=1 --verify "$1" "$2" 2>/dev/null \
        | awk '/^\[GNUPG:\] VALIDSIG /{ if (NF>=12 && $12 ~ /^[0-9A-F]{40}$/) print $12; else print $3; exit }'
}
is_allowed() {  # $1=signer fpr, rest = allowlist
    local s="$1"; shift
    for a in "$@"; do [ "$s" = "$a" ] && return 0; done
    return 1
}
sha512_of() { command -v sha512sum >/dev/null 2>&1 && sha512sum "$1" || shasum -a 512 "$1"; }
fetch() { if command -v wget >/dev/null 2>&1; then wget -q -O "$1" "$2"; else curl -fsS -o "$1" "$2"; fi; }

ALLOWLIST=(5C3C5F3E314C866292F359A8F3AD5C94A67F707E A9C5DF4D22E99998D9875A5110C01C5A2F6059E7)

fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "ok:   $*"; }

# ---------------------------------------------------------------- case 1
echo "== Case 1: real Tomcat archive (signed by a subkey) =="
cd "$WORK"
if [ "$OPTART" = yes ]; then
    cp "$ART/KEYS" "$ART/apache-tomcat-$TOMCAT_VERSION.tar.gz" \
       "$ART/apache-tomcat-$TOMCAT_VERSION.tar.gz.asc" \
       "$ART/apache-tomcat-$TOMCAT_VERSION.tar.gz.sha512" "$WORK/"
else
    fetch KEYS "$BASE/KEYS" || fail "cannot fetch KEYS"
    fetch "apache-tomcat-$TOMCAT_VERSION.tar.gz" "$CDN/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz" || fail "cannot fetch archive"
    fetch "apache-tomcat-$TOMCAT_VERSION.tar.gz.asc" "$BASE/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz.asc" || fail "cannot fetch asc"
    fetch "apache-tomcat-$TOMCAT_VERSION.tar.gz.sha512" "$BASE/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz.sha512" || fail "cannot fetch sha512"
fi

sha512_of "apache-tomcat-$TOMCAT_VERSION.tar.gz" | awk '{print $1}'
expected=$(awk '{print $1}' "apache-tomcat-$TOMCAT_VERSION.tar.gz.sha512")
hash=$(sha512_of "apache-tomcat-$TOMCAT_VERSION.tar.gz" | awk '{print $1}')
[ "$hash" = "$expected" ] || fail "sha512 mismatch"
ok "sha512 matches"

gpg --batch --import KEYS >/dev/null 2>&1 || fail "KEYS import"
gpg --batch --verify "apache-tomcat-$TOMCAT_VERSION.tar.gz.asc" "apache-tomcat-$TOMCAT_VERSION.tar.gz" >/dev/null 2>&1 \
    || fail "archive signature invalid"

SIGNER=$(derive_signer "apache-tomcat-$TOMCAT_VERSION.tar.gz.asc" "apache-tomcat-$TOMCAT_VERSION.tar.gz")
case "$SIGNER" in
    ????????????????????????????????????????) ;; *) fail "bad signer shape: '$SIGNER'";;
esac
is_allowed "$SIGNER" "${ALLOWLIST[@]}" || fail "signer not allowlisted: $SIGNER"
ok "derived signer=$SIGNER is an allowed Tomcat release manager"
[ "$SIGNER" = "${ALLOWLIST[0]}" ] && ok "subkey signature correctly mapped to primary key"

# ---------------------------------------------------------------- case 2
echo "== Case 2: archive fixture signed directly by a primary key =="
gpg --batch --passphrase '' --quick-gen-key "Fixture Signer <fixture@example.org>" rsa2048 >/dev/null 2>&1 \
    || fail "cannot generate fixture key"
FP=$(gpg --with-colons --list-keys fixture@example.org | awk -F: '/^fpr/{print $10; exit}')
[ "${#FP}" -eq 40 ] || fail "fixture key fingerprint malformed: $FP"

echo "fixture artifact" > fixture.tar.gz
gpg --batch --yes --output fixture.tar.gz.asc --armor --detach-sign fixture.tar.gz >/dev/null 2>&1 \
    || fail "cannot sign fixture with primary key"

SIGNER2=$(derive_signer fixture.tar.gz.asc fixture.tar.gz)
case "$SIGNER2" in
    ????????????????????????????????????????) ;; *) fail "bad signer shape: '$SIGNER2'";;
esac
[ "$SIGNER2" = "$FP" ] || fail "direct-primary signature mapped to wrong key: got $SIGNER2 want $FP"
is_allowed "$SIGNER2" "$FP" || fail "allowlist rejected fixture primary key"
ok "direct primary signature derived signer=$SIGNER2 passes allowlist"

echo ""
echo "ALL TESTS PASSED"