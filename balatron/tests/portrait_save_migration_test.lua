function copy_table(t)
    local out={}; for k,v in pairs(t) do out[k]=type(v)=='table' and copy_table(v) or v end; return out
end
G={P_CENTERS={e_negative={config={card_limit=1}}}}
local M=dofile('src/portrait_save_migration.lua')
local saved={GAME={dollars=42,round=8,pseudorandom={seed='KEEP'},current_round={voucher='v_blank'},round_resets={},
    hands={Pair={level=7}},starting_params={hand_size=8}},cardAreas={
    jokers={config={type='joker',card_limit=6},cards={
        {ability={extra=24},edition={negative=true,type='negative'},save_fields={center='j_joker'}},
        {ability={extra=0},save_fields={center='j_chaos'}}}},
    shop_vouchers={config={type='shop',card_limit=1},cards={{ability={},save_fields={center='v_blank'}}}}}}
local defaults={starting_params={hand_size=8,play_limit=5},current_round={},round_resets={free_rerolls=0},hands={Pair={level=1}}}
local new=M.convert(saved,defaults)
assert(not saved.SCORING_CALC and saved.cardAreas.jokers.config.card_limit==6)
assert(new~=saved and new.SCORING_CALC.key=='multiply')
assert(new.GAME.dollars==42 and new.GAME.round==8 and new.GAME.pseudorandom.seed=='KEEP')
assert(new.GAME.hands.Pair.level==7 and new.GAME.starting_params.play_limit==5)
assert(new.GAME.current_round.voucher[1]=='v_blank' and new.GAME.current_round.voucher.spawn.v_blank)
assert(new.GAME.round_resets.free_rerolls==1)
local area=new.cardAreas.jokers
assert(area.config.card_limit==nil and area.config.card_limits.base==5 and area.config.card_limits.total_slots==6)
assert(area.cards[1].ability.extra==24 and area.cards[1].ability.card_limit==1)
assert(area.cards[1].edition.key=='e_negative' and area.cards[1].edition.card_limit==1)
assert(new.cardAreas.shop_vouchers.cards[1].shop_voucher)
assert(M.convert(new,defaults)==new)
print('PASS: legacy migration preserves original, seed, money, hand levels, negative slots, vouchers; idempotent')
