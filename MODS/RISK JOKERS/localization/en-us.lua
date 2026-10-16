local L={
    descriptions={Joker={
        j_risk_all_or_nothing={name='All or Nothing',text={
            '{X:mult,C:white}X#1#{} Mult on the',
            '{C:attention}first hand{} of each Blind',
            'If it does not defeat the Blind,',
            'permanently loses {X:mult,C:white}X#2#{} Mult',
            'Minimum: {X:mult,C:white}X#3#{} Mult'}},
        j_risk_russian_joker={name='Russian Joker',text={
            '{X:mult,C:white}X#1#{} Mult',
            '{C:green}#2#%{} chance to destroy itself',
            'after each defeated {C:attention}Blind{}'}},
        j_risk_burning_fuse={name='Burning Fuse',text={
            '{X:mult,C:white}X#1#{} Mult',
            'Loses {X:mult,C:white}X#2#{} after each',
            'defeated {C:attention}Blind{}, down to {X:mult,C:white}X#3#{}',
            'Destroys itself after winning',
            'a Blind at {X:mult,C:white}X#3#{}'}},
        j_risk_greed={name='Greed',text={
            '{X:mult,C:white}X#1#{} Mult',
            'Lose {C:money}$#2#{} for every',
            'hand that enters scoring'}},
        j_risk_glass_cannon={name='Glass Cannon',text={
            '{X:mult,C:white}X#1#{} Mult',
            'Destroys itself if your',
            '{C:attention}first hand{} does not',
            'defeat the {C:attention}Blind{}'}},
    }},
    misc={v_dictionary={a_risk_all_or_nothing_loss='X#1# > X#2#'},dictionary={
        k_risk_risk='RISK',k_risk_survived='Survived!',
        k_risk_missing_art='sprite pending',
        k_risk_next_run='Generation changes apply to the next run.',
    }},
}
L.descriptions.Joker.j_risk_loan_shark={name="Loan Shark",text={"{X:mult,C:white}X#1#{} Mult; charges {C:money}$#2#{}","after each defeated Blind","If unable to pay, permanently loses","{X:mult,C:white}X#3#{} Mult, minimum {X:mult,C:white}X#4#{}"}}
L.descriptions.Joker.j_risk_overheated={name="Overheated",text={"Starts each Blind at {X:mult,C:white}X3{} Mult","Loses {X:mult,C:white}X#2#{} after each played hand","Minimum {X:mult,C:white}X#3#{}, resets each Blind","{C:inactive}(Next hand: {X:mult,C:white}X#1#{C:inactive} Mult)"}}
-- Mission-gated Jokers: native descriptions and locked unlock text.
L.descriptions.Joker.j_risk_scorched_earth={["name"]="Scorched Earth",["text"]={"{X:mult,C:white}X#1#{} Mult","After each hand, destroy all","{C:attention}scoring cards{} that","are not protected"},["unlock"]={"Destroy {C:attention}12{} playing cards","in a single run"}}
L.descriptions.Joker.j_risk_powder_keg={["name"]="Powder Keg",["text"]={"{X:mult,C:white}X#1#{} Mult","Before {C:attention}every hand{}, double","the {C:attention}current Blind{} target","The increase lasts for that Blind"},["unlock"]={"Defeat a {C:attention}Boss{} on your last hand","with at least {C:attention}twice{}","its target score"}}
L.misc.dictionary.k_risk_target_doubled="Target X2"
return L
