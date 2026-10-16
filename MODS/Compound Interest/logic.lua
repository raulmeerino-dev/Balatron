-- Pure production rules, shared with deterministic tests. No global state.
local L = {}
function L.factor(extra)
    -- Compute from an integer count instead of repeatedly adding a float.
    return math.floor((extra.initial_xmult + extra.growth_per_round*extra.won_rounds)*1e9+0.5)/1e9
end
function L.advance(extra, context, state)
    if not (context.end_of_round and context.main_eval) or context.blueprint or
       context.repetition or context.retrigger_joker or context.individual or context.game_over or
       state.debuff or not state.owned or not state.won or not state.played then return false end
    if extra.last_won_round == state.round then return false end
    extra.last_won_round = state.round
    extra.won_rounds = extra.won_rounds + 1
    return true
end
function L.eligible(state)
    return state.normal_joker and state.unlocked and not state.banned and
           (not state.used or state.showman)
end
function L.roll(draw, probability)
    return draw >= 0 and draw < probability
end
function L.format(number, spanish)
    local text=string.format('%.2f',number)
    return spanish and text:gsub('%.',',') or text
end
return L
