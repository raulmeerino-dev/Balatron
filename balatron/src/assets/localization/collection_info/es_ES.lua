local categories={
    doubles={title='DOBLES',text={'Jokers con dos estados entre los','que puedes elegir durante la run.','','Cada carta mantiene su propia elección.','Consulta su descripción para conocer','los efectos de cada lado.'}},
    mutations={title='MUTATIONS',text={
        'Las Mutations cambian las reglas', 'de la run actual.', '',
        'Después de derrotar una Boss Blind,', 'puedes elegir una entre varias opciones.', '',
        'Pueden mejorar:', '- manos y descartes', '- cartas y palos', '- economía', '- slots', '- otras reglas de la run', '',
        'Las Mutations obtenidas duran hasta', 'que termina la partida.', '',
        'El contador indica las descubiertas.', 'Las desconocidas ocultan su identidad.',
        'Progresar en una mecánica revela', 'sus entradas bloqueadas. Mantén pulsado',
        'para consultar el requisito.', 'Solo las desbloqueadas entran en elecciones.',
        'Los desbloqueos se guardan por perfil;', 'sus avisos aparecen en el menú principal.'}},
    contraband={title='CONTRABAND',text={
        'Contraband son objetos especiales', 'que solo pueden encontrarse en', 'el Black Market.', '',
        'Al comprarlos producen efectos', 'especiales que no funcionan como', 'Jokers ni consumibles normales.', '',
        'Algunos tienen efectos inmediatos', 'y otros pueden durar parte de la run.', '',
        'Comprar Contraband aumenta Heat.'}},
    contracts={title='CONTRACTS',text={
        'Los Contracts son retos opcionales', 'que pueden aparecer durante una run.', '',
        'Puedes aceptar o rechazar cada contrato.', '',
        'Si cumples su objetivo recibes', 'la recompensa indicada.', '',
        'Normalmente solo puedes tener', 'un Contract activo a la vez.'}},
    extra={title='EXTRA JOKERS',text={
        'Jokers adicionales que se integran', 'en los pools normales del juego.', '',
        'Funcionan como Jokers estándar,', 'pero añaden nuevas mecánicas', 'y combinaciones posibles.'}},
    upg={title='UPGRADED JOKERS',text={
        'Los UPG Jokers pueden evolucionar', 'durante una run al cumplir', 'determinadas condiciones.', '',
        'Al evolucionar pueden cambiar:', '- sprite', '- nombre', '- efecto', '- estadísticas', '',
        'Cada UPG Joker tiene sus propios', 'requisitos de evolución.'}},
    risk={title='RISK JOKERS',text={
        'Jokers muy poderosos que incluyen', 'una desventaja o riesgo importante.', '',
        'Pueden ofrecer grandes multiplicadores', 'a cambio de:', '- dinero', '- tiempo', '- posibilidad de destruirse', '- condiciones especiales'}},
    fusion={title='FUSION JOKERS',text={
        'Algunas parejas concretas de Jokers', 'pueden fusionarse para crear', 'un Joker nuevo y exclusivo.', '',
        'Las recetas son inicialmente secretas.', '',
        'Una Fusion se descubre cuando', 'la realizas por primera vez.'}},
    skins={title='CARD SKINS',text={
        'Las skins cambian únicamente', 'el aspecto visual de las cartas.', '',
        'No modifican las reglas,', 'probabilidades ni puntuación.'}},
}
for _,data in pairs(categories) do data.close='Cerrar' end
return categories
