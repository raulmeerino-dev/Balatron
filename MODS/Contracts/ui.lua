return function(C)
    local P=PortraitGameplay
    SMODS.Atlas{key='contracts',path='contracts.png',px=128,py=128,disable_mipmap=true,
        inject=function(self)
            SMODS.Atlas.inject(self);self.image:setFilter('nearest','nearest')
        end}
    SMODS.Shader{key='tear',path='tear.fs'}
    local function es() return (G.SETTINGS.language or ''):sub(1,2)=='es' end
    local failures={
        clean_hands={'You discard.','Descartas.'},one_shot={'The next Blind takes more than one hand.','Necesitas más de una mano en la próxima ciega.'},
        monochrome={'The winning hand scores several suits.','La mano ganadora puntúa varios palos.'},
        high_roller={'You leave the next shop below the target.','Sales de la siguiente tienda sin gastar el objetivo.'},
        no_safety_net={'You use a consumable during the Boss Blind.','Usas un consumible durante la ciega jefe.'},
        execution={'You beat this Boss before reaching the target.','Ganas a este jefe sin destruir las cartas requeridas.'},
        debt_collector={'You finish this Ante below the target.','Terminas esta apuesta inicial sin el dinero requerido.'},
    }
    local positions={}
    for i,id in ipairs(C.order) do
        positions[id]={x=(i-1)%4,y=math.floor((i-1)/4)}
        if C.entries[id].expansion_id then
            failures[id]={C.expansion_text[id].en.failure,C.expansion_text[id].es.failure}
            SMODS.Atlas{key='expansion_'..id,path='expansion/'..id..'.png',px=128,py=128,disable_mipmap=true,
                inject=function(self) SMODS.Atlas.inject(self);self.image:setFilter('nearest','nearest') end}
        end
    end
    function C.icon(id,size)
        local expansion=C.entries[id] and C.entries[id].expansion_id
        local sprite=Sprite(0,0,size,size,G.ASSET_ATLAS[expansion and ('ct_expansion_'..id) or 'ct_contracts'],expansion and {x=0,y=0} or positions[id])
        sprite.created_on_pause=true
        sprite.states.collide.can=false
        sprite.states.drag.can=false
        sprite.states.hover.can=false
        return {n=G.UIT.O,config={object=sprite}}
    end
    function C.heading(id)
        return {n=G.UIT.R,config={align='cm',padding=0.12},nodes={
            {n=G.UIT.R,config={align='cm'},nodes={C.icon(id,3.2)}},
        }}
    end
    function C.info(a,config)
        local c=config or C.config()
        local function cash(value) return math.floor(value*(a.mutation_cash_factor or 1)+0.5) end
        local lines=localize{type='raw_descriptions',set='Other',key='ct_'..a.id,vars={
            a.id=='clean_hands' and a.target or c.clean_hands_blinds,cash(c.clean_hands_reward),cash(c.one_shot_fallback),cash(c.monochrome_reward),
            a.id=='high_roller' and a.target or c.high_roller_spend,c.high_roller_rerolls,
            a.id=='execution' and a.target or c.execution_cards,cash(c.execution_reward),
            a.id=='debt_collector' and a.target or c.debt_required,cash(c.debt_reward)}}
        local reward_start=({clean_hands=2,one_shot=2,monochrome=3,high_roller=2,no_safety_net=3,execution=3,debt_collector=2})[a.id]
        local objective,reward,secondary={},{},{}
        for i,line in ipairs(lines) do
            if a.id=='execution' and i==2 then secondary[#secondary+1]=line
            elseif i<reward_start then objective[#objective+1]=line
            else reward[#reward+1]=line:gsub('^Reward: ',''):gsub('^Recompensa: ',''):gsub('^Premio: ','') end
        end
        if a.progress~=nil and a.target then secondary[#secondary+1]=(es() and 'Progreso: ' or 'Progress: ')..a.progress..' / '..a.target end
        if a.duration then
            local durations={blinds={'Ciegas consecutivas','Consecutive Blinds'},next_blind={'Próxima ciega','Next Blind'},
                next_shop={'Próxima tienda','Next shop'},next_boss={'Próxima ciega jefe','Next Boss Blind'},ante={'Esta apuesta inicial','This Ante'}}
            local duration=durations[a.duration]
            if duration then secondary[#secondary+1]=duration[es() and 1 or 2] end
        end
        if a.uid and not a.status then secondary[#secondary+1]=es() and 'Activo' or 'Active' end
        if a.status then
            secondary[#secondary+1]=a.status=='active' and (es() and 'Activo' or 'Active') or localize('k_ct_'..a.status)
        end
        return {title=localize('k_ct_'..a.id),class='Contract',text=lines,secondary=secondary,sections={
            {title=es() and 'OBJETIVO' or 'OBJECTIVE',text=objective},
            {title=es() and 'RECOMPENSA' or 'REWARD',text=reward,colour=G.C.MONEY},
            {title=es() and 'FALLA SI' or 'FAILS IF',text={failures[a.id][es() and 2 or 1]},colour=G.C.RED}}}
    end
    function C.detail_nodes(a)
        return {require('portrait_tooltips').embedded(PortraitRunGallery.tooltip(C.info(a)))}
    end
    -- Offer presentation owns no contract state. Inspect/back never calls offer(),
    -- accept(), save_run(), or the offer scheduler.
    local function offer_button(label,callback,width,colour,back)
        local node=UIBox_button{label={label},button=callback,col=true,minw=width,
            minh=portrait_touch_height(0.75),scale=0.34,colour=colour,
            focus_args=back and {button='b'} or nil}
        if back then node.nodes[1].config.id='overlay_menu_back_button' end
        return node
    end
    local function offer_text(text,width,scale,colour)
        local rows={}
        for _,line in ipairs(require('portrait_tooltips').wrap({text},width,scale)) do
            rows[#rows+1]={n=G.UIT.R,config={align='cm',padding=0.02,maxw=width},nodes={
                {n=G.UIT.T,config={text=line,scale=scale,colour=colour,shadow=true}}}}
        end
        return {n=G.UIT.R,config={align='cm',padding=0.06},nodes=rows}
    end
    local function open_offer_view(id,nodes,enter,details)
        local width=math.min(5,G.ROOM.T.w-1)
        local definition=create_UIBox_generic_options{no_back=true,minw=width,padding=0.04,
            colour=G.C.CLEAR,outline_colour=G.C.CLEAR,bg_colour=adjust_alpha(G.C.BLACK,0.45),
            contents={{n=G.UIT.C,config={align='cm',padding=0.08},nodes=nodes}}}
        -- Keep native overlay placement/input, without the generic window frame.
        definition.nodes[1].config.emboss=nil
        G.SETTINGS.paused=true
        G.FUNCS.overlay_menu{definition=definition,
            config={offset={x=0,y=enter and not G.SETTINGS.reduced_motion and 0.45 or 0}}}
        G.OVERLAY_MENU.ct_offer_id=id
        G.OVERLAY_MENU.ct_offer_details=details or false
    end
    function C.present_offer(id,enter)
        local width=math.min(5,G.ROOM.T.w-1)
        local art=C.icon(id,math.min(3.6,width-0.4))
        local sprite=art.config.object
        local nodes={
            offer_text(localize('k_ct_available'),width,0.31,G.C.UI.TEXT_LIGHT),
            {n=G.UIT.R,config={align='cm',padding=0.12,colour=G.C.CLEAR,
                button='ct_offer_info',ref_table=id,hover=true},nodes={art}},
            offer_text(localize('k_ct_'..id),width,0.46,G.C.WHITE),
            {n=G.UIT.R,config={align='cm',padding=0.10},nodes={
                offer_button(localize('b_ct_accept'),'ct_accept',(width-0.3)/2,G.C.GREEN),
                {n=G.UIT.B,config={w=0.18,h=0}},
                offer_button(localize('b_ct_decline'),'ct_decline',(width-0.3)/2,G.C.GREY)}}}
        open_offer_view(id,nodes,enter,false)
        if enter then
            -- Explicit rotation avoids consuming RNG for a purely visual juice.
            sprite:juice_up(0.12,0)
            play_sound('cardSlide1',1,0.35)
        end
    end
    G.FUNCS.ct_offer_info=function(e)
        local menu=G.OVERLAY_MENU
        local s=C.state()
        local id=e and e.config.ref_table
        if not menu or menu.ct_offer_details or menu.ct_offer_id~=id or not s or s.offer~=id then return end
        local info=C.info(C.offer_terms(id))
        info.width=math.min(5,G.ROOM.T.w-1)
        local nodes={require('portrait_tooltips').embedded(PortraitRunGallery.tooltip(info)),
            {n=G.UIT.R,config={align='cm',padding=0.12},nodes={
                offer_button(localize('b_back'),'ct_offer_back',2.4,G.C.GREY,true)}}}
        open_offer_view(id,nodes,false,true)
    end
    G.FUNCS.ct_offer_back=function()
        local menu=G.OVERLAY_MENU
        local s=C.state()
        if not menu or not menu.ct_offer_details then return end
        if s and s.offer==menu.ct_offer_id then C.present_offer(s.offer,false)
        else menu.ct_offer_details=false;G.FUNCS.exit_overlay_menu() end
    end
    local exit_overlay_menu=G.FUNCS.exit_overlay_menu
    G.FUNCS.exit_overlay_menu=function(...)
        local menu=G.OVERLAY_MENU
        if menu and menu.ct_offer_details then
            -- Escape/controller dismissal follows the same Back action as touch,
            -- including the native cursor-layer cleanup, instead of losing the offer.
            local back=menu:get_UIE_by_ID('overlay_menu_back_button')
            if back then back:click();return end
        end
        return exit_overlay_menu(...)
    end
    function C.inspect(a,result)
        if result and not a.uid then
            local s=C.state();s.serial=(s.serial or 0)+1;a.uid=s.serial
        end
        local art=C.icon(a.id,3.5)
        local feedback_level=result and not a.feedback_shown and
            require('portrait_reward_fx').admit('contract',a.uid,2,70) or 0
        if result and feedback_level>=2 and not G.SETTINGS.reduced_motion then
            local sprite=art.config.object;local start=G.TIMERS.REAL
            sprite.draw=function(self)
                local t=math.min(1,math.max(0,(G.TIMERS.REAL-start-PortraitQOL.duration(0.5))/PortraitQOL.duration(0.85)))
                if a.status=='complete' then
                    self.dissolve=t;self.dissolve_colours={G.C.GOLD,G.C.RED}
                    self:draw_shader('dissolve')
                else
                    self:draw_shader('ct_tear',nil,{{name='progress',val=t},
                        {name='texture_details',val=self:get_pos_pixel()},{name='image_details',val=self:get_image_dims()}},
                        true,nil,nil,nil,nil,nil,true)
                end
            end
        end
        if result and not a.feedback_shown then
            a.feedback_shown=true
            if feedback_level>=2 then
            play_sound(a.status=='complete' and 'tarot1' or 'cardSlide2',a.status=='complete' and 1.05 or 0.7,0.5)
            play_sound(a.status=='complete' and 'gold_seal' or 'cancel',1,0.35)
            PortraitQOL.haptic(a.status=='complete' and 'contract_complete' or 'contract_failed')
            end
        end
        local nodes={P.text(result and localize('k_ct_'..a.status) or localize('k_contracts'),0.44),
            {n=G.UIT.R,config={align='cm',padding=0.15},nodes={art}}}
        if result then nodes[#nodes+1]=P.text(localize('k_ct_'..a.id),0.4) end
        if result then
            nodes[#nodes+1]=P.text(a.progress..' / '..a.target,0.34)
            if a.status=='failed' then
                local reason=a.failure_event=='lost_run' and (es() and 'La partida ha terminado.' or 'The run has ended.') or failures[a.id][es() and 2 or 1]
                for _,line in ipairs(PortraitRunGallery.wrap({reason},38)) do nodes[#nodes+1]=P.text(line,0.3) end
            end
            local r=a.reward
            if r then
                if (r.dollars or 0)>0 then nodes[#nodes+1]=P.text('+$'..r.dollars,0.5) end
                if r.card then nodes[#nodes+1]=P.text(localize{type='name_text',set=r.card.set,key=r.card.key},0.34) end
                if r.rerolls then nodes[#nodes+1]=P.text(localize{type='variable',key='a_ct_rerolls',vars={r.rerolls}},0.33) end
                if r.pending_spectral then nodes[#nodes+1]=P.text(localize('b_ct_claim'),0.33) end
                if r.pending then nodes[#nodes+1]=P.text(es() and 'Recompensa guardada para reclamar.' or 'Reward saved for claiming.',0.3) end
            end
        else P.append(nodes,C.detail_nodes(a)) end
        P.open(nodes,result and 'ct_result_close' or nil)
        if result then G.OVERLAY_MENU.ct_result_uid=a.uid end
    end
    G.FUNCS.ct_result_close=function()
        local s=C.state()
        local uid=G.OVERLAY_MENU and G.OVERLAY_MENU.ct_result_uid
        if not uid or not s or not s.results or not s.results[1] or s.results[1].uid~=uid then return end
        table.remove(s.results,1)
        G.FUNCS.exit_overlay_menu()
        if G.STATE~=G.STATES.GAME_OVER then save_run();P.schedule_offers() end
    end
    G.FUNCS.ct_inspect=function(e)
        for _,a in ipairs(C.active()) do if a.uid==e.config.ref_table then C.inspect(a);return end end
    end
    local function refresh_legacy_hud()
        local area=G.consumeables
        if not area or G.STAGE~=G.STAGES.RUN then return end
        local active=C.active();local ids={}
        for _,a in ipairs(active) do ids[#ids+1]=a.uid..':'..a.progress end
        local signature=table.concat(ids,'|')
        if area.ct_signature==signature then return end
        area.ct_signature=signature
        if area.children.ct_hud then area.children.ct_hud:remove();area.children.ct_hud=nil end
        if #active==0 then return end
        local rows,cells={},{}
        local columns=math.max(1,math.floor((area.T.w+0.1)/0.8))
        for _,a in ipairs(active) do
            cells[#cells+1]={n=G.UIT.C,config={align='cm',minw=0.74,minh=0.8,padding=0.03,
                r=0.08,colour=G.C.BLACK,button='ct_inspect',ref_table=a.uid,hover=true},nodes={C.icon(a.id,0.62)}}
            if #cells==columns then
                rows[#rows+1]={n=G.UIT.R,config={align='cm'},nodes=cells};cells={}
            end
        end
        if #cells>0 then rows[#rows+1]={n=G.UIT.R,config={align='cm'},nodes=cells} end
        area.children.ct_hud=UIBox{definition={n=G.UIT.ROOT,config={align='cm',padding=0.02,colour=G.C.CLEAR},nodes=rows},
            config={align='bm',offset={x=0,y=0.12},major=area,parent=area,bond='Weak'}}
        area.children.ct_hud.alignment.offset.x=(area.T.w-area.children.ct_hud.T.w)/2
    end
    local draw=CardArea.draw
    function CardArea:draw(...)
        draw(self,...)
        if not G.F_PORTRAIT and self==G.consumeables and self.states.visible and self.children.ct_hud then self.children.ct_hud:draw() end
    end
    function C.refresh_hud()
        if not G.F_PORTRAIT then return refresh_legacy_hud() end
        if G.consumeables and G.consumeables.children.ct_hud then
            G.consumeables.children.ct_hud:remove();G.consumeables.children.ct_hud=nil
            G.consumeables.ct_signature=nil
        end
        local hud=G.HUD
        local footer=hud and hud:get_UIE_by_ID('button_area')
        if not footer or G.STAGE~=G.STAGES.RUN then return end
        local active,ids=C.active(),{}
        for _,a in ipairs(active) do ids[#ids+1]=a.uid..':'..a.progress end
        local signature=table.concat(ids,'|')
        if hud.ct_signature==signature then return end
        hud.ct_signature=signature
        local parent=footer.parent
        for i=#parent.children,1,-1 do
            if parent.children[i].config.id=='portrait_contracts' then
                table.remove(parent.children,i):remove()
            end
        end
        if #active>0 then
            local cells={}
            local size=0.72
            for _,a in ipairs(active) do
                local icon=C.icon(a.id,size)
                local sprite=icon.config.object
                sprite.created_on_pause=false
                sprite.states.collide.can=true;sprite.states.hover.can=true
                sprite.config={force_focus=true}
                sprite.hover=function(self)
                    if self.hovering then return end
                    self.hovering=true
                    local info=C.info(a)
                    -- The shared tooltip wraps by font metrics.
                    self.config.h_popup=create_popup_UIBox_tooltip(info)
                    self.config.h_popup_config=get_portrait_top_popup_config(self)
                    Node.hover(self)
                    local popup=self.children.h_popup
                    if popup then
                        local placement=get_portrait_top_popup_config(self,{half_w=popup.T.w/2+0.1})
                        popup:set_alignment({type=placement.type,major=self,offset=placement.offset})
                        prepare_portrait_popup_fit(popup)
                    end
                end
                sprite.stop_hover=function(self) self.hovering=false;Node.stop_hover(self) end
                portrait_bind_tag_tooltip(sprite)
                icon.config.focus_with_object=true
                cells[#cells+1]={n=G.UIT.C,config={align='cm',padding=0.04},nodes={icon}}
            end
            hud:add_child({n=G.UIT.R,config={id='portrait_contracts',align='cm',padding=0.06},nodes=cells},parent)
            local row=table.remove(parent.children)
            for i,child in ipairs(parent.children) do
                if child==footer then table.insert(parent.children,i,row);break end
            end
        end
        hud:recalculate()
    end
    local update=Game.update
    local game_over=Game.update_game_over
    function Game:update_game_over(dt)
        local s=C.state()
        -- This state is reached only after Mr. Bones / mod save effects resolve.
        if s and not s.run_failed then s.run_failed=true;remove_save();C.event('lost_run') end
        if s and s.results and s.results[1] then
            if not G.OVERLAY_MENU then C.inspect(s.results[1],true) end
            return
        end
        return game_over(self,dt)
    end
    function Game:update(dt)
        C.refresh_hud()
        update(self,dt);C.refresh_hud()
        local s=C.state()
        if s and s.results and s.results[1] and not G.OVERLAY_MENU and G.STAGE==G.STAGES.RUN and
            (G.STATE==G.STATES.SELECTING_HAND or G.STATE==G.STATES.SHOP or G.STATE==G.STATES.ROUND_EVAL or G.STATE==G.STATES.BLIND_SELECT or G.STATE==G.STATES.GAME_OVER) then
            C.inspect(s.results[1],true)
        end
    end
end
