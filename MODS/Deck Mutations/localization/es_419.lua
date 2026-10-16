local L={['misc']={['dictionary']={['k_dm_choose']='Elige un modificador',['k_dm_deep_pockets']='Bolsillos profundos',['k_dm_second_chance']='Segunda oportunidad',['k_dm_loose_hands']='Manos sueltas',['k_dm_interest_rate']='Techo Alto',['k_dm_heavy_hearts']='Corazones pesados',['k_dm_sharp_spades']='Picas afiladas',['k_dm_royal_blood']='Sangre real',['k_dm_low_life']='Bajos fondos',['k_dm_bigger_pockets']='Doble Fondo',['k_dm_enhanced_genetics']='Mutagénesis',['k_dm_lucky_deck']='Baraja afortunada',['k_dm_joker_habitat']='Hábitat de Jokers'}},['descriptions']={['Other']={['dm_deep_pockets']={['name']='Bolsillos profundos',['text']={'+1 tamaño de mano'}},['dm_second_chance']={['name']='Segunda oportunidad',['text']={'+1 mano por ciega'}},['dm_loose_hands']={['name']='Manos sueltas',['text']={'+1 descarte por ciega'}},['dm_interest_rate']={['name']='Techo Alto',['text']={'+$#1# al máximo de interés'}},['dm_heavy_hearts']={['name']='Corazones pesados',['text']={'Corazones puntuados: +#1# fichas'}},['dm_sharp_spades']={['name']='Picas afiladas',['text']={'Picas puntuadas: +#1# multi'}},['dm_royal_blood']={['name']='Sangre real',['text']={'J, Q y K puntuadas: +#1# fichas'}},['dm_low_life']={['name']='Bajos fondos',['text']={'2, 3, 4 y 5 puntuados: +#1# multi'}},['dm_bigger_pockets']={['name']='Doble Fondo',['text']={'+1 espacio de consumible'}},['dm_enhanced_genetics']={['name']='Mutagénesis',['text']={'#1#% de mejorar cartas básicas nuevas','de efectos de creación compatibles'}},['dm_lucky_deck']={['name']='Baraja afortunada',['text']={'+#1#% a probabilidades favorables','Solo cartas de suerte y Rueda de la Fortuna'}},['dm_joker_habitat']={['name']='Hábitat de Jokers',['text']={'+1 espacio de Joker'}}}}}
L.misc.dictionary.k_dm_steady_clubs='Tréboles firmes'
L.descriptions.Other.dm_steady_clubs={name='Tréboles firmes',text={'Tréboles puntuados: +#1# multi'}}
L.misc.dictionary.k_dm_diamond_reserve='Reserva de diamantes'
L.descriptions.Other.dm_diamond_reserve={name='Reserva de diamantes',text={'Diamantes puntuados: +#1# fichas'}}
L.misc.dictionary.k_dm_ace_up_sleeve='As en la manga'
L.descriptions.Other.dm_ace_up_sleeve={name='As en la manga',text={'Ases puntuados: +#1# fichas'}}
L.misc.dictionary.k_dm_boss_dividend='Dividendo del jefe'
L.descriptions.Other.dm_boss_dividend={name='Dividendo del jefe',text={'Gana $#1# al superar cada ciega jefe'}}


L.misc.dictionary.k_dm_overload="Sobrecarga"
L.descriptions.Other.dm_overload={name="Sobrecarga",text={"Primera mano de cada ciega: +100 fichas","Pierde 20 por mano posterior, mínimo 0"}}

L.misc.dictionary.k_dm_resonance="Resonancia"
L.descriptions.Other.dm_resonance={name="Resonancia",text={"Cartas puntuadas consecutivas del mismo palo:","la segunda recibe +4 multi","Wild respeta los palos; repeticiones no avanzan la cadena"}}

L.misc.dictionary.k_dm_chain_reaction="Reacción en Cadena"
L.descriptions.Other.dm_chain_reaction={name="Reacción en Cadena",text={"Cada carta puntuada: +10 fichas para la siguiente","Secuencia por mano: +0, +10, +20, +30...","Las repeticiones reutilizan el bonus, sin avanzar"}}
return L
