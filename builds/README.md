# Builds locales

Este directorio conserva artefactos de compilación locales. Los binarios `.ipa`
están ignorados por Git y no se suben al repositorio de código.

- `archive/root-ipa-history/`: IPA históricas que antes estaban sueltas en la
  raíz del proyecto. Se movieron sin recompilar ni alterar su contenido.
- `archive/alternate-checkout-20261017/`: dos IPA identificadas como test y
  stable backup del checkout alternativo. El checkout completo está bajo
  `local-archive/alternate-checkouts/`.

Las fuentes definitivas viven en `balatron/` y `MODS/`. No usar estas IPA como
prueba de que contienen los cambios posteriores de los mods.

No guardar aquí credenciales, certificados privados ni perfiles de firma.
