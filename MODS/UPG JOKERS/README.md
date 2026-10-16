# Upgraded Jokers

Mods → Upgraded Jokers → Config: familia ON/OFF y controles por Joker.
Los controles afectan a la siguiente partida y nunca descargan las definiciones.
Las partidas anteriores a este mod conservan la generación UPG desactivada.

Metamorphosis es una entrada de colección: Larva (+10, 4 ciegas ganadas),
Chrysalis (X1.5, otras 4), Moth (X3). Estado en `ability.extra`; progreso una
vez por ciega jugada y ganada. Copias físicas heredan el estado con tablas propias;
Blueprint/Brainstorm solo copian puntuación. Precio $8, venta base $4 en todas
las fases; la evolución no altera el cálculo normal de descuentos/ediciones.

Parámetros en `config.lua`. Peso de rareza 0.01 frente a 0.7/0.25/0.05 vanilla:
aproximadamente 0.9901% por selección aleatoria de rareza de Joker cuando todos
los pools son elegibles; ~0.9802% por oferta normal de Joker después del 1% de
Compound Interest. No es un porcentaje por hueco total de tienda. Bans, duplicados,
modificadores de rareza y otros mods pueden modificar la probabilidad efectiva.

Para otro UPG: definición de etapas + registro en `main.lua`, atlas y traducciones.
El registro, controles y snapshot son compartidos; `core/evolution.lua` gestiona
el progreso por ciega ganada. Originales intactos en `METAMORPHOSIS/`; atlas
definitivos en `assets/1x/` y `assets/2x/`. Regenerar con
`python tools/build_upgraded_art.py` desde `balatron`.
