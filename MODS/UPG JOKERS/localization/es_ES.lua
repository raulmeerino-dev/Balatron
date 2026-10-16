local L={
    descriptions={Joker={
        j_upg_bottomless={name='Bottomless',text={
            '{C:attention}Hambriento{} → {C:attention}Famélico{} → {C:attention}Devorador{}',
            'Crece al destruir cartas de juego',
            'Evoluciona tras {C:attention}#4#{} y luego {C:attention}#6#{} cartas'}},
        j_upg_hungry={name='Joker Hambriento',text={
            'Gana {C:mult}+#1#{} multi por cada', 'carta de juego destruida',
            'Actual: {C:mult}+#2#{} multi', 'Devoradas: {C:attention}#3#/#4#{}'}},
        j_upg_starving={name='Joker Famélico',text={
            'Gana {C:mult}+#1#{} multi por cada', 'carta de juego destruida',
            'Actual: {C:mult}+#2#{} multi', 'Devoradas: {C:attention}#3#/#4#{}'}},
        j_upg_devourer={name='Devorador',text={
            'Gana {C:mult}+#1#{} multi por cada', 'carta de juego destruida',
            'Actual: {C:mult}+#2#{} multi', '{X:mult,C:white}X#5#{} multi', '{C:attention}Forma final{}'}},
        j_upg_metamorphosis={name='Metamorphosis',text={
            '{C:mult}+#1#{} multi', '{C:attention}Larva{} → {C:attention}Chrysalis{} → {C:attention}Moth{}',
            'Evoluciona cada {C:attention}#3#{} rondas ganadas'}},
        j_upg_larva={name='Larva',text={'{C:mult}+#1#{} multi','{C:attention}Metamorphosis{}','{C:attention}#2#/#3#{} rondas'}},
        j_upg_chrysalis={name='Chrysalis',text={'{X:mult,C:white}X#1#{} multi','{C:attention}Metamorphosis{}','{C:attention}#2#/#3#{} rondas'}},
        j_upg_moth={name='Moth',text={'{X:mult,C:white}X#1#{} multi','{C:attention}Metamorphosis{}','{C:attention}Forma final{}'}},
    }},
    misc={dictionary={k_upg_upgrade='¡EVOLUCIÓN!',k_upg_upgraded='MEJORADO',k_upg_next_run='Cambios para la siguiente partida'},labels={k_upg_upgraded='MEJORADO'}},
}
-- Mission-gated Jokers: native descriptions and locked unlock text.
L.descriptions.Joker.j_upg_wayfinder={["name"]="Cartógrafo",["text"]={"Reactiva la {C:attention}primera{} carta puntuada","Explora {C:attention}#2#{} tipos de mano: primera y última","Explora {C:attention}#3#{}: todas las puntuadas","{C:inactive}(Tipos explorados: #1#)"},["unlock"]={"Juega {C:attention}5 tipos de mano distintos{}","en una misma apuesta inicial"}}
L.descriptions.Joker.j_upg_orrery={["name"]="Astrolabio",["text"]={"Cada {C:planet}Planet{} usado sube {C:attention}1 nivel{}","a {C:attention}#1#{} otras manos de menor nivel","Evoluciona tras usar {C:attention}#3#{} y {C:attention}#4#{} Planets","{C:inactive}(Planets usados: #2#)"},["unlock"]={"Usa {C:attention}4 Planets distintos{}","en una misma partida"}}
L.descriptions.Joker.j_upg_wayfinder_1={["name"]="Brújula",["text"]={"Reactiva {C:attention}1 vez{} la primera carta puntuada","Evoluciona al explorar {C:attention}#2#{} tipos de mano","{C:inactive}(Explorados: #1#)"}}
L.descriptions.Joker.j_upg_wayfinder_2={["name"]="Carta Náutica",["text"]={"Reactiva {C:attention}1 vez{} la primera y última","carta puntuada (una sola vez si coinciden)","Evoluciona con {C:attention}#3#{} tipos de mano","{C:inactive}(Explorados: #1#)"}}
L.descriptions.Joker.j_upg_wayfinder_3={["name"]="Horizonte",["text"]={"Reactiva {C:attention}1 vez{} cada carta puntuada","{C:attention}Forma final{}"}}
L.descriptions.Joker.j_upg_orrery_1={["name"]="Sextante",["text"]={"Cada {C:planet}Planet{} da {C:attention}+1 nivel{}","a {C:attention}#1#{} otras manos de menor nivel","{C:inactive}(Planets usados: #2#)","Evoluciona a los {C:attention}#3#{} Planets"}}
L.descriptions.Joker.j_upg_orrery_2={["name"]="Armilar",["text"]={"Cada {C:planet}Planet{} da {C:attention}+1 nivel{}","a {C:attention}#1#{} otras manos de menor nivel","{C:inactive}(Planets usados: #2#)","Evoluciona a los {C:attention}#4#{} Planets"}}
L.descriptions.Joker.j_upg_orrery_3={["name"]="Firmamento",["text"]={"Cada {C:planet}Planet{} da {C:attention}+1 nivel{}","a {C:attention}#1#{} otras manos de menor nivel","{C:inactive}(Planets usados: #2#)","{C:attention}Forma final{}"}}
L.misc.dictionary.k_upg_orbits="¡Órbitas alineadas!"
L.descriptions.Joker.j_upg_spyglass_1={["name"]="Catalejo",["text"]={"Una vez por ciega, mira y reordena","las {C:attention}#1# cartas superiores{} del mazo","{C:inactive}(Usos en ciegas distintas: #2#)","Evoluciona tras {C:attention}#3#{} ciegas"},["unlock"]={"Vence dos Boss consecutivos con Straight","Flush como mano ganadora."}}
L.descriptions.Joker.j_upg_spyglass_2={["name"]="Telescopio",["text"]={"Una vez por ciega, mira y reordena","las {C:attention}#1# cartas superiores{} del mazo","{C:inactive}(Usos en ciegas distintas: #2#)","Evoluciona tras {C:attention}#3#{} ciegas"},["unlock"]={"Vence dos Boss consecutivos con Straight","Flush como mano ganadora."}}
L.descriptions.Joker.j_upg_spyglass_3={["name"]="Observatorio",["text"]={"Una vez por ciega, mira y reordena","las {C:attention}#1# cartas superiores{} del mazo","{C:inactive}(Usos en ciegas distintas: #2#)","{C:attention}Forma final{}"},["unlock"]={"Vence dos Boss consecutivos con Straight","Flush como mano ganadora."}}
L.descriptions.Joker.j_upg_spyglass={["name"]="Catalejo",["text"]={"Mira y reordena {C:attention}3 / 5 / 7{} cartas","superiores del mazo una vez por ciega","Evoluciona tras {C:attention}3 / 7{} ciegas distintas"},["unlock"]={"Vence dos Boss consecutivos con Straight","Flush como mano ganadora."}}
return L
