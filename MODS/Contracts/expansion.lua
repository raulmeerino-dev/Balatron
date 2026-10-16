-- Approved expansion Contracts. Persistent state contains IDs and plain values only.
return function(C,P)
    local X=require('portrait_expansion48')
    PortraitContracts=C
    local names={recasting='C01',embargo='C02',no_repeat='C03',cash_register='C04',debut='C05',
        back_row='C06',domino_effect='C07',administrative_silence='C08',protected_witnesses='C09',seed_capital='C10'}
    C.expansion_ids=names
    local function alive_jokers()
        local out={};for _,card in ipairs(G.jokers and G.jokers.cards or {}) do
            if not card.removed and not card.getting_sliced then out[#out+1]=card end
        end;return out
    end
    local function in_blind(a,d) return a.blind_token and a.blind_token==(d.token or P.token()) end
    local function init(a)
        a.progress=0;a.failed=nil;a.complete=nil;a.first_cast=nil;a.blind_token=nil;a.ranks={};a.hand_count=0;a.activations={}
        a.targets=nil;a.protected=nil;a.initial_ids=nil;a.purchases={};a.bosses=0;a.pending_choice=nil;a.waiting_for_pay=nil
    end
    function C.reset(a)
        local selection=a.selected_hand
        if C.entries[a.id].finish then C.entries[a.id].finish(a,true) end
        init(a)
        if a.id=='debut' then a.selected_hand=selection end
    end
    function C.event_ready(a,event,data)
        local wait=a.exp48_retry_wait
        if not wait or event=='lost_run' then return true end
        local ante=G.GAME.round_resets.ante
        local start=event=='start_blind' or event=='shuffled'
        local ready
        if wait.duration=='next_shop' then
            ready=(data.shop or C.state().shop_serial or 0)>wait.shop
            if ready then a.shop=wait.shop end
        elseif wait.duration=='ante' then ready=ante>wait.ante
        elseif wait.duration=='next_boss' then ready=start and data.token~=wait.token and G.GAME.blind.boss
        else ready=start and data.token~=wait.token end
        if ready then a.exp48_retry_wait=nil;a.ante=ante;return true end
        return false
    end
    function C.debut_hands()
        local out={}
        for _,hand in ipairs(G.handlist or {}) do
            local h=G.GAME.hands[hand]
            if h and h.visible and (h.played or 0)==0 then
                for _,center in ipairs(G.P_CENTER_POOLS.Planet or {}) do
                    if center.config.hand_type==hand and center.unlocked~=false and not G.GAME.banned_keys[center.key]
                        and SMODS.add_to_pool(center,{source='contract'}) then
                        out[#out+1]={hand=hand,planet=center.key};break
                    end
                end
            end
        end
        return out
    end
    local function register(d)
        d.expansion_id=names[d.id];d.target_value=d.target_value or 1;d.duration=d.duration or 'next_blind'
        -- Structural requirements (two different casts, two non-overlapping hands)
        -- cannot lose a step without removing the contract's central constraint.
        d.shortcut=d.id=='embargo' or d.id=='cash_register' or d.id=='domino_effect' or d.id=='seed_capital'
        local eligible=d.eligible
        d.eligible=function()
            if d.id=='domino_effect' or d.id=='seed_capital' then
                for _,a in ipairs(C.active()) do if a.id=='administrative_silence' then return false end end
            end
            return X.unlocked(d.expansion_id) and (not eligible or eligible())
        end
        d.init=d.init or init
        -- Expansion contracts may display progress before their required victory.
        d.success_condition=d.success_condition or function(a) return a.complete==true end
        C.register(d)
    end
    register{id='recasting',target_value=2,duration='blinds',reward={kind='pack',key='p_buffoon_mega_1'},
        event=function(a,e,d)
            if e~='win' then return end
            local current=alive_jokers()
            if #current<3 then a.failed=true;return end
            if not a.first_cast then
                a.first_cast={};for _,card in ipairs(current) do a.first_cast[X.id(card)]=true end;a.progress=1
            else
                for _,card in ipairs(current) do if a.first_cast[X.id(card)] then a.failed=true;return end end
                a.progress=2;a.complete=true
            end
        end}
    register{id='embargo',target_value=3,duration='blinds',reward={kind='tag',key='tag_coupon'},
        event=function(a,e,d)
            if e=='paid_purchase' or e=='paid_reroll' then a.failed=(d.amount or 0)>0 or a.failed
            elseif e=='win' then a.progress=a.progress+1;a.complete=a.progress>=a.target end
        end}
    register{id='no_repeat',target_value=2,reward={kind='cards',keys={'c_death','c_strength'}},
        event=function(a,e,d)
            if e=='start_blind' and not a.blind_token then a.blind_token=d.token
            elseif e=='hand' and in_blind(a,d) then
                local ranks={};for _,card in ipairs(d.scoring_hand or {}) do
                    if not card.debuff and not SMODS.has_no_rank(card) then ranks[tostring(card:get_id())]=true end
                end
                if not next(ranks) then a.failed=true;return end
                for rank in pairs(ranks) do if a.ranks[rank] then a.failed=true end;a.ranks[rank]=true end
                a.hand_count=a.hand_count+1;a.progress=math.min(a.hand_count,a.target)
            elseif e=='win' and in_blind(a,d) then a.complete=a.hand_count>=2;a.failed=not a.complete end
        end}
    register{id='cash_register',target_value=12,reward={kind='cards',keys={'c_talisman','c_magician'}},
        event=function(a,e,d)
            if e=='start_blind' and not a.blind_token then a.blind_token=d.token
            elseif e=='card_money' and in_blind(a,d) then a.progress=a.progress+math.max(0,d.amount or 0)
            elseif e=='win' and in_blind(a,d) then a.waiting_for_pay=true
            elseif e=='blind_paid' and in_blind(a,d) then a.complete=a.progress>=a.target;a.failed=not a.complete end
        end}
    register{id='debut',duration='next_boss',reward={kind='planets'},eligible=function() return #C.debut_hands()>0 end,
        select=function(selection)
            for _,v in ipairs(C.debut_hands()) do if v.hand==selection then return true end end
        end,
        init=function(a,selection)
            init(a);a.selected_hand=selection
            for _,v in ipairs(C.debut_hands()) do if v.hand==selection then a.planet=v.planet;break end end
        end,
        event=function(a,e,d)
            if e=='hand' and d.hand==a.selected_hand and not d.boss then a.failed=true
            elseif e=='win' and d.boss then a.complete=d.hand==a.selected_hand;a.progress=a.complete and 1 or 0;a.failed=not a.complete end
        end}
    register{id='back_row',reward={kind='cards',keys={'c_cryptid'}},eligible=function() return #(G.playing_cards or {})>=10 end,
        event=function(a,e,d)
            if e=='shuffled' and not a.blind_token then
                a.blind_token=d.token;a.targets={}
                for i=1,math.min(3,#(G.deck and G.deck.cards or {})) do a.targets[X.id(G.deck.cards[i])]=true end
            elseif e=='hand' and in_blind(a,d) then
                for _,card in ipairs(d.scoring_hand or {}) do if not card.debuff and a.targets and a.targets[X.id(card)] then a.progress=1 end end
            elseif e=='destroy_ids' and a.targets and a.progress==0 then
                for id in pairs(d.ids or {}) do a.targets[id]=nil end
                if not next(a.targets) then a.failed=true end
            elseif e=='win' and in_blind(a,d) then a.complete=a.progress>=1;a.failed=not a.complete end
        end}
    register{id='domino_effect',target_value=6,reward={kind='multiplier',mult=1.75,hands=3},
        event=function(a,e,d)
            if e=='start_blind' and not a.blind_token then a.blind_token=d.token
            elseif e=='score_card' and in_blind(a,d) then
                local key=tostring(d.hand_token)..':'..X.id(d.card)
                a.activations[key]=(a.activations[key] or 0)+1;a.progress=math.max(a.progress,a.activations[key])
            elseif e=='win' and in_blind(a,d) then a.complete=a.progress>=a.target;a.failed=not a.complete end
        end}
    local function silence(a,on)
        for _,card in ipairs(alive_jokers()) do SMODS.debuff_card(card,on,'contract_silence_'..a.uid) end
    end
    register{id='administrative_silence',reward={kind='tag',key='tag_negative'},
        eligible=function()
            for _,a in ipairs(C.active()) do if a.id=='domino_effect' or a.id=='seed_capital' then return false end end
            return true
        end,
        event=function(a,e,d)
            if e=='start_blind' and not a.blind_token then a.blind_token=d.token;silence(a,true)
            elseif e=='joker_added' and in_blind(a,d) then silence(a,true)
            elseif e=='win' and in_blind(a,d) then a.progress=1;a.complete=true end
        end,finish=function(a,retry)
            if a.status=='complete' and not retry then
                local s=C.state();s.silences_to_clear=s.silences_to_clear or {};s.silences_to_clear[#s.silences_to_clear+1]=a.uid
            else silence(a,false) end
        end}
    register{id='protected_witnesses',reward={kind='cards',keys={'c_chariot','c_trance'}},
        eligible=function() return G.hand and G.hand.config.card_limit>3 end,
        event=function(a,e,d)
            if e=='start_blind' and not a.blind_token then a.blind_token=d.token
            elseif e=='initial_hand' and in_blind(a,d) and not a.initial_ids then
                a.initial_ids={};for _,card in ipairs(G.hand.cards) do a.initial_ids[#a.initial_ids+1]=X.id(card) end
                if #a.initial_ids<=3 then a.failed=true else a.pending_choice=true end
            elseif (e=='played_ids' or e=='discard_ids' or e=='destroy_ids') and a.protected then
                for id in pairs(d.ids or {}) do if a.protected[id] then a.failed=true end end
            elseif e=='win' and in_blind(a,d) then a.complete=a.protected~=nil;a.progress=a.complete and 1 or 0;a.failed=not a.complete end
        end}
    register{id='seed_capital',target_value=8,duration='two_bosses',reward={kind='contraband_choice',count=3},
        eligible=function() return C.contraband_reward_pool and #C.contraband_reward_pool()>=3 end,
        event=function(a,e,d)
            if e=='joker_bought' and not d.rented then a.purchases[d.id]=d.amount
            elseif e=='joker_sold' and a.purchases[d.id]~=nil and not d.rented then
                a.progress=math.max(a.progress,d.amount-a.purchases[d.id]);a.purchases[d.id]=nil;a.complete=a.progress>=a.target
            elseif e=='win' and d.boss then a.bosses=a.bosses+1;if a.bosses>=2 and not a.complete then a.failed=true end end
        end}
    local track=C.track
    function C.track(context)
        local s=C.state();if not s then return end
        -- Forced discards (The Hook) also expose per-card discard contexts.
        if context.discard and context.other_card and not context.blueprint and not context.retrigger_joker then
            C.event('discard_ids',{ids={[X.id(context.other_card)]=true}})
        end
        if P.real(context) then
            if context.setting_blind then C.event('start_blind',{token=P.token()}) end
            if context.before then
                local ids={};for _,card in ipairs(context.full_hand or G.play.cards) do ids[X.id(card)]=true end
                C.event('played_ids',{ids=ids})
            end
            if context.after and P.once(s,'exp48_last_hand',P.token()..':'..tostring(G.GAME.hands_played)) then
                s.exp48_hand=context.scoring_name
                C.event('hand',{token=P.token(),hand=context.scoring_name,scoring_hand=context.scoring_hand,boss=G.GAME.blind.boss})
            end
            if context.pre_discard then
                local ids={};for _,card in ipairs(context.full_hand or G.hand.highlighted) do ids[X.id(card)]=true end
                C.event('discard_ids',{ids=ids})
            end
            if context.remove_playing_cards then
                local ids={};for _,card in ipairs(context.removed or {}) do ids[X.id(card)]=true end
                C.event('destroy_ids',{ids=ids})
            end
            if context.buying_card and context.card then
                local card=context.card;local amount=card.cost or 0
                if card.ability.set=='Joker' then
                    C.event('joker_bought',{id=X.id(card),amount=amount,rented=card.ability.exp48_lease~=nil})
                end
            end
            if context.selling_card and context.card and context.card.ability.set=='Joker' then
                local card=context.card
                C.event('joker_sold',{id=X.id(card),amount=card.sell_cost or 0,rented=card.ability.exp48_lease~=nil})
            end
        end
        return track(context)
    end
    -- C.track supplies the latest chosen poker class (including Open Interpretation).
    local event=C.event
    function C.event(e,d)
        d=d or {};d.token=d.token or P.token()
        if e=='win' then d.hand=C.state().exp48_hand end
        return event(e,d)
    end
    X.listen(function(context)
        if not C.state() then return end
        if context.exp48_blind_shuffled then C.event('shuffled',{token=P.token()}) end
        if context.exp48_initial_hand or context.first_hand_drawn then C.event('initial_hand',{token=P.token()}) end
        if context.exp48_blind_paid then
            C.event('blind_paid',{token=P.token()})
        end
        if context.exp48_money and context.native_playing and not context.converted and (context.amount or 0)>0 then
            C.event('card_money',{token=P.token(),amount=context.amount})
        end
        if context.exp48_score_card and context.card then
            C.event('score_card',{token=P.token(),card=context.card,hand_token=context.hand_token or G.GAME.hands_played})
        end
    end)
    -- A new Joker is debuffed before passive add_to_deck processing.
    local add=Card.add_to_deck
    function Card:add_to_deck(...)
        if self.ability.set=='Joker' and G.STAGE==G.STAGES.RUN and G.GAME and G.GAME.blind
            and G.GAME.blind.config and G.GAME.blind.config.blind and C.state() then
            for _,a in ipairs(C.active()) do
                if a.id=='administrative_silence' and a.blind_token==P.token() then
                    self.ability.debuff_sources=self.ability.debuff_sources or {}
                    self.ability.debuff_sources['contract_silence_'..a.uid]=true
                    SMODS.recalc_debuff(self)
                end
            end
        end
        return add(self,...)
    end
    -- Native spending receipts cover normal/Black Market purchases, packs,
    -- vouchers and both Carousel rows, without mistaking a cancelled UI for payment.
    local career=inc_career_stat
    function inc_career_stat(key,amount,...)
        if key=='c_shop_dollars_spent' and (amount or 0)>0 and G.STAGE==G.STAGES.RUN and C.state() then
            C.event('paid_purchase',{amount=amount})
        end
        return career(key,amount,...)
    end
    local evaluate_round=G.FUNCS.evaluate_round
    G.FUNCS.evaluate_round=function(...)
        local result=evaluate_round(...)
        local s=C.state()
        if s then
            for _,uid in ipairs(s.silences_to_clear or {}) do silence({uid=uid},false) end
            s.silences_to_clear=nil
        end
        return result
    end
end
