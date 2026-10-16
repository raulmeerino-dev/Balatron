local L={
    descriptions={Joker={
        j_upg_bottomless={name='Bottomless',text={
            '{C:attention}Hungry{} → {C:attention}Starving{} → {C:attention}Devourer{}',
            'Grows when playing cards are destroyed',
            'Evolves after {C:attention}#4#{} then {C:attention}#6#{} more cards'}},
        j_upg_hungry={name='Hungry Joker',text={
            'Gains {C:mult}+#1#{} Mult for each', 'playing card destroyed',
            'Currently {C:mult}+#2#{} Mult', 'Devoured: {C:attention}#3#/#4#{}'}},
        j_upg_starving={name='Starving Joker',text={
            'Gains {C:mult}+#1#{} Mult for each', 'playing card destroyed',
            'Currently {C:mult}+#2#{} Mult', 'Devoured: {C:attention}#3#/#4#{}'}},
        j_upg_devourer={name='Devourer',text={
            'Gains {C:mult}+#1#{} Mult for each', 'playing card destroyed',
            'Currently {C:mult}+#2#{} Mult', '{X:mult,C:white}X#5#{} Mult', '{C:attention}Final Form{}'}},
        j_upg_metamorphosis={name='Metamorphosis',text={
            '{C:mult}+#1#{} Mult', '{C:attention}Larva{} → {C:attention}Chrysalis{} → {C:attention}Moth{}',
            'Evolves after {C:attention}#3#{} won rounds per stage'}},
        j_upg_larva={name='Larva',text={'{C:mult}+#1#{} Mult','{C:attention}Metamorphosis{}','{C:attention}#2#/#3#{} rounds'}},
        j_upg_chrysalis={name='Chrysalis',text={'{X:mult,C:white}X#1#{} Mult','{C:attention}Metamorphosis{}','{C:attention}#2#/#3#{} rounds'}},
        j_upg_moth={name='Moth',text={'{X:mult,C:white}X#1#{} Mult','{C:attention}Metamorphosis{}','{C:attention}Final Form{}'}},
    }},
    misc={dictionary={k_upg_upgrade='UPGRADE!',k_upg_upgraded='UPGRADED',k_upg_next_run='Changes apply to the next run'},labels={k_upg_upgraded='UPGRADED'}},
}
-- Mission-gated Jokers: native descriptions and locked unlock text.
L.descriptions.Joker.j_upg_wayfinder={["name"]="Wayfinder",["text"]={"Retriggers the {C:attention}first{} scoring card","Explore {C:attention}#2#{} hand types: first and last","Explore {C:attention}#3#{}: all scoring cards","{C:inactive}(Hand types explored: #1#)"},["unlock"]={"Play {C:attention}5 different poker hand types{}","within a single Ante"}}
L.descriptions.Joker.j_upg_orrery={["name"]="Orrery",["text"]={"Each {C:planet}Planet{} used gives {C:attention}+1 level{}","to {C:attention}#1#{} other lowest-level hands","Evolves after using {C:attention}#3#{} and {C:attention}#4#{} Planets","{C:inactive}(Planets used: #2#)"},["unlock"]={"Use {C:attention}4 different Planets{}","in a single run"}}
L.descriptions.Joker.j_upg_wayfinder_1={["name"]="Compass",["text"]={"Retriggers the first scoring card {C:attention}once{}","Evolves after exploring {C:attention}#2#{} hand types","{C:inactive}(Explored: #1#)"}}
L.descriptions.Joker.j_upg_wayfinder_2={["name"]="Chart",["text"]={"Retriggers first and last scoring cards {C:attention}once{}","Only once if they are the same card","Evolves at {C:attention}#3#{} hand types","{C:inactive}(Explored: #1#)"}}
L.descriptions.Joker.j_upg_wayfinder_3={["name"]="Horizon",["text"]={"Retriggers each scoring card {C:attention}once{}","{C:attention}Final form{}"}}
L.descriptions.Joker.j_upg_orrery_1={["name"]="Sextant",["text"]={"Each {C:planet}Planet{} gives {C:attention}+1 level{}","to {C:attention}#1#{} other lowest-level hands","{C:inactive}(Planets used: #2#)","Evolves after {C:attention}#3#{} Planets"}}
L.descriptions.Joker.j_upg_orrery_2={["name"]="Armillary",["text"]={"Each {C:planet}Planet{} gives {C:attention}+1 level{}","to {C:attention}#1#{} other lowest-level hands","{C:inactive}(Planets used: #2#)","Evolves after {C:attention}#4#{} Planets"}}
L.descriptions.Joker.j_upg_orrery_3={["name"]="Firmament",["text"]={"Each {C:planet}Planet{} gives {C:attention}+1 level{}","to {C:attention}#1#{} other lowest-level hands","{C:inactive}(Planets used: #2#)","{C:attention}Final form{}"}}
L.misc.dictionary.k_upg_orbits="Orbits aligned!"
L.descriptions.Joker.j_upg_spyglass_1={["name"]="Spyglass",["text"]={"Once per Blind, inspect and reorder","the {C:attention}top #1# cards{} of your deck","{C:inactive}(Distinct Blind uses: #2#)","Evolves after {C:attention}#3#{} Blinds"},["unlock"]={"Win two consecutive Boss Blinds with","Straight Flush as the winning hand."}}
L.descriptions.Joker.j_upg_spyglass_2={["name"]="Telescope",["text"]={"Once per Blind, inspect and reorder","the {C:attention}top #1# cards{} of your deck","{C:inactive}(Distinct Blind uses: #2#)","Evolves after {C:attention}#3#{} Blinds"},["unlock"]={"Win two consecutive Boss Blinds with","Straight Flush as the winning hand."}}
L.descriptions.Joker.j_upg_spyglass_3={["name"]="Observatory",["text"]={"Once per Blind, inspect and reorder","the {C:attention}top #1# cards{} of your deck","{C:inactive}(Distinct Blind uses: #2#)","{C:attention}Final form{}"},["unlock"]={"Win two consecutive Boss Blinds with","Straight Flush as the winning hand."}}
L.descriptions.Joker.j_upg_spyglass={["name"]="Spyglass",["text"]={"Inspect and reorder {C:attention}3 / 5 / 7{} top cards","once per Blind","Evolves after {C:attention}3 / 7{} distinct Blind uses"},["unlock"]={"Win two consecutive Boss Blinds with","Straight Flush as the winning hand."}}
return L
