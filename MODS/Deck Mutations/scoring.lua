-- Individual contexts arrive in the engine's actual scoring order. Repetitions
-- of the same card reuse its position; they never advance the chain twice.
return function(M,level)
    local sequence
    function M.reset_sequence() sequence={index=0} end
    function M.sequence_bonus(card)
        sequence=sequence or {index=0}
        if sequence.card~=card then
            sequence.previous=sequence.suits
            sequence.card=card;sequence.index=sequence.index+1
        end
        local suits={}
        if not SMODS.has_no_suit(card) then
            for suit in pairs(SMODS.Suits) do
                if card:is_suit(suit) then suits[suit]=true end
            end
        end
        local matches=false
        for suit in pairs(suits) do if sequence.previous and sequence.previous[suit] then matches=true end end
        sequence.suits=suits
        return level('chain_reaction')>0 and (sequence.index-1)*10 or 0,
            level('resonance')>0 and matches and 4 or 0
    end
end
