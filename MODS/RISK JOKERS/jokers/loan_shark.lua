return {
    key='loan_shark',name='Loan Shark',cost_key='loan_shark_cost',
    initial_state=function() return {xmult=3.5} end,
    mult=function(s) return s.xmult end,
    vars=function(s) return {s.xmult,4,0.5,1} end,
    secondary=function(card,context,c,M)
        if not M.won(card,context) then return end
        local s=card.ability.extra
        if G.GAME.dollars>=4 then
            -- Synchronous payment: later copies see the money actually left.
            ease_dollars(-4,true)
            return {message='-$4',colour=G.C.MONEY,card=card}
        end
        local before=s.xmult
        s.xmult=math.max(1,s.xmult-0.5)
        return {message='X'..before..' > X'..s.xmult,colour=G.C.MULT,card=card}
    end,
}
