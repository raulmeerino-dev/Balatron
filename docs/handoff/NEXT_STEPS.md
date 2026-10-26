# NEXT_STEPS — plan recomendado

Prioridades sugeridas según el estado comprobable, no preferencias conversacionales
que no están disponibles.

## P0 — preservar y verificar el árbol activo

1. El repo principal está publicado en GitHub. Preservar las instrucciones de
   `AGENTS.md`, revisar `git status` antes de editar y mantener `local-archive/`
   fuera de Git.
2. Revisar los diffs de los 11 cambios de mods ya confirmados en `9ab04cb`. La
   línea aparente incluye persistencia/preview
   de «Marked Card», aviso de unlock de Horizons, ajustes de Compound Interest y
   Deck Mutations. Confirmar el objetivo con el usuario si no está claro en la
   propia lógica antes de cambiar semántica. El checkout alternativo está en
   `local-archive/alternate-checkouts/balatro-portrait-mobile-codex-test-20261017/`;
   no integrarlo sin nueva instrucción del usuario.
3. Comparar `MODS/` con el contenido de mods que empaqueta `balatron/build.py` y
   verificar que `balatron/src/assets/`/atlas no es una copia divergente que
   necesite sincronización. No empaquetar IPA para este chequeo.
4. Aplicar comprobaciones acotadas permitidas: sintaxis de archivos Lua tocados,
   rutas/localizaciones/assets y coherencia del uso de `cb_choices`, checkpoint
   y callback `apply`. Seguir `AGENTS.md`; no lanzar pruebas largas.

## P1 — cerrar funcionalidad de mods en curso

1. Para «Marked Card», revisar persistencia tras guardar/reanudar y que el
   resultado mostrado es el mismo enhancement/sello aplicado; aclarar consumo
   de RNG, target eliminado, carta no elegible y preservación de edición.
2. Revisar traducciones EN/ES-ES/ES-419 del consumible y verificar que la UI
   mobile muestra preview legible sin solapar botones.
3. Verificar nuevo aviso de unlock Horizons con la firma/contrato de
   `create_UIBox_card_unlock`, sprite y definición de descripción en todos los
   tipos/categorías posibles.
4. Revisar cambios de Compound Interest/Deck Mutations uno por uno y preservar
   sus guardados/configuración.
5. Resolver inconsistencias de etiquetas de revisión (rc1/rc2/rc3) y ciclo del
   fondo (240 s/siete tonos frente a 480 s/14 paradas) entre el código y la
   documentación antes de publicar una release; no asumir qué lado está obsoleto.

## P2 — iPhone real (bloqueo de confianza importante)

Usar IPA disponible solo si corresponde y está presente; generar nueva IPA
únicamente tras orden explícita. Con instalación firmada, ejecutar el plan ya
registrado en `balatron/INFORME-PRUEBAS.md`:

1. Arranque, app separada, portrait, lock/unlock y suspensión/reanudación.
2. Diagnostics: drawable/canvas, nativeScale, safe-area, iOS y frecuencia máxima;
   confirmar notch/Dynamic Island, esquinas y home indicator.
3. Toque, multiselección, drag, swipes, cancelación, botones, tooltips, teclado,
   pantallas y menú de mods.
4. Completar una sesión, cerrar/reabrir, confirmar save, audio, memoria, calor,
   FPS sostenido y comportamiento de ProMotion.
5. Probar una actualización conservando identidad/firmado y backup de `game/`;
   verificar mod installer y partida antes de considerar exitosa.

## P3 — decidir si retomar arte de Deck 2/3

README local dice que Deck 2/3 están pendientes. Hay assets/fuentes en `DECK 2/`
y `DECK 3/`; guías y checkpoints pueden contener decisiones de generación.
No copiar/integrar automáticamente: inspeccionar manifests, completitud de
52 cartas/reverso, resolución/crops y licencias/procedencia, y pedir dirección
solo si hace falta para una elección de diseño.

## Dependencias

- Los P1 dependen de revisar la intención y compatibilidad de cambios de mods
  ya confirmados, no de un diff local pendiente.
- La prueba P2 depende de un dispositivo iOS y firma/instalación del usuario;
  el repositorio no certifica hardware.
- P3 es opcional y no bloquea desarrollo de mods.
- Actualizar esta lista y `CURRENT_STATE.md` cuando se resuelvan decisiones o
  cambie el status.
