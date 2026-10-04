#!/usr/bin/env bash
# Bir Keycloak realm'inin SMTP ayarını Vault kv/platform/smtp'den uygular (parola Terraform state'ine girmez) ve
# isteğe bağlı olarak e-posta doğrulamasını açar/kapatır. Terraform'da olmayan realm'ler (todogi) için doğrulama
# ayarı da buradan yönetilir; Terraform'daki realm'lerde verify_email modül değişkeniyle yönetilir.
#
# Kullanım:
#   scripts/configure-realm-email.sh --realm <realm> --from <adres> --from-name <ad> [--verify-email true|false]
#                                    [--mark-existing-verified]
# Ortam: APPLY=true (yoksa dry-run), VAULT_ADDR, KEYCLOAK_URL (varsayılan https://auth.cantalay.com),
#        TALAY_HOST (admin kimliği identity/keycloak-bootstrap secret'ından SSH ile okunur)
set -euo pipefail

export VAULT_ADDR="${VAULT_ADDR:-https://vault.cantalay.com}"
KEYCLOAK_URL="${KEYCLOAK_URL:-https://auth.cantalay.com}"
TALAY_HOST="${TALAY_HOST:-45.87.80.10}"
APPLY="${APPLY:-false}"
realm="" from="" from_name="" verify="" mark_verified=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --realm) realm="$2"; shift 2 ;;
    --from) from="$2"; shift 2 ;;
    --from-name) from_name="$2"; shift 2 ;;
    --verify-email) verify="$2"; shift 2 ;;
    --mark-existing-verified) mark_verified=true; shift ;;
    -h|--help) sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Bilinmeyen argüman: $1" >&2; exit 1 ;;
  esac
done
[[ "$realm" =~ ^[a-z0-9]+$ ]] || { echo "--realm gerekli" >&2; exit 1; }
[[ "$from" == *@* ]] || { echo "--from gerekli" >&2; exit 1; }
[[ -n "$from_name" ]] || { echo "--from-name gerekli" >&2; exit 1; }
[[ -z "$verify" || "$verify" == true || "$verify" == false ]] || { echo "--verify-email true|false" >&2; exit 1; }
[[ "$realm" != master && "$realm" != monitoring ]] || { echo "$realm platform realm'idir" >&2; exit 1; }
vault token lookup >/dev/null 2>&1 || { echo "Vault girişi yok: vault login -method=oidc" >&2; exit 1; }

umask 077
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

vault kv get -mount=kv -format=json platform/smtp > "$tmp/smtp.json"
admin_json="$(ssh -o BatchMode=yes "root@$TALAY_HOST" "kubectl get secret -n identity keycloak-bootstrap -o jsonpath='{.data}'")"
token="$(ADMIN_JSON="$admin_json" KEYCLOAK_URL="$KEYCLOAK_URL" python3 - <<'PY'
import base64, json, os, urllib.parse, urllib.request
d = json.loads(os.environ["ADMIN_JSON"])
body = urllib.parse.urlencode({
    "grant_type": "password", "client_id": "admin-cli",
    "username": base64.b64decode(d["KC_BOOTSTRAP_ADMIN_USERNAME"]).decode(),
    "password": base64.b64decode(d["KC_BOOTSTRAP_ADMIN_PASSWORD"]).decode(),
}).encode()
with urllib.request.urlopen(f"{os.environ['KEYCLOAK_URL']}/realms/master/protocol/openid-connect/token", body) as r:
    print(json.load(r)["access_token"])
PY
)"
unset admin_json

TOKEN="$token" REALM="$realm" FROM="$from" FROM_NAME="$from_name" VERIFY="$verify" MARK="$mark_verified" \
APPLY="$APPLY" KEYCLOAK_URL="$KEYCLOAK_URL" SMTP_FILE="$tmp/smtp.json" python3 - <<'PY'
import json, os, urllib.request

base, realm, token = os.environ["KEYCLOAK_URL"], os.environ["REALM"], os.environ["TOKEN"]
apply = os.environ["APPLY"] == "true"
smtp = json.load(open(os.environ["SMTP_FILE"]))["data"]["data"]

def call(method, path, body=None):
    req = urllib.request.Request(f"{base}/admin/realms/{realm}{path}", method=method,
                                 data=json.dumps(body).encode() if body is not None else None,
                                 headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"})
    with urllib.request.urlopen(req) as r:
        raw = r.read()
        return json.loads(raw) if raw else None

current = call("GET", "")
desired_smtp = {
    "host": smtp["host"], "port": str(smtp["port"]), "auth": "true",
    "user": smtp["username"], "password": smtp["password"],
    "ssl": str(smtp.get("ssl", "true")).lower(), "starttls": str(smtp.get("starttls", "false")).lower(),
    "from": os.environ["FROM"], "fromDisplayName": os.environ["FROM_NAME"],
}
masked = {k: ("***" if k == "password" else v) for k, v in desired_smtp.items()}
print(f"realm {realm}")
print("  smtp şimdi :", {k: ("***" if k == "password" else v) for k, v in (current.get("smtpServer") or {}).items()})
print("  smtp hedef :", masked)
verify = os.environ["VERIFY"]
if verify:
    print(f"  verifyEmail: {current.get('verifyEmail')} -> {verify}")

users = call("GET", "/users?max=1000&briefRepresentation=true")
unverified = [u for u in users if not u.get("emailVerified") and not u["username"].startswith("service-account-")]
if os.environ["MARK"] == "true":
    print(f"  doğrulanmamış {len(unverified)} kullanıcı doğrulanmış işaretlenecek")

if not apply:
    print("DRY-RUN: değişiklik yapılmadı (APPLY=true ile uygula)")
    raise SystemExit(0)

if os.environ["MARK"] == "true":
    for u in unverified:
        call("PUT", f"/users/{u['id']}", {"emailVerified": True})
    print(f"  {len(unverified)} kullanıcı doğrulanmış işaretlendi")
update = {"smtpServer": desired_smtp}
if verify:
    update["verifyEmail"] = verify == "true"
call("PUT", "", update)
after = call("GET", "")
assert after["smtpServer"]["host"] == desired_smtp["host"] and after["smtpServer"]["from"] == desired_smtp["from"]
print("  uygulandı; verifyEmail =", after.get("verifyEmail"))
PY
