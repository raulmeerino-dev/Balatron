local function value() return math.max(1,(30-4*(G.GAME.current_round.hands_played or 0))/10) end
return {
    key='overheated',name='Overheated',cost_key='overheated_cost',
    initial_state=function() return {xmult=3} end,
    mult=function() return value() end,
    vars=function(s) return {s.xmult,0.4,1} end,
    secondary=function(card,context,c,M)
        if not M.real(card,context) then return end
        local s=card.ability.extra
        if context.setting_blind then s.xmult=3 end
        if context.after then
            local token=M.blind_token()..':'..G.GAME.hands_played
            if s.last_decay==token then return end
            s.last_decay=token
            local before=value()
            s.xmult=math.max(1,math.floor((before-0.4)*10+0.5)/10)
            if before~=s.xmult then
                return {message='X'..before..' > X'..s.xmult,colour=G.C.MULT,card=card}
            end
        end
    end,
}
