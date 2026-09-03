# talay-identity

Repo kökündeki install stack Keycloak'ı harici `talay-data` PostgreSQL servisine bağlı olarak kurar. `stacks/configure` ikinci state'te `talay` realm'ini, grupları ve Argo CD/web/mobil/API client'larını oluşturur. Bu ayrım, Keycloak API kurulmadan Keycloak provider'ın plan sırasında bağlantı kurmaya çalıştığı bootstrap döngüsünü çözer.

Admin bootstrap ve veritabanı parolaları Vault'tan External Secrets Operator ile gelir; Terraform state'ine girmez. Configure stack provider kimlik bilgilerini `KEYCLOAK_USER` ve `KEYCLOAK_PASSWORD` ortam değişkenlerinden okur.

Vault alanları:

```text
kv/platform/postgresql: password
kv/platform/keycloak:   username, password
```

Chart tek-node profiline göre bir replica çalıştırır. Çok-node üretim topolojisinde Keycloak cache discovery, PostgreSQL HA ve en az üç replica ayrı kapasite çalışmasıyla etkinleştirilmelidir.
