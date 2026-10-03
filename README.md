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
