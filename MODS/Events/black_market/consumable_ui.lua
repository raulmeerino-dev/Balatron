return function(B,C)
    local picker
    local function button(label,callback,ref,check)
        local node=UIBox_button{label={label},button=callback,minw=2.2,minh=portrait_touch_height(0.75),scale=0.32}
        node.nodes[1].config.ref_table=ref;node.nodes[1].config.func=check
        return node
    end
    local function preview(source,choice)
        local id=C.id(source)
        if choice.components then
            local area=CardArea(0,0,3.6,2.8,{card_limit=2,type='title',highlight_limit=0})
            for i,key in ipairs(choice.components) do
                local card=SMODS.create_card{set='Joker',key=key,area=area,no_edition=true,skip_materialize=true}
                card.cb_preview=true;card:set_edition(i==choice.edition_to and choice.edition or nil,true,true);area:emplace(card)
            end
            return {n=G.UIT.C,config={align='cm'},nodes={{n=G.UIT.O,config={object=area}},PortraitGameplay.text(choice.label,0.25)}}
        end
        if choice.label and not choice.saved and not choice.key then
            local rows={}
            for _,line in ipairs(require('portrait_tooltips').wrap({choice.label},3.5,0.3)) do rows[#rows+1]=PortraitGameplay.text(line,0.3) end
            return {n=G.UIT.C,config={align='cm',minw=2.4,minh=2.5},nodes=rows}
        end
        if id=='bribe' then
            local blind=G.P_BLINDS[choice.key]
            local icon=AnimatedSprite(0,0,1.7,1.7,G.ANIMATION_ATLAS[blind.atlas or 'blind_chips'],blind.pos)
            return {n=G.UIT.C,config={align='cm'},nodes={
                {n=G.UIT.O,config={object=icon}},
                create_UIBox_blind_popup(blind,true)}}
        elseif id=='stolen_tag' then
            local tally,id=G.GAME.tag_tally,G.tagid
            local tag=Tag(choice.key,true)
            G.GAME.tag_tally=tally;G.tagid=id
            local node=tag:generate_UI(1.7)
            return node
        end
        local saved=choice.saved
        if not saved then
            local target=C.entries[id].targets and C.resolve(source,choice)
            if target then saved=target:save()
            elseif choice.key then
                local card=SMODS.create_card{set=G.P_CENTERS[choice.key].set,key=choice.key,skip_materialize=true}
                saved=card:save();card:remove()
            end
        end
        local area=CardArea(0,0,2.4,3.2,{card_limit=1,type='title',highlight_limit=0})
        if saved then C.preview(saved,area) end
        local nodes={{n=G.UIT.O,config={object=area}}}
        if id=='fake_diploma' then
            local target=C.resolve(source,choice)
            if target then nodes[#nodes+1]=PortraitGameplay.text((target.ability.extra.stage or 1)..' → '..((target.ability.extra.stage or 1)+1),0.32) end
        elseif id=='stain_remover' then
            local target=C.resolve(source,choice);local stickers={}
            if target then for _,key in ipairs({'eternal','rental','perishable'}) do if target.ability[key] then stickers[#stickers+1]=key end end end
            nodes[#nodes+1]=PortraitGameplay.text(table.concat(stickers,' / '),0.25)
        end
        return {n=G.UIT.C,config={align='cm'},nodes=nodes}
    end
    function C.open(card,page)
        if not C.can_use(card) then return end
        local choices=C.prepare(card)
        card.ability.cb_pending=true
        picker={card=card,choices=choices,page=page or 1}
        local title=localize{type='name_text',set='Contraband',key=card.config.center.key}
        local rows={{n=G.UIT.R,config={align='cm',padding=0.1},nodes={
            {n=G.UIT.T,config={text=title,scale=0.48,colour=G.C.WHITE,shadow=true}}}}}
        local first=(picker.page-1)*3+1
        local columns={}
        for index=first,math.min(first+2,#choices) do
            local ref={card=card,choice=choices[index]}
            columns[#columns+1]={n=G.UIT.C,config={align='cm',padding=0.10},nodes={
                preview(card,choices[index]),button(localize('b_select'),'evt_cb_select',ref,'evt_cb_can_select')}}
        end
        rows[#rows+1]={n=G.UIT.R,config={align='cm'},nodes=columns}
        if #choices>3 then
            local pages={};for i=1,math.ceil(#choices/3) do pages[i]=tostring(i) end
            rows[#rows+1]=create_option_cycle{w=4,scale=0.7,options=pages,current_option=picker.page,opt_callback='evt_cb_page'}
        end
        G.FUNCS.overlay_menu{definition=create_UIBox_generic_options{back_func='evt_cb_cancel',contents=rows}}
        B.checkpoint()
    end
    G.FUNCS.evt_cb_page=function(args) if picker then C.open(picker.card,args.to_key) end end
    G.FUNCS.evt_cb_can_select=function(e)
        local ref=e.config.ref_table
        local valid=C.can_use(ref.card) and C.resolve(ref.card,ref.choice)
        e.config.button=valid and 'evt_cb_select' or nil
        e.config.colour=valid and G.C.GREEN or G.C.UI.BACKGROUND_INACTIVE
    end
    G.FUNCS.evt_cb_select=function(e)
        local ref=e.config.ref_table
        if not picker or not C.can_use(ref.card) or not C.resolve(ref.card,ref.choice) then return end
        picker.selected=ref.choice
        G.FUNCS.overlay_menu{definition=create_UIBox_generic_options{back_func='evt_cb_back',contents={
            {n=G.UIT.R,config={align='cm'},nodes={preview(ref.card,ref.choice)}},
            button(localize('b_use'),'evt_cb_confirm',ref,'evt_cb_can_confirm'),
            button(localize('b_cancel'),'evt_cb_cancel')
        }}}
    end
    G.FUNCS.evt_cb_back=function() if picker then C.open(picker.card,picker.page) end end
    G.FUNCS.evt_cb_can_confirm=function(e)
        G.FUNCS.evt_cb_can_select(e)
        if e.config.button then e.config.button='evt_cb_confirm' end
    end
    G.FUNCS.evt_cb_cancel=function()
        if picker then picker.card.ability.cb_pending=nil;picker.card.ability.cb_selected=nil end
        picker=nil;G.FUNCS.exit_overlay_menu();B.checkpoint()
    end
    G.FUNCS.evt_cb_confirm=function(e)
        local ref=e.config.ref_table
        if not picker or not C.can_use(ref.card) or not C.resolve(ref.card,ref.choice) then return end
        ref.card.ability.cb_selected=ref.choice;ref.card.ability.cb_pending=nil
        picker=nil;G.FUNCS.exit_overlay_menu()
        C.native_use({config={ref_table=ref.card}},false)
    end
    C.native_use=G.FUNCS.use_card
    G.FUNCS.use_card=function(e,...)
        local card=e.config.ref_table;local id=C.id(card)
        if not id then return C.native_use(e,...) end
        if not C.can_use(card) then return end
        local def=C.entries[id]
        if def.targets or def.choices then return C.open(card) end
        return C.native_use(e,...)
    end
    function C.refresh_status()
        local active=G.GAME and G.GAME.portrait_events and B.state().dice_ante==G.GAME.round_resets.ante
        if C.status and (not active or C.status_major~=G.consumeables) then C.status:remove();C.status=nil end
        if active and G.consumeables and not C.status then
            local center=G.P_CENTERS.cb_evt_loaded_dice
            local sprite=Sprite(0,0,0.42,0.56,G.ASSET_ATLAS[center.atlas],center.pos)
            C.status=UIBox{definition={n=G.UIT.ROOT,config={align='cm',padding=0.02,colour=G.C.CLEAR,
                hover=true,on_demand_tooltip={class=center.set,loc={set='Contraband',key=center.key,vars={2,center.cost}},text=localize{type='raw_descriptions',set='Contraband',key=center.key},title=localize{type='name_text',set='Contraband',key=center.key}}},
                nodes={{n=G.UIT.O,config={object=sprite}}}},config={align='tri',major=G.consumeables,offset={x=-0.02,y=0.02}}}
            C.status_major=G.consumeables
        end
    end
    local update=Game.update
    function Game:update(dt)
        update(self,dt)
        if G.STAGE==G.STAGES.RUN then
            C.refresh_status()
            if not picker and not G.OVERLAY_MENU and not G.TAROT_INTERRUPT and G.STATE_COMPLETE and not B.busy then
                for _,card in ipairs(G.consumeables and G.consumeables.cards or {}) do
                    if card.ability.cb_pending and C.can_use(card) then C.open(card);break end
                end
            end
        else
            picker=nil
            if C.status then C.status:remove();C.status=nil end
        end
    end
end
