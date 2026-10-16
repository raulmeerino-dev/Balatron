local L={
    descriptions={Joker={
        j_incj_options={name='Options',text={
            'Dos efectos nuevos cada {C:attention}mano{}',
            '{C:red}A:{} #1#',
            '{C:blue}B:{} #2#',
            'Activa: {C:attention}#3#{}'}},
        j_incj_olympico={name='Olímpico',text={
            'Gana {X:mult,C:white}+#1#{} a su X Multi por',
            'cada {C:attention}récord consecutivo{} de',
            'una mano en esta run',
            'Vuelve a {X:mult,C:white}X1{} si no bate el récord',
            '{C:inactive}(Racha #3#: {X:mult,C:white}X#2#{C:inactive} Multi)'}},
        j_incj_tax_collector={name='Recaudador',text={
            'Gana {C:mult}+#1#{} Multi por',
            'cada {C:attention}Overkill{} conseguido',
            '{C:inactive}(Actualmente {C:mult}+#2#{C:inactive} Multi)'}},
        j_incj_hipster={name='Hipster',text={
            '{X:mult,C:white}X#1#{} Multi si la mano es',
            'de las {C:attention}menos jugadas{} de la run',
            '{C:inactive}(Incluye 0 usos; antes de jugarla)'}},
        j_incj_world_record={name='Récord Mundial',text={
            'Gana {C:mult}+#1#{} Multi al batir el',
            '{C:attention}récord de una mano{} de esta run',
            '{C:inactive}(Actualmente {C:mult}+#2#{C:inactive} Multi)'}},
        j_incj_excessive_force={name='Exceso de Fuerza',text={
            'Gana {X:mult,C:white}+#1#{} a su X Multi',
            'por cada {C:attention}Overkill de ×10{} o más',
            '{C:inactive}(Actualmente {X:mult,C:white}X#2#{C:inactive} Multi)'}},
        j_incj_collector={name='Coleccionista',text={
            '{C:mult}+#1#{} Multi por cada tipo distinto',
            'de {C:attention}mejora{}, {C:attention}sello{}, {C:attention}edición{}',
            'o {C:attention}sticker{} presente en la baraja',
            '{C:inactive}(#3# tipos: {C:mult}+#2#{C:inactive} Multi)'}},
    j_incj_compound_interest={name='Interés compuesto',text={
        'Gana {X:mult,C:white}+#1#{} a su factor',
        'de {C:mult}X Multi{} por {C:attention}ronda ganada{}',
        '{C:inactive}(Actualmente {X:mult,C:white}X#2#{C:inactive} Multi)'
    }}}},
    misc={dictionary={k_incj_doubles='Dobles',
            k_incj_options_pending='En la próxima mano',k_incj_options_chips='Fichas',k_incj_options_interest='Interés',k_incj_next_run='Cambios en la siguiente partida',k_incj_up='¡Aumenta!',k_incj_ultra='Ultra raro'},v_dictionary={
        a_incj_olympico_up='OLÍMPICO X#1# > X#2#',
        a_incj_olympico_reset='Olímpico X#2#'}}
}
L.descriptions.Joker.j_incj_sniper={name="Francotirador",text={"Gana {X:mult,C:white}X0.25{} permanentemente","al ganar con un total entre el","{C:attention}100% y 110%{} del objetivo","{C:inactive}(Actualmente {X:mult,C:white}X#1#{C:inactive} Multi)"}}
L.descriptions.Joker.j_incj_second_course={name="Segundo Plato",text={"{C:mult}+25{} Multi la {C:attention}segunda{} vez","que juegas cada tipo de mano","durante una misma {C:attention}ciega{}"}}
L.misc.v_text=L.misc.v_text or {}
L.misc.v_text.ch_c_incj_options_anchored={"Options queda anclado permanentemente a tu zona de Jokers."}
L.descriptions.Joker.j_incj_color_call={name='Todo al Color',text={
    '{C:red}ROJO:{} Corazones y Rombos',
    '{C:attention}NEGRO:{} Picas y Tréboles',
    'Cada carta del color elegido',
    'que puntúa otorga {C:mult}+#1#{} Multi',
    'Modo: {C:attention}#2#{}'}}
L.descriptions.Joker.j_incj_double_entry={name='Doble Entrada',text={
    '{C:red}DÉBITO:{} {C:mult}+#1#{} Multi',
    'Cuesta {C:money}$#2#{} por mano jugada',
    '{C:green}CRÉDITO:{} ganas {C:money}$#3#{}',
    'al terminar la ciega',
    'Modo: {C:attention}#4#{}'}}
L.misc.dictionary.k_incj_red='ROJO'
L.misc.dictionary.k_incj_black='NEGRO'
L.misc.dictionary.k_incj_debit='DÉBITO'
L.misc.dictionary.k_incj_credit='CRÉDITO'
L.misc.dictionary.k_incj_double_choose='A elegir'
L.descriptions.Other=L.descriptions.Other or {}
L.descriptions.Other.incj_double_controls={name='Dobles',text={
    '{C:attention}Toca{} para cambiar de modo',
    '{C:attention}Mantén pulsado{} para ver detalles',
    'No se puede cambiar al puntuar'}}

-- Shared native tooltip sections; mechanical localization remains available.
L.descriptions.Joker.j_incj_options_tooltip={name=L.descriptions.Joker.j_incj_options.name,text={L.descriptions.Joker.j_incj_options.text[1]}}
L.descriptions.Joker.j_incj_color_call_tooltip={name=L.descriptions.Joker.j_incj_color_call.name,text={}}
L.descriptions.Joker.j_incj_double_entry_tooltip={name=L.descriptions.Joker.j_incj_double_entry.name,text={}}
L.descriptions.Other.incj_color_red={name='',text={"Los {C:hearts}Corazones{} y {C:diamonds}Diamantes{}","que puntúan dan {C:mult}+#1#{} Multi cada uno"}}
L.descriptions.Other.incj_color_black={name='',text={"Las {C:spades}Picas{} y los {C:clubs}Tréboles{}","que puntúan dan {C:mult}+#1#{} Multi cada uno"}}
L.descriptions.Other.incj_entry_debit={name='',text={"{C:mult}+#1#{} Multi","Cuesta {C:money}$#2#{} por mano jugada"}}
L.descriptions.Other.incj_entry_credit={name='',text={"Gana {C:money}$#3#{} al","final de la ciega"}}
L.misc.dictionary.k_incj_mode_a='MODO A'
L.misc.dictionary.k_incj_mode_b='MODO B'
-- Mission-gated Jokers: native descriptions and locked unlock text.
L.descriptions.Joker.j_incj_graft={["name"]="Injerto",["text"]={"El primer descarte de {C:attention}1 carta mejorada{}","de cada ciega guarda su mejora","Tras puntuar, la aplica a la primera","carta puntuada {C:attention}sin mejora{}","No copia palo, rango, sello ni edición","{C:inactive}(Guardada: #1#)"},["unlock"]={"Puntúa cartas con {C:attention}3 mejoras distintas{}","en una misma mano"}}
L.descriptions.Joker.j_incj_intermission={["name"]="Entreacto",["text"]={"El {C:attention}primer consumible{} usado","durante cada ciega recupera","{C:blue}+1 mano{} y {C:red}+1 descarte{}"},["unlock"]={"Usa {C:attention}5 consumibles{} durante","ciegas en una misma partida"}}
L.misc.dictionary.k_incj_no_imprint="Ninguna"
L.misc.dictionary.k_incj_imprinted="Guardada"
L.misc.dictionary.k_incj_grafted="¡Injerto!"
L.misc.dictionary.k_incj_intermission="¡Entreacto!"
-- Approved 48-piece expansion. Native unlock descriptions stay hidden until eligible.
L.descriptions.Joker.j_incj_backstage={["name"]="Entre bastidores",["text"]={"En cada tienda, aparta hasta {C:attention}5 cartas{}","del mazo durante la siguiente ciega","Vuelven al terminarla","{C:inactive}(Reservadas: #1# · seleccionar, Acción)"},["unlock"]={"Gana una run con 35 cartas o menos sin","haber añadido ninguna playing card nueva al","mazo durante la run."}}
L.descriptions.Joker.j_incj_pendulum={["name"]="Péndulo",["text"]={"{C:red}A:{} puntúa {C:attention}0{} y guarda los {C:chips}Chips{} finales","{C:blue}B:{} suma los {C:chips}Chips{} guardados y vacía la reserva","{C:inactive}(Reserva: #1# · Modo #2#)"},["unlock"]={"En un mismo Boss de Ante 6 o superior,","juega una mano de como máximo el 1% del","objetivo y después una de al menos el doble","del objetivo."}}
L.descriptions.Joker.j_incj_between_lines={["name"]="Entre líneas",["text"]={"Las cartas jugadas que {C:attention}no puntúan{}","activan sus efectos de {C:attention}carta mantenida{}","durante la puntuación"},["unlock"]={"Vence un Boss de Ante 6 o superior con High","Card jugando cinco cartas y manteniendo","tres Steel en mano."}}
L.descriptions.Joker.j_incj_thumbtack={["name"]="Chincheta",["text"]={"Tras una mano, fija {C:attention}1 carta puntuante{}","superviviente para jugarla en la siguiente","Ocupa plaza; selecciona este Joker para liberarla"},["unlock"]={"Vence tres Boss consecutivos con el mismo","Rey físico formando parte de sus manos","ganadoras."}}
L.descriptions.Joker.j_incj_extra_time={["name"]="Prórroga",["text"]={"Al alcanzar el objetivo puedes","{C:attention}seguir jugando{} con tus recursos restantes","Selecciona este Joker para cobrar"},["unlock"]={"Vence un Boss de Ante 6 o superior en tu","última mano y con Overkill de al menos 10."}}
L.descriptions.Joker.j_incj_barterer={["name"]="Mercachifle",["text"]={"Una vez por tienda, {C:attention}intercambia{} un Joker","propio por uno de tienda de rareza igual o menor","Sin dinero ni disparadores de compra o venta"},["unlock"]={"Entre dos Boss consecutivos renueva al","menos tres Jokers mediante compras y ventas","con un gasto neto máximo de $6 y vence el","segundo Boss, de Ante 6 o superior."}}
L.descriptions.Joker.j_incj_castling={["name"]="Enroque",["text"]={"Una vez por ciega, {C:attention}intercambia los rangos{}","de dos cartas de tu mano","Conserva sus demás propiedades"},["unlock"]={"Convierte tres Ases físicos distintos en","doses con Strength y vence después un Boss","de Ante 6 o superior con un Three of a Kind","de doses que los incluya."}}
L.descriptions.Joker.j_incj_lightning_rod={["name"]="Pararrayos",["text"]={"La carta puntuante {C:attention}más a la izquierda{}","recibe las repeticiones extra de las","demás cartas jugadas"},["unlock"]={"Haz que una sola carta puntúe seis veces en","la mano ganadora de un Boss de Ante 6 o","superior."}}
L.descriptions.Joker.j_incj_last_performance={["name"]="Última función",["text"]={"Los Jokers que se autodestruyen conservan","su último estado útil hasta terminar","la {C:attention}siguiente ciega seleccionada{}"},["unlock"]={"Vence un Boss de Ante 6 o superior después","de perder dos Jokers por autodestrucción","durante ese Ante."}}
L.descriptions.Joker.j_incj_promissory_note={["name"]="Letra de cambio",["text"]={"Al completar un {C:attention}Contract{}, elige su premio","o el tipo de premio original del","{C:attention}Contract anterior{} que completaste"},["unlock"]={"Completa tres Contracts distintos que","entreguen tres tipos de recompensa","diferentes, sin fallar ninguno entre ellos,","y vence después un Boss de Ante 6 o","superior."}}
L.descriptions.Joker.j_incj_broken_record={["name"]="Disco rayado",["text"]={"Cada carta reutiliza sus primeros","{C:attention}resultados de azar de Lucky y Glass{}","durante toda la ciega"},["unlock"]={"En una mano ganadora de Boss, activa Lucky","al menos ocho veces y cobra al menos $40","por esas activaciones."}}
return L
