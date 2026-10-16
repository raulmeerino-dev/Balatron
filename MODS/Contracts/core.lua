return function(C,P)
    C.entries={};C.order={}
    function C.active()
        local s=C.state();if not s then return {} end
        s.actives=s.actives or {}
        if s.active then s.actives[#s.actives+1]=s.active;s.active=nil end
        for _,a in ipairs(s.actives) do
            if not a.uid then s.serial=(s.serial or 0)+1;a.uid=s.serial end
            if a.seen_destroyed then
                s.seen_destroyed=s.seen_destroyed or {}
                for id in pairs(a.seen_destroyed) do s.seen_destroyed[tostring(id)]=true end
                a.seen_destroyed=nil
            end
        end
        return s.actives
    end
    function C.register(d)
        d.name='k_ct_'..d.id;d.description='ct_'..d.id
        d.failure_condition=d.failure_condition or function(a) return a.failed end
        d.success_condition=d.success_condition or function(a) return a.progress>=a.target end
        C.entries[d.id]=d;C.order[#C.order+1]=d.id
        C.mod.config.contracts=C.mod.config.contracts or {}
        if C.mod.config.contracts[d.id]==nil then C.mod.config.contracts[d.id]=true end
    end
    function C.reward(kind,mutation_cash_factor)
        local s,c=C.state(),C.config()
        local receipt={dollars=0}
        local function cash(amount)
            amount=math.floor(amount*((PortraitRunRules and PortraitRunRules.factor('contracts_plus',1.5)) or 1)*(mutation_cash_factor or 1)+0.5)
            receipt.dollars=amount;ease_dollars(amount,true)
        end
        local function reward_card(set,rarity,key)
            local ok,card=P.reward_card(set,rarity,key)
            if ok then
                receipt.card={key=card.config.center.key,set=card.ability.set}
                if PortraitRunRules and PortraitRunRules.has('contracts_plus') then
                    local bonus=math.ceil((card.config.center.cost or 4)*0.5*(mutation_cash_factor or 1))
                    receipt.dollars=receipt.dollars+bonus;ease_dollars(bonus,true)
                end
            end
            return ok
        end
        if kind=='cash_clean' then cash(c.clean_hands_reward)
        elseif kind=='cash_execution' then cash(c.execution_reward)
        elseif kind=='cash_debt' then cash(c.debt_reward)
        elseif kind=='rerolls' then
            s.rerolls={count=(s.rerolls and s.rerolls.count or 0)+math.ceil(c.high_roller_rerolls*((PortraitRunRules and PortraitRunRules.factor('contracts_plus',1.5)) or 1)),after_shop=s.shop_serial}
            receipt.rerolls=math.ceil(c.high_roller_rerolls*((PortraitRunRules and PortraitRunRules.factor('contracts_plus',1.5)) or 1))
        elseif kind=='joker' then
            -- Only eligible Uncommon-or-higher rarities with positive native weights.
            local rarities={}
            for _,r in ipairs(SMODS.ObjectTypes.Joker.rarities) do
                if r.key~='Common' then
                    local def=SMODS.Rarities[r.key]
                    local w=def.get_weight and def:get_weight(r.weight,SMODS.ObjectTypes.Joker) or r.weight
                    w=(w or 0)*(G.GAME[tostring(r.key):lower()..'_mod'] or 1)
                    if w>0 and #P.pool('Joker',r.key)>0 then rarities[#rarities+1]={key=r.key,weight=w} end
                end
            end
            local r=P.choose(rarities,function(v) return v.weight end,'contract_rarity')
            if not r or not reward_card('Joker',r.key,'contract_joker') then cash(c.one_shot_fallback) end
        elseif kind=='mono' then
            cash(c.monochrome_reward);reward_card('Tarot',nil,'contract_tarot')
        elseif kind=='spectral' then
            if not reward_card('Spectral',nil,'contract_spectral') then
                s.pending_spectral=(s.pending_spectral or 0)+1;receipt.pending_spectral=true
            end
        end
        return receipt
    end
    function C.event(event,data)
        local s=C.state();if not s then return end
        local active=C.active()
        local finished,survivors={},{}
        -- Evaluate against one event snapshot in acquisition order. Remove ALL
        -- terminal contracts before rewards cause nested money/card callbacks.
        for i=1,#active do
            local a=active[i];local d=C.entries[a.id];local previous=a.progress
            if d and (not C.event_ready or C.event_ready(a,event,data or {})) then d.event(a,event,data or {}) end
            if event=='lost_run' then a.failed=true end
            local failed=not d or d.failure_condition(a,event,data)
            if failed or d.success_condition(a,event,data) then
                a.status=failed and 'failed' or 'complete'
                a.failure_event=failed and event or nil
                if failed and C.retry_failed and event~='lost_run' and C.retry_failed(a,event,data) then
                    if C.result_event then C.result_event(a,false,true) end
                    a.status=nil;a.failure_event=nil;a.failed=nil;survivors[#survivors+1]=a
                else finished[#finished+1]=a end
            else
                survivors[#survivors+1]=a
                if a.progress>previous then
                    play_sound('chips1',1.1,0.35)
                    attention_text{text=localize('k_ct_'..a.id)..' · '..a.progress..' / '..a.target,
                        scale=0.32,hold=0.65,major=G.consumeables,align='bm',offset={x=0,y=0.65+0.4*(i-1)}}
                end
            end
        end
        s.actives=survivors
        for _,a in ipairs(finished) do
            if a.status=='complete' then
                a.reward=C.complete_reward and C.complete_reward(a) or C.reward(C.entries[a.id].reward,a.mutation_cash_factor)
                if PortraitModifierUnlocks then PortraitModifierUnlocks.record('contracts',1,a.uid) end
            end
            if C.entries[a.id] and C.entries[a.id].finish then C.entries[a.id].finish(a) end
            if C.result_event then C.result_event(a,a.status=='complete') end
            s.last_result=copy_table(a)
            s.results=s.results or {};s.results[#s.results+1]=copy_table(a)
            s.history=s.history or {};s.history[#s.history+1]=copy_table(a)
        end
    end
    function C.shop()
        local s=C.state()
        if not s or not s.last_win or s.last_shop==s.last_win.token then return end
        s.last_shop=s.last_win.token;s.shop_serial=(s.shop_serial or 0)+1;s.offer=nil;s.offer_shown=nil
        C.shown_offer=nil
        if s.last_win.boss then C.event('ante_paid',{money=G.GAME.dollars}) end
        if s.rerolls and s.shop_serial>s.rerolls.after_shop then
            G.GAME.current_round.free_rerolls=G.GAME.current_round.free_rerolls+s.rerolls.count
            calculate_reroll_cost(true);s.rerolls=nil
        end
        if C.enabled() and P.roll('contract_offer')<math.min(1,C.config().contract_chance*((PortraitRunRules and PortraitRunRules.factor('frequent_contracts',2)) or 1)) then
            local eligible,owned={},{}
            for _,a in ipairs(C.active()) do owned[a.id]=true end
            for _,id in ipairs(C.order) do
                -- Old run snapshots have no individual preferences and retain
                -- their original pool. New runs capture Settings selections.
                local d=C.entries[id]
                if not owned[id] and (not C.config().contracts or C.config().contracts[id]~=false)
                    and (not d.eligible or d.eligible()) then
                    eligible[#eligible+1]=id
                end
            end
            s.offer=P.choose(eligible,function() return 1 end,'contract_kind')
        end
    end
    function C.accept(selection)
        local s=C.state();local id=s.offer
        if not id then return end
        local active=C.active()
        for _,a in ipairs(active) do if a.id==id then return end end
        local d=C.entries[id]
        if d.eligible and not d.eligible() then return false end
        if d.select and not d.select(selection) then return false end
        s.serial=(s.serial or 0)+1
        active[#active+1]={id=id,uid=s.serial,progress=0,target=id=='execution' and 2 or d.target and C.config()[d.target] or d.target_value,
            duration=d.duration,ante=G.GAME.round_resets.ante,shop=s.shop_serial,seen_destroyed={}}
        if d.shortcut~=false and PortraitRunRules and PortraitRunRules.has('contract_shortcut') then
            local a=active[#active];a.target=PortraitRunRules.contract_target(a.target);a.mutation_cash_factor=0.75
        end
        if d.init then d.init(active[#active],selection) end
        s.offer=nil
        if id=='execution' then
            local card=SMODS.create_card{set='Tarot',key='c_hanged_man',area=G.consumeables,
                edition='e_negative',skip_materialize=true,key_append='contract_execution'}
            card:add_to_deck();G.consumeables:emplace(card);card:start_materialize()
        end
        return true
    end
    function C.offer_terms(id)
        local d=C.entries[id]
        local target=id=='execution' and 2 or d.target and C.config()[d.target] or d.target_value
        local express=d.shortcut~=false and PortraitRunRules and PortraitRunRules.has('contract_shortcut')
        return {id=id,target=express and PortraitRunRules.contract_target(target) or target,
            mutation_cash_factor=express and 0.75 or nil}
    end
    function C.track(context)
        local s=C.state();if not s or not P.real(context) then return end
        if context.after and P.once(s,'last_hand_event',P.token()..':'..tostring(G.GAME.hands_played)) then
            local mono=false
            for suit in pairs(SMODS.Suits) do
                local all,count=true,0
                for _,card in ipairs(context.scoring_hand or {}) do
                    if not card.debuff then count=count+1;if not card:is_suit(suit) then all=false end end
                end
                if all and count>0 then mono=true;break end
            end
            s.last_hand={token=P.token(),mono=mono}
        end
        if P.won(context) and P.once(s,'won_token',P.token()) then
            s.last_win={token=P.token(),boss=context.beat_boss==true,ante=G.GAME.round_resets.ante}
            C.event('win',{boss=context.beat_boss,hands=G.GAME.current_round.hands_played,
                mono=s.last_hand and s.last_hand.token==P.token() and s.last_hand.mono})
        end
        if context.pre_discard then C.event('discard') end
        if context.using_consumeable then C.event('consume',{boss=G.GAME.facing_blind and G.GAME.blind.boss}) end
        if context.money_altered and context.from_shop and context.amount<0 then
            C.event('spend',{shop=s.shop_serial,amount=-context.amount})
        end
        if context.ending_shop then C.event('leave_shop',{shop=s.shop_serial});s.offer=nil end
        if context.remove_playing_cards then
            local count=0
            local owned={};for _,card in ipairs(G.playing_cards or {}) do owned[card]=true end
            for _,card in ipairs(context.removed or {}) do
                if card.playing_card and card.ability and (owned[card] or card.removed or card.destroyed or card.shattered) then
                    local id=card.ability.ct_destroyed_id
                    if not id then
                        s.destroy_serial=(s.destroy_serial or 0)+1;id=s.destroy_serial;card.ability.ct_destroyed_id=id
                    end
                    s.seen_destroyed=s.seen_destroyed or {}
                    if not s.seen_destroyed[tostring(id)] then
                        s.seen_destroyed[tostring(id)]=true;count=count+1
                    end
                end
            end
            C.event('destroy',{count=count})
        end
    end
    local copy=copy_card
    function copy_card(...)
        local card=copy(...);if card.ability then card.ability.ct_destroyed_id=nil end;return card
    end
end
