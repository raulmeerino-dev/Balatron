local L={
    descriptions={Joker={
        j_incj_options={name='Options',text={
            'Two new effects each {C:attention}hand{}',
            '{C:red}A:{} #1#',
            '{C:blue}B:{} #2#',
            'Active: {C:attention}#3#{}'}},
        j_incj_olympico={name='Olympian',text={
            'Gains {X:mult,C:white}+#1#{} to its X Mult for',
            'each {C:attention}consecutive single-hand{}',
            '{C:attention}record{} this run',
            'Resets to {X:mult,C:white}X1{} on a non-record hand',
            '{C:inactive}(Streak #3#: {X:mult,C:white}X#2#{C:inactive} Mult)'}},
        j_incj_tax_collector={name='Tax Collector',text={
            'Gains {C:mult}+#1#{} Mult for',
            'each {C:attention}Overkill{} achieved',
            '{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult)'}},
        j_incj_hipster={name='Hipster',text={
            '{X:mult,C:white}X#1#{} Mult if played hand is',
            'one of the {C:attention}least played{} this run',
            '{C:inactive}(Includes unplayed; before this play)'}},
        j_incj_world_record={name='World Record',text={
            'Gains {C:mult}+#1#{} Mult when beating',
            'this run\'s {C:attention}single-hand record{}',
            '{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult)'}},
        j_incj_excessive_force={name='Excessive Force',text={
            'Gains {X:mult,C:white}+#1#{} to its X Mult',
            'per {C:attention}Overkill of ×10{} or higher',
            '{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult)'}},
        j_incj_collector={name='Collector',text={
            '{C:mult}+#1#{} Mult for each distinct',
            '{C:attention}Enhancement{}, {C:attention}Seal{}, {C:attention}Edition{}',
            'or {C:attention}Sticker{} type in your deck',
            '{C:inactive}(#3# types: {C:mult}+#2#{C:inactive} Mult)'}},
    j_incj_compound_interest={name='Compound Interest',text={
        'Gains {X:mult,C:white}+#1#{} to its',
        '{C:mult}X Mult{} factor per {C:attention}round won{}',
        '{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult)'
    }}}},
    misc={dictionary={k_incj_doubles='Doubles',
            k_incj_options_pending='On the next hand',k_incj_options_chips='Chips',k_incj_options_interest='Interest',k_incj_next_run='Changes apply to the next run',k_incj_up='Upgrade!',k_incj_ultra='Ultra Rare'},v_dictionary={
        a_incj_olympico_up='OLYMPIAN X#1# > X#2#',
        a_incj_olympico_reset='Olympian X#2#'}}
}
L.descriptions.Joker.j_incj_sniper={name="Sniper",text={"Permanently gains {X:mult,C:white}X0.25{} Mult","when winning with a final total between","{C:attention}100% and 110%{} of the blind target","{C:inactive}(Currently {X:mult,C:white}X#1#{C:inactive} Mult)"}}
L.descriptions.Joker.j_incj_second_course={name="Second Course",text={"{C:mult}+25{} Mult the {C:attention}second{} time","each poker hand type is played","within the same {C:attention}Blind{}"}}
L.misc.v_text=L.misc.v_text or {}
L.misc.v_text.ch_c_incj_options_anchored={"Options is permanently anchored to your Joker slots."}
L.descriptions.Joker.j_incj_color_call={name='Color Call',text={
    '{C:red}RED:{} Hearts and Diamonds',
    '{C:attention}BLACK:{} Spades and Clubs',
    'Each scoring card of the',
    'chosen color gives {C:mult}+#1#{} Mult',
    'Mode: {C:attention}#2#{}'}}
L.descriptions.Joker.j_incj_double_entry={name='Double Entry',text={
    '{C:red}DEBIT:{} {C:mult}+#1#{} Mult',
    'Costs {C:money}$#2#{} per hand played',
    '{C:green}CREDIT:{} earn {C:money}$#3#{}',
    'at the end of the blind',
    'Mode: {C:attention}#4#{}'}}
L.misc.dictionary.k_incj_red='RED'
L.misc.dictionary.k_incj_black='BLACK'
L.misc.dictionary.k_incj_debit='DEBIT'
L.misc.dictionary.k_incj_credit='CREDIT'
L.misc.dictionary.k_incj_double_choose='Choose a mode'
L.descriptions.Other=L.descriptions.Other or {}
L.descriptions.Other.incj_double_controls={name='Doubles',text={
    '{C:attention}Tap{} to switch modes',
    '{C:attention}Hold{} to see details',
    'Cannot switch during scoring'}}

-- Shared native tooltip sections; mechanical localization remains available.
L.descriptions.Joker.j_incj_options_tooltip={name=L.descriptions.Joker.j_incj_options.name,text={L.descriptions.Joker.j_incj_options.text[1]}}
L.descriptions.Joker.j_incj_color_call_tooltip={name=L.descriptions.Joker.j_incj_color_call.name,text={}}
L.descriptions.Joker.j_incj_double_entry_tooltip={name=L.descriptions.Joker.j_incj_double_entry.name,text={}}
L.descriptions.Other.incj_color_red={name='',text={"Scored {C:hearts}Hearts{} and {C:diamonds}Diamonds{}","each give {C:mult}+#1#{} Mult"}}
L.descriptions.Other.incj_color_black={name='',text={"Scored {C:spades}Spades{} and {C:clubs}Clubs{}","each give {C:mult}+#1#{} Mult"}}
L.descriptions.Other.incj_entry_debit={name='',text={"{C:mult}+#1#{} Mult","Costs {C:money}$#2#{} per hand played"}}
L.descriptions.Other.incj_entry_credit={name='',text={"Earn {C:money}$#3#{} at","the end of the blind"}}
L.misc.dictionary.k_incj_mode_a='MODE A'
L.misc.dictionary.k_incj_mode_b='MODE B'
-- Mission-gated Jokers: native descriptions and locked unlock text.
L.descriptions.Joker.j_incj_graft={["name"]="Graft",["text"]={"The first discard of {C:attention}1 enhanced card{}","each Blind stores its enhancement","After scoring, applies it to the first","{C:attention}unenhanced{} scoring card","Does not copy rank, suit, seal or edition","{C:inactive}(Stored: #1#)"},["unlock"]={"Score cards with {C:attention}3 different enhancements{}","in a single hand"}}
L.descriptions.Joker.j_incj_intermission={["name"]="Intermission",["text"]={"The {C:attention}first consumable{} used","during each Blind restores","{C:blue}+1 hand{} and {C:red}+1 discard{}"},["unlock"]={"Use {C:attention}5 consumables{} during","Blinds in a single run"}}
L.misc.dictionary.k_incj_no_imprint="None"
L.misc.dictionary.k_incj_imprinted="Stored"
L.misc.dictionary.k_incj_grafted="Grafted!"
L.misc.dictionary.k_incj_intermission="Intermission!"
-- Approved 48-piece expansion. Native unlock descriptions stay hidden until eligible.
L.descriptions.Joker.j_incj_backstage={["name"]="Backstage",["text"]={"In each shop, set aside up to {C:attention}5 cards{}","from your deck for the next Blind","They return when the Blind ends","{C:inactive}(Reserved: #1# · select Joker, Action)"},["unlock"]={"Win a run with at most 35 cards and no","playing cards added during that run."}}
L.descriptions.Joker.j_incj_pendulum={["name"]="Pendulum",["text"]={"{C:red}A:{} score {C:attention}0{}, bank final {C:chips}Chips{}","{C:blue}B:{} add banked {C:chips}Chips{} and empty bank","{C:inactive}(Bank: #1# · Mode #2#)"},["unlock"]={"In one Ante 6+ Boss, play a hand scoring at","most 1% of its target, then one scoring at","least twice its target."}}
L.descriptions.Joker.j_incj_between_lines={["name"]="Between the Lines",["text"]={"Played cards that {C:attention}do not score{}","activate their {C:attention}held-in-hand{} effects","during scoring"},["unlock"]={"Win an Ante 6+ Boss with High Card, playing","five cards and holding three Steel cards."}}
L.descriptions.Joker.j_incj_thumbtack={["name"]="Thumbtack",["text"]={"After a hand, pin {C:attention}1 surviving scoring card{}","to play it again in the next hand","Uses a hand slot; select Joker to release"},["unlock"]={"Win three consecutive Boss Blinds with the","same physical King in each winning hand."}}
L.descriptions.Joker.j_incj_extra_time={["name"]="Extra Time",["text"]={"When you reach the target, choose to","{C:attention}keep playing{} with your remaining resources","Select this Joker to cash out when ready"},["unlock"]={"Win an Ante 6+ Boss on the last hand with","at least 10 times its target score."}}
L.descriptions.Joker.j_incj_barterer={["name"]="Barterer",["text"]={"Once per shop, {C:attention}trade{} one owned Joker","for a shop Joker of equal or lower rarity","No money, purchase or sale triggers"},["unlock"]={"Between consecutive Boss Blinds, replace at","least three Jokers through buying and","selling with at most $6 net spending; win","the second Boss at Ante 6+."}}
L.descriptions.Joker.j_incj_castling={["name"]="Castling",["text"]={"Once per Blind, {C:attention}swap the ranks{}","of two cards in your hand","Keep suits, enhancements, seals and editions"},["unlock"]={"Use Strength to turn three distinct Aces","into twos, then win an Ante 6+ Boss with a","Three of a Kind containing those three","twos."}}
L.descriptions.Joker.j_incj_lightning_rod={["name"]="Lightning Rod",["text"]={"The {C:attention}leftmost scoring card{} receives","all extra played-card retriggers","that belonged to your other played cards"},["unlock"]={"Trigger one card six times in the winning","hand of an Ante 6+ Boss."}}
L.descriptions.Joker.j_incj_last_performance={["name"]="Last Performance",["text"]={"Self-destructing Jokers keep their last","useful state until the end of the","{C:attention}next selected Blind{}"},["unlock"]={"Lose two Jokers to self-destruction in one","Ante, then win its Boss at Ante 6+."}}
L.descriptions.Joker.j_incj_promissory_note={["name"]="Promissory Note",["text"]={"On completing a {C:attention}Contract{}, choose its reward","or the original reward type of the","{C:attention}previous Contract{} you completed"},["unlock"]={"Complete three different Contracts with","three reward types and no failure between","them, then win an Ante 6+ Boss."}}
L.descriptions.Joker.j_incj_broken_record={["name"]="Broken Record",["text"]={"Each playing card reuses its first","{C:attention}Lucky and Glass random results{}","for the entire Blind"},["unlock"]={"In a winning Boss hand, trigger Lucky eight","times and earn at least $40 from those","activations."}}
return L
