local L={
    descriptions={Joker={
        j_risk_all_or_nothing={name='Todo o Nada',text={
            '{X:mult,C:white}X#1#{} multi en la',
            '{C:attention}primera mano{} de cada ciega',
            'Si no la derrota, pierde',
            '{X:mult,C:white}X#2#{} de forma permanente',
            'Mínimo: {X:mult,C:white}X#3#{} multi'}},
        j_risk_russian_joker={name='Joker Ruso',text={
            '{X:mult,C:white}X#1#{} multi',
            '{C:green}#2#%{} de probabilidad de destruirse',
            'tras cada {C:attention}ciega{} superada'}},
        j_risk_burning_fuse={name='Mecha Ardiente',text={
            '{X:mult,C:white}X#1#{} multi',
            'Pierde {X:mult,C:white}X#2#{} tras cada',
            '{C:attention}ciega{} superada, hasta {X:mult,C:white}X#3#{}',
            'Se destruye tras superar',
            'una ciega estando en {X:mult,C:white}X#3#{}'}},
        j_risk_greed={name='Codicia',text={
            '{X:mult,C:white}X#1#{} multi',
            'Pierdes {C:money}$#2#{} por cada',
            'mano que entra en puntuación'}},
        j_risk_glass_cannon={name='Cañón de Cristal',text={
            '{X:mult,C:white}X#1#{} multi',
            'Se destruye si tu',
            '{C:attention}primera mano{} no',
            'supera la {C:attention}ciega{}'}},
    }},
    misc={v_dictionary={a_risk_all_or_nothing_loss='X#1# > X#2#'},dictionary={
        k_risk_risk='RISK',k_risk_survived='¡Sobrevive!',
        k_risk_missing_art='sprite pendiente',
        k_risk_next_run='Los cambios se aplican en la siguiente partida.',
    }},
}
L.descriptions.Joker.j_risk_loan_shark={name="Préstamo Usurero",text={"{X:mult,C:white}X#1#{} Multi; cobra {C:money}$#2#{}","tras cada ciega superada","Si no puedes pagar, pierde {X:mult,C:white}X#3#{}","permanentemente, mínimo {X:mult,C:white}X#4#{}"}}
L.descriptions.Joker.j_risk_overheated={name="Sobrecalentado",text={"Empieza cada ciega con {X:mult,C:white}X3{} Multi","Pierde {X:mult,C:white}X#2#{} tras cada mano","Mínimo {X:mult,C:white}X#3#{}, se reinicia por ciega","{C:inactive}(Siguiente mano: {X:mult,C:white}X#1#{C:inactive} Multi)"}}
-- Mission-gated Jokers: native descriptions and locked unlock text.
L.descriptions.Joker.j_risk_scorched_earth={["name"]="Tierra Quemada",["text"]={"{X:mult,C:white}X#1#{} Multi","Al terminar cada mano, destruye","todas las cartas {C:attention}puntuadas{}","que no estén protegidas"},["unlock"]={"Destruye {C:attention}12{} cartas de juego","en una misma partida"}}
L.descriptions.Joker.j_risk_powder_keg={["name"]="Barril de Pólvora",["text"]={"{X:mult,C:white}X#1#{} Multi","Antes de {C:attention}cada mano{}, duplica","el objetivo de la {C:attention}ciega actual{}","El aumento dura toda la ciega"},["unlock"]={"Derrota a un {C:attention}jefe{} con tu última mano","alcanzando al menos {C:attention}el doble{}","de su puntuación objetivo"}}
L.misc.dictionary.k_risk_target_doubled="Objetivo X2"
return L
