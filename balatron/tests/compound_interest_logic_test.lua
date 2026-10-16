local L=dofile('../MODS/Compound Interest/logic.lua')
local checks=0
local function eq(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)); checks=checks+1 end
local function fresh() return {initial_xmult=1,growth_per_round=.15,won_rounds=0,last_won_round=''} end
local ctx={end_of_round=true,main_eval=true}
local state={owned=true,played=true,won=true,round='1'}
local e=fresh()
eq(L.factor(e),1)
for i=1,20 do
    state.round=tostring(i)
    eq(L.advance(e,ctx,state),true)
    eq(L.advance(e,ctx,state),false)
    eq(L.factor(e),math.floor((1+.15*i)*100+.5)/100)
end
eq(L.factor(e),4)
for _,flag in ipairs({'blueprint','repetition','individual','game_over'}) do
    local context={end_of_round=true,main_eval=true}; context[flag]=true
    eq(L.advance(fresh(),context,state),false)
end
eq(L.advance(fresh(),{end_of_round=true},state),false)
eq(L.advance(fresh(),{joker_main=true},state),false)
for _,flag in ipairs({'owned','played','won'}) do
    state[flag]=false; eq(L.advance(fresh(),ctx,state),false); state[flag]=true
end
state.debuff=true; eq(L.advance(fresh(),ctx,state),false); state.debuff=nil
e=fresh(); e.won_rounds=2
eq(20*L.factor(e),26)
eq(L.format(L.factor(e),false),'1.30')
eq(L.format(L.factor(e),true),'1,30')
for _,v in ipairs({{0,true},{.009999,true},{.01,false},{.010001,false},{1,false}}) do eq(L.roll(v[1],.01),v[2]) end
local eligible={normal_joker=true,unlocked=true}
eq(not not L.eligible(eligible),true)
eligible.used=true; eq(not not L.eligible(eligible),false)
eligible.showman=true; eq(not not L.eligible(eligible),true)
eligible.banned=true; eq(not not L.eligible(eligible),false)
eligible.banned=nil; eligible.normal_joker=false; eq(not not L.eligible(eligible),false)
print('PASS: '..checks..' Compound Interest rule checks')
