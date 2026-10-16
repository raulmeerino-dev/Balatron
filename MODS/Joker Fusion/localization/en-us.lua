local L={descriptions={Joker={
    j_fuse_midas={name='Midas',text={'{X:mult,C:white}X#1#{} Mult','After each defeated Blind, earn','{C:money}$#2#{} per {C:money}$#3#{} held, up to {C:money}$#4#{}'}},
    j_fuse_banana_cannon={name='Banana Cannon',text={'{X:mult,C:white}X#1#{} Mult','After winning: {C:green}1 in #2#{} chance','to destroy itself; {C:green}1 in #3#{}','if won with your first hand'}},
    j_fuse_glitch={name='Glitch',text={'{C:attention}???{}','A new random effect is revealed','at the start of each Blind'}},
    j_fuse_glitch_revealed={name='Glitch',text={'This Blind: {C:mult}+#1#{} Mult,','{X:mult,C:white}X#2#{} Mult, {C:chips}+#3#{} Chips','Changes at the next Blind'}},
    j_fuse_last_meal={name='Last Meal',text={'{X:mult,C:white}X#1#{} Mult','Loses {X:mult,C:white}X#2#{} per defeated Blind,','down to {X:mult,C:white}X#3#{}; each consumable','restores {X:mult,C:white}X#4#{}, up to {X:mult,C:white}X#5#{}'}},
}},misc={dictionary={k_fuse_fusion='FUSION',k_fuse_complete='FUSION!',k_fuse_revealed='Revealed!',
    k_fuse_available='FUSION AVAILABLE!',k_fuse_available_heading='AVAILABLE FUSIONS',k_fuse_owned_heading='COMPLETED · OWNED',k_fuse_confirm='Fuse these two Jokers?',b_fuse_action='FUSE',k_fuse_none='No available pair. Fuse in the shop.',
    k_fuse_collection='Fusions',b_fuse_yes='Yes, fuse',b_fuse_no='No',
    k_fuse_inherit='Edition conflict: first component wins. Counters reset.',
}}}
L.descriptions.Joker.j_fuse_broken_copier={name="Broken Copier",text={"Copies {C:attention}compatible{} numeric effects","from the Joker to its {C:attention}right{}","Efficiency: {C:attention}#1#%{} ({C:inactive}#2#{})","{C:attention}+10%{} per Boss defeated, up to 100%","XMult scales the amount above X1","Money rounds down"}}
L.misc.dictionary.k_fuse_choose='Choose a Fusion'
L.misc.dictionary.k_fuse_reward='Pending Joker reward'
return L
