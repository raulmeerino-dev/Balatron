-- Reward receipts are allocated once and persisted separately from result banners.
-- No reward applies a Seal: those rewards contain real vanilla Spectral cards.
return function(C,P)
    local X=require('portrait_expansion48')
    local function es() return (G.SETTINGS.language or ''):sub(1,2)=='es' end
    local function copy(v) return copy_table(v) end
    local function state()
        local s=C.state();if not s then return end
        s.reward_receipts=s.reward_receipts or {};s.reward_decisions=s.reward_decisions or {};s.reward_serial=s.reward_serial or 0
        return s
    end
    function C.reward_template(a)
        local reward=C.entries[a.id].reward
        if type(reward)~='table' then
            local types={cash_clean='Cash',cash_execution='Cash',cash_debt='Cash',rerolls='Rerolls',joker='Joker',mono='Cash+Tarot',spectral='Spectral'}
            return {kind='legacy',reward=reward,mutation_cash_factor=a.mutation_cash_factor,reward_type=types[reward] or reward}
        end
        local t=copy(reward)
        if t.kind=='planets' then t={kind='cards',keys={a.planet,a.planet,a.planet}} end
        if t.kind=='cards' then
            local sets,types={},{}
            for _,key in ipairs(t.keys) do local set=G.P_CENTERS[key].set;if not sets[set] then sets[set]=true;types[#types+1]=set end end
            table.sort(types);t.reward_type=table.concat(types,'+')
        else t.reward_type=t.kind end
        return t
    end
    local function save_card(key,set,seed)
        local card=SMODS.create_card{set=set or G.P_CENTERS[key].set,key=key,area=G.consumeables,
            skip_materialize=true,key_append=seed}
        local saved=copy(card:save());saved.added_to_deck=false
        card:remove();return saved
    end
    local function contraband_pool()
        local B=PortraitEvents and PortraitEvents.black_market
        local out={};if not B or not B.enabled() then return out end
        for _,id in ipairs(B.contraband.order) do
            local def=B.contraband.entries[id];local center=G.P_CENTERS[def.key]
            if center and center.unlocked~=false and not G.GAME.banned_keys[def.key]
                and (B.config().contraband_weights[id] or 0)>0
                and (not def.mission or X.unlocked(def.mission))
                and (not B.registry.mod_enabled or B.registry.mod_enabled(center)) then out[#out+1]=def.key end
        end
        return out
    end
    C.contraband_reward_pool=contraband_pool
    function C.queue_reward(template,options)
        local s=state();options=options or {}
        s.reward_serial=s.reward_serial+1
        local r={id=s.reward_serial,source=options.source,uid=options.uid,template=copy(template),dollars=0,pending=true}
        local t=r.template
        if t.kind=='cards' then
            r.cards={};for i,key in ipairs(t.keys) do r.cards[i]=save_card(key,nil,'ct_receipt_'..r.id..'_'..i) end;r.next_card=1
        elseif t.kind=='contraband_choice' then
            local pool=contraband_pool();r.choices={}
            for i=1,math.min(t.count or 3,#pool) do
                local index=math.min(#pool,math.floor(P.roll('ct_receipt_'..r.id..'_'..i)*#pool)+1)
                local key=table.remove(pool,index);r.choices[#r.choices+1]=save_card(key,'Contraband','ct_receipt_'..r.id..'_'..i)
            end
        elseif t.kind=='pack' then
            local card=SMODS.create_card{set='Booster',key=t.key,skip_materialize=true,key_append='ct_receipt_'..r.id}
            r.pack=X.mutations.freeze_pack(card);card:remove()
        end
        s.reward_receipts[#s.reward_receipts+1]=r
        if C.deliver_receipt then C.deliver_receipt(r,false) end
        return {id=r.id,dollars=r.dollars or 0,pending=r.pending,template=copy(template)}
    end
    C.reward_filters={}
    function C.add_reward_filter(priority,fn)
        C.reward_filters[#C.reward_filters+1]={priority=priority,fn=fn}
        table.sort(C.reward_filters,function(a,b) return a.priority<b.priority end)
    end
    local function pay(template,a)
        local templates={template}
        for _,filter in ipairs(C.reward_filters) do templates=filter.fn(a,templates) or templates end
        local result
        for _,t in ipairs(templates) do result=C.queue_reward(t,{source=a.id,uid=a.uid}) end
        return result or {dollars=0}
    end
    function C.complete_reward(a)
        local s=state();local original=C.reward_template(a);a.original_template=copy(original)
        -- A stake may not be chosen retroactively after a later result is known.
        -- Simultaneous completions remain ordered; only the newest can be staked.
        for _,pending in ipairs(s.reward_decisions) do pending.escrow=false end
        local previous=s.previous_contract_original
        s.previous_contract_original=copy(original)
        -- Escrow's old deposit pays exactly twice, independently of the new reward.
        if s.escrow then
            local deposit=s.escrow
            s.escrow=nil
            C.queue_reward(deposit.template,{source='escrow',uid=deposit.uid})
            C.queue_reward(deposit.template,{source='escrow',uid=deposit.uid})
        end
        local can_exchange=previous and X.has('j_incj_promissory_note')
        local can_deposit=PortraitRunRules and PortraitRunRules.has('escrow')
        if can_exchange or can_deposit then
            s.reward_decisions[#s.reward_decisions+1]={uid=a.uid,contract=a.id,original=copy(original),
                previous=can_exchange and copy(previous) or nil,escrow=can_deposit,selected=nil}
            return {dollars=0,pending=true,decision=a.uid}
        end
        return pay(original,a)
    end
    function C.result_event(a,success,retried)
        local s=state()
        if not success then
            s.escrow=nil
            for _,pending in ipairs(s.reward_decisions) do pending.escrow=false end
        end
        X.track{exp48_contract_result=true,contract=a,success=success,retried=retried,original_template=a.original_template}
    end
    local function receipt(id)
        for _,r in ipairs(state().reward_receipts) do if r.id==id then return r end end
    end
    local function space(saved)
        local area=G.consumeables
        local extra=saved.edition and (saved.edition.card_limit or (saved.edition.negative and 1)) or 0
        return area and #area.cards+(G.GAME.consumeable_buffer or 0)<area.config.card_limit+(extra or 0)
    end
    local function restore(saved,area)
        local center=G.P_CENTERS[saved.save_fields.center]
        local card=Card(0,0,G.CARD_W,G.CARD_H,G.P_CARDS.empty,center,{bypass_discovery_center=true})
        card:load(copy(saved));card.added_to_deck=false
        card.ability.queue_negative_removal=nil
        if area then card:add_to_deck();area:emplace(card);card:start_materialize() end
        return card
    end
    function C.deliver_receipt(r,manual)
        if not r.pending then return true end
        local s=state();local t=r.template;local complete=false
        local saved=r.cards and r.cards[r.next_card or 1] or r.selected
        if saved then
            if not space(saved) then return false end
            restore(saved,G.consumeables)
            if r.cards then
                r.next_card=r.next_card+1;complete=r.next_card>#r.cards
                if not complete then return C.deliver_receipt(r,manual) end
            else complete=true end
        elseif t.kind=='tag' then add_tag(Tag(t.key));complete=true
        elseif t.kind=='multiplier' then
            s.temporary_multipliers=s.temporary_multipliers or {}
            s.temporary_multipliers[#s.temporary_multipliers+1]={id=r.id,mult=t.mult,hands=t.hands};complete=true
        elseif t.kind=='legacy' then
            local delivered=C.reward(t.reward,t.mutation_cash_factor);r.dollars=delivered.dollars or 0;complete=true
        elseif t.kind=='pack' and r.pack and manual then return false end
        if complete then
            r.pending=false
            for i,v in ipairs(s.reward_receipts) do if v==r then table.remove(s.reward_receipts,i);break end end
        end
        return complete
    end
    function C.pending_rewards()
        local s=state();return s and (#s.reward_decisions>0 or #s.reward_receipts>0)
    end
    local function title(t)
        if t.kind=='cards' then
            local labels={};for _,key in ipairs(t.keys) do labels[#labels+1]=localize{type='name_text',set=G.P_CENTERS[key].set,key=key} end
            return table.concat(labels,' + ')
        elseif t.kind=='tag' then return localize{type='name_text',set='Tag',key=t.key}
        elseif t.kind=='pack' then return localize{type='name_text',set='Booster',key=t.key}
        elseif t.kind=='multiplier' then return 'X'..t.mult..' Mult · '..t.hands..(es() and ' manos' or ' hands')
        elseif t.kind=='contraband_choice' then return es() and 'Elegir Contraband' or 'Choose Contraband'
        else return es() and 'Recompensa de contrato' or 'Contract reward' end
    end
    local function preview(saved)
        local area=CardArea(0,0,1.65,2.2,{card_limit=1,type='title',highlight_limit=0})
        local card=restore(saved);card.ct_preview=true;area:emplace(card)
        return {n=G.UIT.O,config={object=area}}
    end
    local function rows(text)
        local out={}
        for _,line in ipairs(require('portrait_tooltips').wrap({text},4.5,0.3)) do out[#out+1]=P.text(line,0.3) end
        return out
    end
    local function choice_button(label,ref)
        local node=UIBox_button{label={label},button='ct48_choose',minw=1.5,minh=portrait_touch_height(0.7),scale=0.3}
        node.nodes[1].config.ref_table=ref;return node
    end
    function C.open_rewards()
        local s=state();if not C.pending_rewards() then return end
        if G.GAME.PACK_INTERRUPT or G.booster_pack then return end
        local nodes={P.text(es() and 'RECOMPENSAS' or 'REWARDS',0.42)}
        local d=s.reward_decisions[1]
        if d then
            if not d.selected and d.previous then
                P.append(nodes,rows(es() and 'Letra de cambio: elige una recompensa.' or 'Promissory Note: choose a reward.'))
                P.append(nodes,rows(title(d.original)));nodes[#nodes+1]=P.button(es() and 'Recompensa actual' or 'Current reward','ct48_decide',{uid=d.uid,choice='original'})
                P.append(nodes,rows(title(d.previous)));nodes[#nodes+1]=P.button(es() and 'Recompensa anterior' or 'Previous reward','ct48_decide',{uid=d.uid,choice='previous'})
            else
                local selected=d.selected or d.original
                P.append(nodes,rows(title(selected)))
                if d.escrow then
                    P.append(nodes,rows(es() and 'Cobrar ahora o depositar: el próximo éxito paga el depósito dos veces; un fallo lo pierde.'
                        or 'Claim now or stake: the next success pays the deposit twice; any failure loses it.'))
                    nodes[#nodes+1]=P.button(es() and 'Depositar' or 'Stake','ct48_decide',{uid=d.uid,choice='stake'})
                end
                nodes[#nodes+1]=P.button(es() and 'Cobrar' or 'Claim','ct48_decide',{uid=d.uid,choice='claim'})
            end
        else
            local r=s.reward_receipts[1]
            P.append(nodes,rows(title(r.template)))
            if r.choices and not r.selected then
                local columns={}
                for i,saved in ipairs(r.choices) do
                    columns[#columns+1]={n=G.UIT.C,config={align='cm',padding=0.05},nodes={preview(saved),
                        choice_button(tostring(i),{id=r.id,index=i})}}
                end
                nodes[#nodes+1]={n=G.UIT.R,config={align='cm',padding=0.05},nodes=columns}
                if #r.choices==0 then P.append(nodes,rows(es() and 'No hay Contraband elegible. La recompensa queda pendiente.' or 'No eligible Contraband. The reward remains pending.')) end
            else
                local saved=r.cards and r.cards[r.next_card or 1] or r.selected
                if saved then nodes[#nodes+1]=preview(saved) end
                if not saved or space(saved) then nodes[#nodes+1]=P.button(es() and 'Reclamar' or 'Claim','ct48_claim',r.id)
                else P.append(nodes,rows(es() and 'Libera un espacio de consumible y vuelve a reclamar. La carta está guardada.'
                    or 'Free a consumable slot, then return to claim. This card is saved.')) end
            end
        end
        P.open(nodes,'ct48_reward_back')
        if G.OVERLAY_MENU then G.OVERLAY_MENU.ct48_reward=true end
    end
    G.FUNCS.ct48_decide=function(e)
        local s=state();local d=s.reward_decisions[1];local ref=e.config.ref_table
        if not d or d.uid~=ref.uid then return end
        if ref.choice=='original' or ref.choice=='previous' then
            d.selected=copy(d[ref.choice]);if not d.escrow then
                pay(d.selected,{id=d.contract,uid=d.uid});table.remove(s.reward_decisions,1)
            end
        else
            local selected=d.selected or d.original
            if ref.choice=='stake' and d.escrow and not s.escrow then s.escrow={template=copy(selected),uid=d.uid}
            elseif ref.choice=='claim' then pay(selected,{id=d.contract,uid=d.uid})
            else return end
            table.remove(s.reward_decisions,1)
        end
        save_run();G.FUNCS.exit_overlay_menu();C.open_rewards()
    end
    G.FUNCS.ct48_choose=function(e)
        local ref=e.config.ref_table;local r=receipt(ref.id)
        if not r or r.selected or not r.choices or not r.choices[ref.index] then return end
        r.selected=copy(r.choices[ref.index]);save_run();C.open_rewards()
    end
    G.FUNCS.ct48_claim=function(e)
        local s=state();local r=receipt(e.config.ref_table);if not r then return end
        if r.template.kind=='pack' then
            if not r.pack or G.GAME.PACK_INTERRUPT or G.booster_pack then return end
            s.active_reward_pack=r.id;r.opening=true
            G.FUNCS.exit_overlay_menu();save_run()
            if not X.mutations.open_pack(r.pack) then r.opening=nil;s.active_reward_pack=nil;save_run();C.open_rewards() end
            return
        end
        local t=r.template;local complete=C.deliver_receipt(r,true)
        G.FUNCS.exit_overlay_menu();save_run()
        C.open_rewards()
    end
    G.FUNCS.ct48_reward_back=function() G.FUNCS.exit_overlay_menu();save_run();P.schedule_offers() end
    G.FUNCS.ct48_rewards=function() C.open_rewards() end
    local calculate=C.mod.calculate
    C.mod.calculate=function(self,context)
        local result=calculate and calculate(self,context)
        local s=state();if not s or not P.real(context) then return result end
        if context.ending_booster and s.active_reward_pack then
            local r=receipt(s.active_reward_pack)
            if r then for i,v in ipairs(s.reward_receipts) do if v==r then table.remove(s.reward_receipts,i);break end end end
            s.active_reward_pack=nil
        elseif context.final_scoring_step then
            local mult=1
            for _,buff in ipairs(s.temporary_multipliers or {}) do if buff.hands>0 then mult=mult*buff.mult end end
            if mult~=1 then return {xmult=mult,no_retrigger=true} end
        elseif context.after and P.once(s,'buff_hand',P.token()..':'..tostring(G.GAME.hands_played)) then
            for i=#(s.temporary_multipliers or {}),1,-1 do
                local buff=s.temporary_multipliers[i];buff.hands=buff.hands-1
                if buff.hands<=0 then table.remove(s.temporary_multipliers,i) end
            end
        end
        return result
    end
    local run_info=C.run_info
    function C.run_info(...)
        if C.pending_rewards() then return C.open_rewards() end
        return run_info(...)
    end
    local close=G.FUNCS.ct_result_close
    G.FUNCS.ct_result_close=function(...)
        close(...)
        if not G.OVERLAY_MENU and C.pending_rewards() and G.STATE~=G.STATES.GAME_OVER then C.open_rewards() end
    end
    local update=Game.update
    function Game:update(dt)
        update(self,dt)
        if PortraitRunGallery and not C.reward_gallery_installed then
            C.reward_gallery_installed=true;local groups=PortraitRunGallery.groups
            PortraitRunGallery.groups=function(filter)
                local result=groups(filter);local s=state()
                if s and (not filter or filter=='contract') and C.pending_rewards() then
                    result[#result+1]={key='contract',columns=1,items={P.button(es() and 'Recompensas pendientes' or 'Pending rewards','ct48_rewards')}}
                end
                if s and #(s.temporary_multipliers or {})>0 and (not filter or filter=='effects') then
                    local items={};for _,b in ipairs(s.temporary_multipliers) do items[#items+1]=P.text('X'..b.mult..' Mult · '..b.hands..(es() and ' manos' or ' hands')) end
                    result[#result+1]={key='effects',columns=1,items=items}
                end
                return result
            end
        end
        local s=state()
        if s and s.active_reward_pack and not G.GAME.PACK_INTERRUPT and not G.booster_pack then
            local r=receipt(s.active_reward_pack);if r then r.opening=nil end
            s.active_reward_pack=nil
        end
        local buffs=s and s.temporary_multipliers or {}
        local signature={};for _,b in ipairs(buffs) do signature[#signature+1]='X'..b.mult..' · '..b.hands end
        signature=table.concat(signature,' / ')
        if C.buff_status and (signature~=C.buff_signature or C.buff_major~=G.jokers or G.STAGE~=G.STAGES.RUN) then
            C.buff_status:remove();C.buff_status=nil
        end
        if not C.buff_status and signature~='' and G.jokers and G.STAGE==G.STAGES.RUN then
            C.buff_signature=signature;C.buff_major=G.jokers
            C.buff_status=UIBox{definition={n=G.UIT.ROOT,config={align='cm',padding=0.04,r=0.07,colour=G.C.MULT,
                hover=true,on_demand_tooltip={title=es() and 'Multiplicador temporal' or 'Temporary Multiplier',
                    text={es() and 'Una carga por mano real. Persistente al guardar.' or 'One charge per real hand. Persists when saved.'}}},
                nodes={{n=G.UIT.T,config={text=signature,scale=0.24,colour=G.C.WHITE,shadow=true}}}},
                config={align='bri',major=G.jokers,offset={x=-0.02,y=-0.02}}}
        end
        if s and G.STAGE==G.STAGES.RUN and not G.OVERLAY_MENU and G.STATE==G.STATES.SELECTING_HAND then
            for _,a in ipairs(C.active()) do if a.pending_choice then C.choose_witnesses(a);break end end
        end
    end
end
