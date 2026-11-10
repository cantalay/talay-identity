# talay-identity

`stacks/install`, `modules/keycloak` üzerinden Keycloak'ı harici `talay-data` PostgreSQL servisine bağlı olarak kurar. `stacks/configure`, `modules/keycloak-configuration` üzerinden ikinci state'te platform realm entegrasyonunu, grupları ve Argo CD/Vault istemcilerini oluşturur. Bu ayrım, Keycloak API kurulmadan Keycloak provider'ın plan sırasında bağlantı kurmaya çalıştığı bootstrap döngüsünü çözer.

Admin bootstrap ve veritabanı parolaları Vault'tan External Secrets Operator ile gelir; Terraform state'ine girmez. Configure stack provider kimlik bilgilerini `KEYCLOAK_USER` ve `KEYCLOAK_PASSWORD` ortam değişkenlerinden okur.

`modules/application-identity`, uygulamaya ait realm, public PKCE istemcileri, bearer-only API audience ve realm rollerini kod olarak yönetir. VitaFinder için `vitafinder` realm'i; `vitafinder-storefront`, `vitafinder-admin` ve `vitafinder-api` istemcileri configure stack tarafından oluşturulur. Yeni kayıt olan kullanıcılara yalnızca `user` rolü otomatik atanır; yönetim rolleri Keycloak'ta yetkili operatör tarafından atanır.

Vault alanları:

```text
kv/platform/postgresql: password
kv/platform/keycloak:   username, password
```

Chart tek-node profiline göre bir replica çalıştırır. Çok-node üretim topolojisinde Keycloak cache discovery, PostgreSQL HA ve en az üç replica ayrı kapasite çalışmasıyla etkinleştirilmelidir.

## Yeni uygulama kimliği

`modules/application-identity` her uygulama için bir realm üretir. Yeni proje `stacks/configure/main.tf` içine bir
modül çağrısı olarak eklenir:

```hcl
module "example_identity" {
  source = "../../modules/application-identity"

  keycloak_url = var.keycloak_url
  realm_name   = "example"
  display_name = "Example"
  browser_clients = {
    web = { root_url = "https://example.cantalay.com" }                       # client id: example-web
    mobile = {
      root_url            = "https://example.cantalay.com"
      extra_redirect_uris = ["example://auth/callback"]
    }
  }
  api_client_enabled   = true            # example-api (bearer-only) + browser token audience
  realm_roles          = ["user", "admin"]
  default_role         = "user"
  registration_allowed = true
}
```

Browser client'ları public ve PKCE S256'dır; redirect `<root_url>/*` (+ `extra_redirect_uris`), web origin
`<root_url>`. Uygulama API'leri issuer `https://auth.cantalay.com/realms/<realm>` ve audience `<realm>-api` ile
JWT doğrular; roller `realm_access.roles` claim'indedir.

### Keycloak eklentileri ve platform girişi

- **Eklentiler.** `stacks/install` → `providers_image`. Kaynak:
  [talay-keycloak-providers](https://github.com/cantalay/talay-keycloak-providers).
  - İmaj init container olarak JAR'ı `/opt/keycloak/providers` birimine kopyalar. `kc.sh start` açılışta derler, bu da açılışa
    yaklaşık 30 sn ekler.
  - İmaj değişince Keycloak pod'u yeniden başlar; kısa bir giriş kesintisi olur, dağıtılmış JWT'ler geçerli kalır.
- **Keycloak dosya kasası.** `stacks/install` → `vault_realm_secrets_key` (Vault yolu).
  - Realm yapılandırmalarındaki `${vault.<anahtar>}` referansları bu yolun `<realm>_<anahtar>` alanlarından okunur
    (ExternalSecret `keycloak-realm-vault`).
  - Sır Terraform durumuna girmez.
- **Platform girişi** (`platform_identity`, modül değişkeni): Game Center / Play Games ile parolasız giriş.
  - Oluşanlar:
    - `platform-direct-grant` akışı;
    - `platform-identity` authenticator yapılandırması;
    - `<realm>-platform` istemcisi (public, yalnız bu direct grant).
  - auth-gateway `/auth/<realm>/platform` bu istemciyi kullanır. Kimlik kullanıcı özniteliğindedir; bağlama ucu
    `/realms/<realm>/platform-identity/link`.
  - Önce `stacks/install` (eklenti yüklü olmalı), sonra `stacks/configure` uygulanır.

### auth-gateway client'ları

`gateway_client_enabled = true` uygulamanın kendi login ekranını auth-gateway (`/auth/<realm>/*`) üzerinden
kullanmasını sağlar: `<realm>-gateway` (public, direct grant, API audience) ve `<realm>-gateway-admin`
(manage/query/view-users service account). Admin secret write-only'dir; Vault
`kv/apps/todogi/keycloak` → `GATEWAY_REALMS_<REALM>_ADMINCLIENTSECRET` alanından her plan/apply'da verilir:

```bash
export TF_VAR_gateway_admin_client_secrets="{\"vitafinder\":\"$(vault kv get -mount=kv -field=GATEWAY_REALMS_VITAFINDER_ADMINCLIENTSECRET apps/todogi/keycloak)\"}"
```

Client `access_token_lifespan` değerleri **saniye** cinsindendir (`"300"`); `"5m"` gibi değerler Keycloak'ta token
üretirken 500'e yol açar.
