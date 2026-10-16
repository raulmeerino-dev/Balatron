local L=assert(loadfile('../MODS/Compound Interest/options_logic.lua'))()
local function roll(kind,value)
    local i=0
    return L.roll(function() i=i+1;return i==1 and kind or value end,5)
end
for _,case in ipairs({{0,'chips',10,1000},{0.30,'mult',1,100},{0.55,'xmult',0.25,50},
    {0.80,'dollars',1,100},{0.92,'interest',1,20},{0.97,'combo',1,100}}) do
    local low,high=roll(case[1],0),roll(case[1],1)
    assert(low.kind==case[2] and high.kind==case[2])
    assert(low.value==case[3] and high.value==case[4],case[2])
    local effect=L.effect(high)
    assert(effect.chips==1000 or effect.mult==100 or effect.x_mult==50 or effect.dollars==100)
end
assert(L.effect(roll(0.6,0)).x_mult==0.25)
assert(L.interest_base{dollars=200,interest_cap=25,interest_amount=1}==5)
assert(L.interest_base{dollars=50,interest_cap=50,interest_amount=2}==20)
assert(L.interest_base{dollars=200,modifiers={no_interest=true}}==0)
local calls=0
local function rng() calls=calls+1;return calls%10/10 end
local e={selected='B'}
assert(L.prepare(e,'1:0',rng,5) and calls==4 and e.selected=='B')
local saved={selected=e.selected,hand_key=e.hand_key,a=e.a,b=e.b}
assert(not L.prepare(saved,'1:0',rng,5) and calls==4)
assert(L.active(saved)==saved.b)
assert(L.prepare(saved,'1:1',rng,5) and calls==8 and saved.selected=='B')
print('PASS: bounds, jackpots, harmful XMult, immediate interest, A/B independence and saved hand identity')

-- A million pairs, using exactly the production sampler (not a reimplementation).
math.randomseed(7132026)
local bands,kinds={},{}
local n,jackpot_pairs,both_harmful=1000000,0,0
local gain,bank=0,0
for i=1,n do
    local a,b=L.roll(math.random,5),L.roll(math.random,5)
    if a.band=='jackpot' or b.band=='jackpot' then jackpot_pairs=jackpot_pairs+1 end
    if a.band=='harmful' and b.band=='harmful' then both_harmful=both_harmful+1 end
    local best,best_money=0,0
    for _,v in ipairs({a,b}) do
        bands[v.band]=(bands[v.band] or 0)+1
        local k=kinds[v.kind] or {n=0,sum=0,min=math.huge,max=0};kinds[v.kind]=k
        k.n=k.n+1;k.sum=k.sum+v.value;k.min=math.min(k.min,v.value);k.max=math.max(k.max,v.value)
        local effect=L.effect(v)
        -- Deliberately optimistic: choose scoring and money separately, with a
        -- modest 100 chips / 20 Mult baseline. This is an upper bound, not winrate.
        local score=(100+(effect.chips or 0))*(20+(effect.mult or 0))*(effect.x_mult or 1)/2000
        best=math.max(best,score);best_money=math.max(best_money,effect.dollars or 0)
    end
    gain=gain+best;bank=bank+best_money
end
for _,band in ipairs({'harmful','normal','good','rare','jackpot'}) do
    print(string.format('%s: %.5f%% (%d / %d options)',band,100*(bands[band] or 0)/(n*2),bands[band] or 0,n*2))
end
for _,kind in ipairs({'chips','mult','xmult','dollars','interest','combo'}) do
    local k=kinds[kind]
    print(string.format('%s: mean %.3f, observed range %.2f..%.2f, count %d',kind,k.sum/k.n,k.min,k.max,k.n))
end
print(string.format('Hands with jackpot: %.5f%%; both harmful: %.5f%%',100*jackpot_pairs/n,100*both_harmful/n))
print(string.format('Optimistic independent choices: scoring X%.3f at 100x20; money $%.3f at vanilla interest cap',gain/n,bank/n))
assert(bands.jackpot>100 and bands.jackpot<350)
assert(bands.harmful>90000 and bands.harmful<110000)
assert(gain/n<1.8 and bank/n<2.0,'Revisit balance before shipping')
