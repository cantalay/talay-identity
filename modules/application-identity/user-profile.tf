# Kullanıcı profili (Keycloak declarative user profile). Varsayılan profilde ad ve soyad `user` rolü için zorunludur; sosyal
# girişte sağlayıcı adı vermezse (Apple adı yalnız ilk yetkilendirmede, passkey/yeniden girişte hiç göndermez) Keycloak
# VERIFY_PROFILE adımında KENDİ "Hesap bilgilerini güncelle" sayfasını gösterir — uygulamalar Keycloak sayfası göstermez
# (talay-auth). person_name_optional = true: ad/soyad isteğe bağlı; ad uygulamanın kendi ekranında istenir/düzenlenir.
# Diğer alanlar Keycloak varsayılanının aynısıdır (2026-11-26 todogi canlı profilinden).

resource "keycloak_realm_user_profile" "names_optional" {
  count = var.person_name_optional ? 1 : 0

  realm_id = keycloak_realm.application.id

  attribute {
    name         = "username"
    display_name = "$${username}"
    multi_valued = false

    permissions {
      view = ["admin", "user"]
      edit = ["admin", "user"]
    }

    validator {
      name   = "length"
      config = { min = "3", max = "255" }
    }
    validator {
      name = "username-prohibited-characters"
    }
    validator {
      name = "up-username-not-idn-homograph"
    }
  }

  attribute {
    name               = "email"
    display_name       = "$${email}"
    multi_valued       = false
    required_for_roles = ["user"]

    permissions {
      view = ["admin", "user"]
      edit = ["admin", "user"]
    }

    validator {
      name = "email"
    }
    validator {
      name   = "length"
      config = { max = "255" }
    }
  }

  attribute {
    name         = "firstName"
    display_name = "$${firstName}"
    multi_valued = false

    permissions {
      view = ["admin", "user"]
      edit = ["admin", "user"]
    }

    validator {
      name   = "length"
      config = { max = "255" }
    }
    validator {
      name = "person-name-prohibited-characters"
    }
  }

  attribute {
    name         = "lastName"
    display_name = "$${lastName}"
    multi_valued = false

    permissions {
      view = ["admin", "user"]
      edit = ["admin", "user"]
    }

    validator {
      name   = "length"
      config = { max = "255" }
    }
    validator {
      name = "person-name-prohibited-characters"
    }
  }

  group {
    name                = "user-metadata"
    display_header      = "User metadata"
    display_description = "Attributes, which refer to user metadata"
  }
}
