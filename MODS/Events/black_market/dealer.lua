return function(B)
    local D={expression=0,phrase=nil,elapsed=0,colour={1,0.94,0.82,0}}
    B.dealer=D
    local function cosmetic(key) return B.roll('cosmetic_dealer_'..key) end
    function B.dealer_react(kind)
        local c=B.config()
        D.expression=kind=='contraband' and 2 or kind=='purchase' and 1 or
            B.state().heat>=c.heat_high and 3 or B.state().heat>=c.heat_medium and 2 or 0
        if kind=='enter' or cosmetic('comment')<(kind=='contraband' and c.dealer_contraband_comment_chance or c.dealer_normal_comment_chance) then
            D.phrase=math.min(6,math.floor(cosmetic('phrase')*6)+1)
            D.elapsed=0; D.colour[4]=1
        end
    end
    local update=Game.update
    function Game:update(dt,...)
        local result=update(self,dt,...)
        if B.active and D.phrase then
            D.elapsed=D.elapsed+dt
            local duration=B.config().dealer_phrase_seconds
            D.colour[4]=math.max(0,math.min(1,(duration-D.elapsed)/0.4))
            if D.elapsed>=duration then D.phrase=nil; B.refresh_sign() end
        end
        return result
    end
end

