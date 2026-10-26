# Builds locales

Este directorio conserva artefactos de compilación locales. Los binarios `.ipa`
están ignorados por Git y no se suben al repositorio de código.

- `archive/root-ipa-history/`: IPA históricas que antes estaban sueltas en la
  raíz del proyecto. Se movieron sin recompilar ni alterar su contenido.
- Los demás archivos de build permanecen en su carpeta de origen para conservar
  la relación con el checkout y el proceso que los produjo.

No guardar aquí credenciales, certificados privados ni perfiles de firma.
