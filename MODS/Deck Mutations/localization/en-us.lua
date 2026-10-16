local L={['misc']={['dictionary']={['k_dm_choose']='Choose a Modifier',['k_dm_deep_pockets']='Deep Pockets',['k_dm_second_chance']='Second Chance',['k_dm_loose_hands']='Loose Hands',['k_dm_interest_rate']='High Ceiling',['k_dm_heavy_hearts']='Heavy Hearts',['k_dm_sharp_spades']='Sharp Spades',['k_dm_royal_blood']='Royal Blood',['k_dm_low_life']='Low Life',['k_dm_bigger_pockets']='False Bottom',['k_dm_enhanced_genetics']='Mutagenesis',['k_dm_lucky_deck']='Lucky Deck',['k_dm_joker_habitat']='Joker Habitat'}},['descriptions']={['Other']={['dm_deep_pockets']={['name']='Deep Pockets',['text']={'+1 hand size'}},['dm_second_chance']={['name']='Second Chance',['text']={'+1 hand each Blind'}},['dm_loose_hands']={['name']='Loose Hands',['text']={'+1 discard each Blind'}},['dm_interest_rate']={['name']='High Ceiling',['text']={'+$#1# maximum interest'}},['dm_heavy_hearts']={['name']='Heavy Hearts',['text']={'Scoring Hearts give +#1# Chips'}},['dm_sharp_spades']={['name']='Sharp Spades',['text']={'Scoring Spades give +#1# Mult'}},['dm_royal_blood']={['name']='Royal Blood',['text']={'Scoring J, Q, K give +#1# Chips'}},['dm_low_life']={['name']='Low Life',['text']={'Scoring 2, 3, 4, 5 give +#1# Mult'}},['dm_bigger_pockets']={['name']='False Bottom',['text']={'+1 consumable slot'}},['dm_enhanced_genetics']={['name']='Mutagenesis',['text']={'#1#% chance to enhance new basic cards','from compatible creation effects'}},['dm_lucky_deck']={['name']='Lucky Deck',['text']={'+#1#% to compatible favorable chances','Lucky cards and Wheel of Fortune only'}},['dm_joker_habitat']={['name']='Joker Habitat',['text']={'+1 Joker slot'}}}}}
L.misc.dictionary.k_dm_steady_clubs='Steady Clubs'
L.descriptions.Other.dm_steady_clubs={name='Steady Clubs',text={'Scored Clubs: +#1# Mult'}}
L.misc.dictionary.k_dm_diamond_reserve='Diamond Reserve'
L.descriptions.Other.dm_diamond_reserve={name='Diamond Reserve',text={'Scored Diamonds: +#1# chips'}}
L.misc.dictionary.k_dm_ace_up_sleeve='Ace Up the Sleeve'
L.descriptions.Other.dm_ace_up_sleeve={name='Ace Up the Sleeve',text={'Scored Aces: +#1# chips'}}
L.misc.dictionary.k_dm_boss_dividend='Boss Dividend'
L.descriptions.Other.dm_boss_dividend={name='Boss Dividend',text={'Earn $#1# after each Boss Blind'}}


L.misc.dictionary.k_dm_overload="Overload"
L.descriptions.Other.dm_overload={name="Overload",text={"First hand of each Blind: +100 chips","Loses 20 per later hand, minimum 0"}}

L.misc.dictionary.k_dm_resonance="Resonance"
L.descriptions.Other.dm_resonance={name="Resonance",text={"Consecutive scored cards sharing a suit:","the second receives +4 Mult","Wild respects suits; retriggers do not advance the chain"}}

L.misc.dictionary.k_dm_chain_reaction="Chain Reaction"
L.descriptions.Other.dm_chain_reaction={name="Chain Reaction",text={"Each scored card: +10 chips for the next","Sequence per hand: +0, +10, +20, +30...","Retriggers reuse the bonus without advancing"}}
return L
