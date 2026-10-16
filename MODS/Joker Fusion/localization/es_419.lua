local L={descriptions={Joker={
    j_fuse_midas={name='Midas',text={'{X:mult,C:white}X#1#{} multi','Tras cada ciega superada:','{C:money}$#2#{} por cada {C:money}$#3#{} que tengas, máximo {C:money}$#4#{}'}},
    j_fuse_banana_cannon={name='Cañón Banana',text={'{X:mult,C:white}X#1#{} multi','Tras ganar: {C:green}1 de #2#{} de destruirse;','{C:green}1 de #3#{} si ganas','con la primera mano'}},
    j_fuse_glitch={name='Glitch',text={'{C:attention}???{}','Revela un efecto aleatorio nuevo','al comenzar cada ciega'}},
    j_fuse_glitch_revealed={name='Glitch',text={'Esta ciega: {C:mult}+#1#{} multi,','{X:mult,C:white}X#2#{} multi, {C:chips}+#3#{} fichas','Cambia en la próxima ciega'}},
    j_fuse_last_meal={name='Última Cena',text={'{X:mult,C:white}X#1#{} multi','Pierde {X:mult,C:white}X#2#{} por ciega superada,','hasta {X:mult,C:white}X#3#{}; cada consumible','recupera {X:mult,C:white}X#4#{}, máximo {X:mult,C:white}X#5#{}'}},
}},misc={dictionary={k_fuse_fusion='FUSION',k_fuse_complete='¡FUSIÓN!',k_fuse_revealed='¡Revelado!',
    k_fuse_available='¡FUSIÓN DISPONIBLE!',k_fuse_available_heading='FUSIONES DISPONIBLES',k_fuse_owned_heading='COMPLETADAS · POSEÍDAS',k_fuse_confirm='¿Fusionar estos dos Jokers?',b_fuse_action='FUSIONAR',k_fuse_none='Sin pareja disponible. Fusiona en la tienda.',
    k_fuse_collection='Fusiones',b_fuse_yes='Sí, fusionar',b_fuse_no='No',
    k_fuse_inherit='Ediciones distintas: gana la primera. Contadores a cero.',
}}}
L.descriptions.Joker.j_fuse_broken_copier={name="Fotocopiadora Rota",text={"Copia valores numéricos {C:attention}compatibles{}","del Joker situado a su {C:attention}derecha{}","Eficiencia: {C:attention}#1#%{} ({C:inactive}#2#{})","{C:attention}+10%{} por jefe superado, máximo 100%","XMulti escala su parte por encima de X1","Dinero redondeado hacia abajo"}}
L.misc.dictionary.k_fuse_choose='Elige una Fusion'
L.misc.dictionary.k_fuse_reward='Joker de recompensa pendiente'
return L
