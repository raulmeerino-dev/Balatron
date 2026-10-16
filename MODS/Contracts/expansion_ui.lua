return function(C,P)
    local X=require('portrait_expansion48')
    local function es() return (G.SETTINGS.language or ''):sub(1,2)=='es' end
    local function wrapped(nodes,text)
        for _,line in ipairs(require('portrait_tooltips').wrap({text},4.6,0.3)) do nodes[#nodes+1]=P.text(line,0.3) end
    end
    local function compact(label,callback,ref)
        local node=UIBox_button{label={label},button=callback,minw=1.25,minh=portrait_touch_height(0.7),scale=0.28}
        node.nodes[1].config.ref_table=ref;return node
    end
    local accept=G.FUNCS.ct_accept
    G.FUNCS.ct_accept=function(...)
        if C.state().offer~='debut' then return accept(...) end
        local nodes={P.text(es() and 'Puesta de largo' or 'Debut',0.45)}
        wrapped(nodes,es() and 'Reserva una mano sin jugar hasta el próximo Boss.' or 'Reserve an unplayed hand until the next Boss.')
        for _,option in ipairs(C.debut_hands()) do
            nodes[#nodes+1]=P.button(localize(option.hand,'poker_hands'),'ct48_debut',option.hand)
        end
        P.open(nodes,'ct48_debut_back')
    end
    G.FUNCS.ct48_debut=function(e)
        if C.state().offer=='debut' and C.accept(e.config.ref_table) then
            G.FUNCS.exit_overlay_menu();save_run();P.schedule_offers()
        end
    end
    G.FUNCS.ct48_debut_back=function() C.present_offer('debut',false) end
    function C.choose_witnesses(a)
        if not a.pending_choice then return end
        a.choice_ids=a.choice_ids or {}
        local count=0;for _ in pairs(a.choice_ids) do count=count+1 end
        local nodes={P.text(es() and 'Testigos protegidos' or 'Protected Witnesses',0.42)}
        wrapped(nodes,(es() and 'Elige tres cartas que permanecerán en tu mano. ' or 'Choose three cards to keep in hand. ')..count..' / 3')
        local cells={}
        for _,id in ipairs(a.initial_ids) do
            local card=X.find(id)
            if card and card.area==G.hand then
                local saved=card:save();local area=CardArea(0,0,1.1,1.5,{card_limit=1,type='title',highlight_limit=0})
                local preview=Card(0,0,G.CARD_W,G.CARD_H,G.P_CARDS.empty,card.config.center)
                saved=copy_table(saved);saved.added_to_deck=false;preview:load(saved);preview.added_to_deck=false;preview.ct_preview=true;area:emplace(preview)
                cells[#cells+1]={n=G.UIT.C,config={align='cm',padding=0.04},nodes={
                    {n=G.UIT.O,config={object=area}},compact(a.choice_ids[id] and '✓' or (es() and 'Elegir' or 'Choose'),
                        'ct48_witness_toggle',{uid=a.uid,id=id})}}
                if #cells==4 then nodes[#nodes+1]={n=G.UIT.R,config={align='cm'},nodes=cells};cells={} end
            end
        end
        if #cells>0 then nodes[#nodes+1]={n=G.UIT.R,config={align='cm'},nodes=cells} end
        if count==3 then nodes[#nodes+1]=P.button(es() and 'Confirmar' or 'Confirm','ct48_witness_confirm',a.uid) end
        P.open(nodes,'ct48_witness_wait')
    end
    local function witness(uid)
        for _,a in ipairs(C.active()) do if a.uid==uid and a.pending_choice then return a end end
    end
    G.FUNCS.ct48_witness_toggle=function(e)
        local ref=e.config.ref_table;local a=witness(ref.uid);if not a then return end
        local card=X.find(ref.id);if not card or card.area~=G.hand then return end
        local allowed=false;for _,id in ipairs(a.initial_ids) do if id==ref.id then allowed=true end end
        if not allowed then return end
        local count=0;for _ in pairs(a.choice_ids) do count=count+1 end
        if a.choice_ids[ref.id] then a.choice_ids[ref.id]=nil elseif count<3 then a.choice_ids[ref.id]=true end
        save_run();C.choose_witnesses(a)
    end
    G.FUNCS.ct48_witness_confirm=function(e)
        local a=witness(e.config.ref_table);if not a then return end
        local count=0
        for id in pairs(a.choice_ids) do local card=X.find(id);if not card or card.area~=G.hand then return end;count=count+1 end
        if count~=3 then return end
        a.protected=copy_table(a.choice_ids);a.choice_ids=nil;a.pending_choice=nil
        G.FUNCS.exit_overlay_menu();save_run()
    end
    G.FUNCS.ct48_witness_wait=function()
        for _,a in ipairs(C.active()) do if a.pending_choice then C.choose_witnesses(a);return end end
        G.FUNCS.exit_overlay_menu()
    end
    -- A pending mandatory choice blocks actions even after Escape or reload.
    local function guard(original)
        return function(...)
            for _,a in ipairs(C.active()) do if a.pending_choice then C.choose_witnesses(a);return end end
            local s=C.state()
            if s and s.reward_decisions and #s.reward_decisions>0 then C.open_rewards();return end
            return original(...)
        end
    end
    G.FUNCS.play_cards_from_highlighted=guard(G.FUNCS.play_cards_from_highlighted)
    G.FUNCS.discard_cards_from_highlighted=guard(G.FUNCS.discard_cards_from_highlighted)
    G.FUNCS.toggle_shop=guard(G.FUNCS.toggle_shop)
    local info=C.info
    function C.info(a,config)
        local def=C.entries[a.id]
        if not def or not def.expansion_id then return info(a,config) end
        local l=copy_table(C.expansion_text[a.id][es() and 'es' or 'en'])
        if a.target and a.target~=def.target_value then
            local replacements={embargo={'tres','three'},cash_register={'%$12','%$12'},domino_effect={'seis','six'},seed_capital={'%$8','%$8'}}
            local tokens=replacements[a.id]
            if tokens then
                local value=(a.id=='cash_register' or a.id=='seed_capital') and ('$'..a.target) or tostring(a.target)
                l.objective=l.objective:gsub(tokens[es() and 1 or 2],value)
                l.failure=l.failure:gsub(tokens[es() and 1 or 2],value)
            end
        end
        local secondary={}
        if a.progress~=nil then secondary[#secondary+1]=(es() and 'Progreso: ' or 'Progress: ')..a.progress..' / '..a.target end
        if a.selected_hand then secondary[#secondary+1]=localize(a.selected_hand,'poker_hands') end
        if a.targets or a.protected then
            for id in pairs(a.targets or a.protected) do
                local card=X.find(id)
                if card then
                    secondary[#secondary+1]=localize(card.base.value,'ranks')..' · '..localize(card.base.suit,'suits_plural')
                end
            end
        end
        return {title=l.name,class='Contract',text={l.objective,l.reward},secondary=secondary,sections={
            {title=es() and 'OBJETIVO' or 'OBJECTIVE',text={l.objective}},
            {title=es() and 'RECOMPENSA' or 'REWARD',text={l.reward},colour=G.C.MONEY},
            {title=es() and 'FALLA SI' or 'FAILS IF',text={l.failure},colour=G.C.RED}}}
    end
end
