# Flujo de trabajo de este proyecto

- Antes de cambiar código, leer `docs/handoff/PROJECT_OVERVIEW.md`,
  `CURRENT_STATE.md`, `DECISIONS.md` y la guía específica del área. Estas notas
  documentan la estructura consolidada, el estado del árbol de trabajo y las
  limitaciones conocidas; comprobar siempre que siguen coincidiendo con el repo.
- El proyecto principal de iOS está en `balatron/`; las fuentes de mods locales
  que consume su build están en `MODS/`. No editar copias de prueba o entregas
  antiguas salvo petición explícita.
- `local-archive/` guarda checkouts alternativos locales y está excluido de Git.
  No trabajar desde ahí ni integrar/borrar su contenido salvo petición explícita.
- Implementar cambios directamente en fuentes y assets definitivos.
- No generar ni recompilar la IPA salvo petición explícita «Genera la IPA».
- Comprobar solo sintaxis, referencias, rutas, assets e integración evidente.
- No añadir suites, simulaciones largas, benchmarks, herramientas de debug ni informes extensos sin petición.
- Conservar los cambios anteriores y terminar con un resumen muy breve.
- No borrar, resetear, formatear ni sobrescribir cambios locales existentes. Antes
  de editar, revisar `git status` y los diffs de los archivos que se tocarán.
- Para la interfaz portrait, conservar comportamiento de escritorio y limitar los
  cambios a `G.F_PORTRAIT` cuando corresponda. Mantener compatibilidad con el
  guardado y los callbacks del juego; revisar las integraciones de Steamodded y
  Lovely en lugar de reemplazar funciones centrales sin necesidad.
- Los cambios de mods raíz se empaquetan desde `../MODS/` al ejecutar
  `balatron/build.py`; copiar manualmente un mod al árbol integrado puede dejar
  fuentes divergentes. Revisar `balatron/mods/README.md` y el flujo de build.
- Antes de cambiar un mod, consultar también `MODS/README.md` y
  `docs/handoff/MOD_CATALOG.md` para distinguir paquete, propietario, categoría,
  assets y claves persistentes. Mantener las rutas/IDs/keys salvo migración
  explícita y verificada.
- No dar por validado el funcionamiento en iPhone basándose en QA de escritorio,
  fixtures o empaquetado. La instalación y pruebas en hardware siguen pendientes.
- No incluir credenciales ni secretos en documentación. Actualizar la
  documentación de handoff cuando cambie de forma material el estado o las
  instrucciones del proyecto.

## Documentación de continuidad

- `docs/handoff/PROJECT_OVERVIEW.md`: mapa, arquitectura, toolchain y adaptación.
- `docs/handoff/CURRENT_STATE.md`: estado publicado, organización local,
  incertidumbres y próximos pasos.
- `docs/handoff/DECISIONS.md`: decisiones documentadas y motivos conocidos.
- `docs/handoff/IOS_AND_MODS.md`: particularidades de iOS, portrait y mods.
- `docs/handoff/DEVELOPMENT_GUIDE.md`: preparación y comandos de trabajo.
- `docs/handoff/NEXT_STEPS.md`: cola de continuación con prioridades.
- `docs/handoff/MOD_CATALOG.md`: inventario de mods, Jokers, fusiones, contenido,
  desbloqueos y rutas de sprites.
- `balatron/README-IOS-LOCAL.md`, `balatron/INFORME-PRUEBAS.md`,
  `balatron/CHANGELOG.md` y `balatron/mods/README.md` contienen detalles y
  evidencia de las iteraciones previas; consultar antes de cambiar esos sistemas.
