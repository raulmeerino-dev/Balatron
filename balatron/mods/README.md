# Dependencias del mod y adaptación portrait

Se conserva el código original de Steamodded 1.0.0-beta-1224a bajo `Steamodded/`,
incluida su licencia. `dependencies.lock.json` identifica archivos y hashes.
La versión está fijada para que las API y los patrones probados no cambien al
recompilar. Lovely 0.10.0 ya viene en el ejecutable ARM64 de la plantilla iOS.

Fuentes: [Steamodded](https://github.com/Steamodded/smods/releases/tag/1.0.0-beta-1224a)
y [Lovely](https://github.com/ethangreen-dev/lovely-injector/releases/tag/v0.10.0).

Transformaciones explícitas del paquete en `build._bundled_mods()`:

- LF para Lua/TOML; desactivar solicitudes de volcados Lua en manifests.
- Omitir los reemplazos de UI `deck_skins.toml` y `blind_ui.toml`, que chocan
  con el selector completo de Deck 1 y el HUD portrait ya existentes.
- Excluir del escaneo de metadatos la carpeta de diagnósticos `Mods/lovely`:
  Lovely 0.10 genera JSON de mapas de código que no son metadatos de mods.
- SHA-256 por paquete y sello escrito al terminar la copia.

`src/portrait_mods.lua` instala en la identidad anterior `game`, recarga los
patches antes de `main.lua` y precarga los módulos originales del loader que
Lovely solo registra automáticamente cuando ya existían al arrancar.
`src/portrait_smods.lua` conserva HUD, selector y sprites de Deck 1 después de
los overrides del loader. Los sprites de Jokers continúan usando SMODS.Atlas.

`src/portrait_save_migration.lua` adapta partidas anteriores sin Steamodded:
añade campos nuevos de puntuación, límites, ediciones y vales sin reiniciar la
semilla, dinero, niveles ni cartas. Guarda primero una copia binaria intacta
`<perfil>/save.pre-steamodded.jkr`. Los guardados nuevos no vuelven a migrarse.

Lovely informa de 11 patrones de UI/escritorio sin coincidencia en esta copia
portrait: Steam y comentarios de arranque; tooltip/alerta de escritorio;
texto demo de reversos; etiquetas de límites de mano; contador y ordenación
de áreas ya adaptadas. Se mantienen las implementaciones portrait. El patrón
propio de tienda sí coincide; sus exclusiones y tirada se prueban en ejecución.
No se afirma compatibilidad universal con otros mods no incluidos.
