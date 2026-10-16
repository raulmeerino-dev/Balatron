return function(P,M,R)
    local function feedback(id,message,colour)
        if M.feedback then card_eval_status_text(G.deck,'extra',nil,nil,nil,M.feedback({id},message or '',colour or G.C.GREEN)) end
    end
    function R.fusion_completed(card)
        if PortraitModifierUnlocks then PortraitModifierUnlocks.record('fusions',1,'card:'..tostring(card.sort_id)) end
        if R.has('fusion_workshop') then
            G.consumeables:change_size(1);feedback('fusion_workshop','+1')
            G.E_MANAGER:add_event(Event{func=function() save_run();return true end})
        end
    end
    function R.contraband_used()
        if R.has('contraband_credit') then M.state().purchase_credit=true;feedback('contraband_credit') end
    end
    function R.contract_target(target)
        return R.has('contract_shortcut') and math.max(1,target-1) or target
    end
    local calculate=R.calculate
    function R.calculate(c)
        local s=M.state()
        if s and P.real(c) then
            if c.setting_blind and P.once(s,'expansion_blind',P.token()) then
                s.seal_relay_used=false
                if R.has('discard_reserve') then
                    ease_discard(s.reserved_discards or 0);s.reserved_discards=0
                end
                if R.has('field_reserves') and c.blind and c.blind.boss then
                    ease_hands_played(1);ease_discard(1);feedback('field_reserves','+1')
                end
            end
            if c.pre_discard and not c.hook and R.has('seal_relay') and not s.seal_relay_used then
                s.seal_relay_used=true
                local cards={};for _,card in ipairs(c.full_hand or {}) do cards[#cards+1]=card end
                table.sort(cards,function(a,b) return a.T.x<b.T.x end)
                local seal,target
                for _,card in ipairs(cards) do
                    if card.seal and not seal then seal=card.seal end
                    if not card.seal and not target then target=card end
                end
                if seal and target then target:set_seal(seal);feedback('seal_relay') end
            end
            if c.using_consumeable and c.consumeable and c.consumeable.ability.set=='Planet' and R.has('orbital_echo') then
                -- Native Planet application has already run; ties use native hand order.
                local hand
                for _,key in ipairs(G.handlist) do local h=G.GAME.hands[key]
                    if h and h.visible and (not hand or h.level<G.GAME.hands[hand].level) then hand=key end
                end
                -- This +1 belongs to the Mutation, not the Planet's own level grant.
                if hand then level_up_hand(c.consumeable,hand,true,1,'mutation');feedback('orbital_echo','+1') end
            end
            if c.buying_card and c.card and c.card.ability.set=='Joker' and s.purchase_credit and R.has('contraband_credit') then
                -- Refund after native payment, including shop Fusion transactions.
                -- Paying first preserves native affordability and purchase validation.
                s.purchase_credit=nil;ease_dollars(math.max(0,c.card.cost or 0),true);feedback('contraband_credit')
            end
            if c.open_booster then
                s.pack_serial=(s.pack_serial or 0)+1;s.pack_refunded=false
            end
            if c.skipping_booster and R.has('pack_refund') and not s.pack_refunded then
                s.pack_refunded=true
                local amount=2*math.max(0,G.GAME.pack_choices or 0)
                if amount>0 then ease_dollars(amount,true);feedback('pack_refund','+$'..amount,G.C.MONEY) end
            end
            if P.won(c) and P.once(s,'expansion_win',P.token()) then
                if R.has('discard_reserve') then s.reserved_discards=math.min(2,math.max(0,G.GAME.current_round.discards_left or 0)) end
                if c.beat_boss and R.has('deck_pruning') then
                    local target
                    for _,card in ipairs(G.playing_cards or {}) do
                        if not card.removed and not card.getting_sliced and card.config.center==G.P_CENTERS.c_base and not card.seal and not card.edition
                            and not SMODS.is_eternal(card,{destroy_cards=true}) and card:get_id()>0 and
                            (not target or card:get_id()<target:get_id() or card:get_id()==target:get_id() and card.playing_card<target.playing_card) then target=card end
                    end
                    if target then
                        -- Native dissolve can be paused by a completed Contract modal.
                        -- Persist its pending removal, without replaying rewards on load.
                        target.ability.dm_pruning_pending=true
                        SMODS.destroy_cards(target);feedback('deck_pruning')
                    end
                end
            end
        end
        return calculate(c)
    end
    local start=Game.start_run
    function Game:start_run(args,...)
        local result=start(self,args,...)
        if args and args.savetext then for _,card in ipairs(G.playing_cards or {}) do
            if card.ability.dm_pruning_pending then card:start_dissolve() end
        end end
        return result
    end
end
