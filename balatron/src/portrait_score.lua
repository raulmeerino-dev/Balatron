local S={hand_names={}}
function S.begin_run(loading)
    S.hand_names={}
    S.record_pending=nil
    local game=G.GAME
    if not loading then game.portrait_record_hand=nil;game.portrait_scored_hand=nil
    else game.portrait_scored_hand=game.portrait_scored_hand or game.portrait_record_hand end
    game.portrait_record_feedback_hand=loading and
        (game.portrait_record_feedback_hand or game.portrait_record_hand) or nil
    game.portrait_best_hand=loading and (game.portrait_best_hand or game.round_scores.hand.amt or 0) or 0
    game.portrait_overkill=loading and game.portrait_overkill or {dollars=0,best=0,blinds=0}
    game.portrait_overkill=game.portrait_overkill or {dollars=0,best=0,blinds=0}
    -- Old saves have no round identity. Never reuse their pending calculation;
    -- a paid result outside resolution belongs to an already settled round.
    local old=game.current_round.portrait_overkill
    if loading and old and not old.round then
        if old.paid and (G.STATE==G.STATES.SHOP or G.STATE==G.STATES.BLIND_SELECT) then
            game.portrait_overkill.cashout_round=game.round
        end
        game.current_round.portrait_overkill=nil
    end
end
function S.hand_label(name)
    local hand=G.GAME.hands[S.hand_names[name]]
    return name~='' and hand and (name..' · '..tostring(hand.played or 0)) or name
end
function S.hand_usage(name)
    if not name or name=='' then return '' end
    local hands=G.GAME.hands
    local key=S.hand_names[name]
    -- A resumed HUD can be drawn before the first selection recalculates its
    -- display-name mapping. Resolve native localized names in that case.
    if not key then
        if hands[name] then key=name
        elseif name==localize('Royal Flush','poker_hands') then key='Straight Flush'
        else
            for id in pairs(hands) do
                if localize(id,'poker_hands')==name then key=id;break end
            end
        end
    end
    local hand=key and hands[key]
    return 'x'..tostring(hand and hand.played or 0)
end
function S.bonus(score,required,boss)
    -- Native scores use doubles. Invalid/already-overflowed inputs cannot
    -- supply a meaningful ratio and must never put NaN/Infinity into money.
    if type(score)~='number' or type(required)~='number' or
        score~=score or required~=required or score==math.huge or
        required==math.huge or required<=0 or score<required then return 0,0,0,0 end
    local ratio=score/required
    if ratio<10 then return 0,ratio,0,0 end
    -- Log subtraction remains finite even when the quotient overflows.
    local magnitude=ratio<math.huge and math.log10(ratio) or math.log10(score)-math.log10(required)
    local base=math.floor(2.5*magnitude+1e-12)
    return boss and math.ceil(base*1.5) or base,ratio<math.huge and ratio or nil,magnitude,base
end
function S.category(ratio,magnitude)
    if (ratio and ratio>=1000) or (not ratio and magnitude>=3) then return 'OBLITERATED' end
    if (ratio and ratio>=100) or (not ratio and magnitude>=2) then return 'ABSURD OVERKILL' end
    if (ratio and ratio>=50) or (not ratio and magnitude>=math.log10(50)) then return 'MASSIVE OVERKILL' end
    return 'OVERKILL'
end
function S.ratio_text(ratio,magnitude)
    if ratio and ratio<10000 then return string.format('%.1f',math.floor(ratio*10)/10) end
    local exponent=math.floor(magnitude)
    local mantissa=math.floor(10^(magnitude-exponent)*100+0.5)/100
    if mantissa>=10 then mantissa=1;exponent=exponent+1 end
    return string.format('%.2fe%d',mantissa,exponent)
end
function S.evaluate()
    local game=G.GAME
    local stats=game.portrait_overkill
    if stats.cashout_round and stats.cashout_round>=game.round then return 0 end
    local bonus=game.current_round.portrait_overkill
    if not bonus or bonus.round~=game.round then
        local dollars,ratio,magnitude,base=S.bonus(game.chips,game.blind.chips,game.blind.boss)
        bonus={round=game.round,ante=game.round_resets.ante,boss=not not game.blind.boss,
            dollars=dollars,base=base,ratio=ratio,log10=magnitude,paid=false,
            category=S.category(ratio,magnitude),ratio_text=S.ratio_text(ratio,magnitude)}
        game.current_round.portrait_overkill=bonus
    end
    if bonus.paid then return 0 end
    bonus.payout=bonus.payout or bonus.dollars*((PortraitRunRules and PortraitRunRules.factor('overkill_plus',2)) or 1)
    if bonus.dollars>0 and not bonus.jokers_notified then
        -- Persist the receipt together with native Joker abilities. UI rebuilds
        -- and resumed round summaries cannot deliver the same victory twice.
        bonus.jokers_notified=true
        if SMODS and SMODS.calculate_context then
            SMODS.calculate_context{portrait_overkill=tostring(bonus.ante)..':'..tostring(bonus.round),
                overkill_log10=bonus.log10,no_blueprint=true}
        end
    end
    if bonus.dollars>0 and not (G.round_eval and G.round_eval.portrait_overkill_shown) then
        if G.round_eval then G.round_eval.portrait_overkill_shown=true end
        add_round_eval_row{bonus=true,name='portrait_overkill',dollars=bonus.payout,
            label=bonus.category,ratio_text='×'..bonus.ratio_text,boss=bonus.boss,compact_money=true,pitch=1.15}
    end
    return bonus.payout
end
function S.paid()
    local game=G.GAME;local bonus=game.current_round.portrait_overkill
    if not bonus or bonus.round~=game.round or bonus.paid or bonus.dollars<=0 then return end
    bonus.paid=true
    if PortraitModifierUnlocks then PortraitModifierUnlocks.record('overkill',bonus.ratio or 1000,nil,true) end
    local stats=game.portrait_overkill
    stats.dollars=(stats.dollars or 0)+bonus.dollars
    stats.blinds=(stats.blinds or 0)+1
    stats.boss_blinds=(stats.boss_blinds or 0)+(bonus.boss and 1 or 0)
    local best_log=stats.best_log10 or ((stats.best or 0)>0 and math.log10(stats.best) or 0)
    if bonus.log10>best_log then
        stats.best=bonus.ratio;stats.best_log10=bonus.log10;stats.best_ratio_text=bonus.ratio_text
    end
    PortraitQOL.career('c_overkill_dollars',bonus.dollars)
end
function S.cash_out(amount)
    local game,round=G.GAME,G.GAME.round
    G.E_MANAGER:add_event(Event{trigger='immediate',func=function()
        if G.GAME~=game or game.round~=round then return true end
        local stats=game.portrait_overkill
        if stats.cashout_round and stats.cashout_round>=round then return true end
        -- Credit, receipt and statistics share one synchronous event/snapshot.
        -- Resuming or replaying the cash-out transition cannot credit it again.
        ease_dollars(amount,true)
        S.paid()
        stats.cashout_round=round
        save_run()
        return true
    end})
end
function S.record(amount)
    if type(amount)~='number' or amount~=amount or amount==math.huge then return end
    amount=math.floor(amount)
    local game=G.GAME
    local is_record=amount>(game.portrait_best_hand or 0)
    if is_record then game.portrait_best_hand=amount end
    -- The native hand counter advances after scoring. It identifies this play
    -- even if another hook reports a revised score for the same hand. Store the
    -- receipt before dispatch so re-entry, save/load and UI replay are harmless.
    local hand_id=tostring(game.round)..':'..tostring(game.hands_played)
    if game.portrait_scored_hand~=hand_id then
        game.portrait_scored_hand=hand_id
        if is_record then game.portrait_record_hand=hand_id end
        if SMODS and SMODS.calculate_context then
            -- One authoritative result for both record growth and broken streaks.
            SMODS.calculate_context{portrait_hand_result=hand_id,
                portrait_hand_record=is_record and hand_id or nil,record_score=amount,no_blueprint=true}
        end
    end
    if not is_record then return end
    -- A revised result may improve the stored best without replaying the
    -- celebration for the same hand, even after its popup expired or a reload.
    if game.portrait_record_feedback_hand==hand_id then
        if S.record_pending and S.record_pending.game==game then S.record_pending.amount=amount end
        return
    end
    game.portrait_record_feedback_hand=hand_id
    if S.record_pending and S.record_pending.game==game then
        S.record_pending.amount=amount;return
    end
    local pending={game=game,amount=amount}
    S.record_pending=pending
    G.E_MANAGER:add_event(Event{blocking=false,func=function()
        if S.record_pending==pending then S.record_pending=nil end
        if G.GAME~=game then return true end
        require('portrait_reward_fx').record(pending.amount)
        return true
    end})
end
function S.install()
    local info=G.FUNCS.get_poker_hand_info
    G.FUNCS.get_poker_hand_info=function(...)
        local key,display,hands,scoring,raw=info(...)
        S.hand_names[display]=key
        return key,display,hands,scoring,raw
    end
    local record=check_and_set_high_score
    function check_and_set_high_score(kind,amount)
        if kind=='hand' and type(amount)=='number' then S.record(amount) end
        return record(kind,amount)
    end
end
return S
