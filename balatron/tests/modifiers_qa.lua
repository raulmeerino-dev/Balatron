-- Targeted integration checks in the native game, using an isolated profile.
local function log(s) local f=assert(io.open(QA.out..'/result.txt','a'));f:write(s..'\n');f:close() end
love.errorhandler=function(err) log('FAIL '..tostring(err)..'\n'..debug.traceback());return function() return 1 end end
love.errhand=love.errorhandler
local steps={};local function step(name,fn,delay) steps[#steps+1]={name=name,fn=fn,delay=delay or 1} end
local M,U,R,defs,snapshot,profile,selected,held,dimensions
local function close() if G.OVERLAY_MENU then G.FUNCS.exit_overlay_menu() end end
local function acquire(id)
 M.state().levels=M.state().levels or {};assert(not M.state().levels[id],id..' already acquired')
 M.state().levels[id]=1;if defs[id].apply then defs[id].apply() end
end
local function walk(node,fn) fn(node);for _,c in pairs(node.children or {}) do walk(c,fn) end
 if node.config and node.config.object and node.config.object.content then walk(node.config.object.content.UIRoot,fn) end
end
local function choices()
 local list={};walk(G.OVERLAY_MENU.UIRoot,function(n) if n.config and n.config.button=='dm_choose' then list[#list+1]=n end end)
 table.sort(list,function(a,b) return a.T.x<b.T.x end);assert(#list==3);return list
end
local function point(n) local u=G.TILESCALE*G.TILESIZE;return (n.T.x+n.T.w/2)*u,(n.T.y+n.T.h/2)*u end
step('new_profile',function()
 G.SETTINGS.tutorial_complete=true;G.SETTINGS.tutorial_progress=nil;G.SETTINGS.SOUND.volume=0
 G.SETTINGS.GAMESPEED=4
 local p=G.PROFILES[G.SETTINGS.profile];p.all_unlocked=nil;p.portrait_collection=nil;p.modifier_unlocks=nil
 G:delete_run();G:start_run{seed='MODFINAL'}
 M=PortraitGameplay.modules.deck_mutations;U=PortraitModifierUnlocks;R=PortraitRunRules;defs={}
 local locked=0;for _,d in ipairs(M.definitions) do assert(not defs[d.id]);defs[d.id]=d;if d.unlock_condition then locked=locked+1 end end
 assert(#M.definitions==79 and locked==40)
 assert(U.unlocked('discounts') and not U.unlocked('free_reroll'))
 assert(PortraitCollection.count('mutations').tally==0)
end,3)
step('locked_collection',function() PortraitCollection.open('mutations',11) end,2)
step('locked_hold',function()
 walk(G.OVERLAY_MENU.UIRoot,function(n)
  if n.config and n.config.pg_visual_tooltip and n.config.on_demand_tooltip then held=held or n end
 end)
 assert(held);local x,y=point(held);love.mousepressed(x,y,1,true)
end,0.6)
step('locked_tooltip',function()
 assert(held.config.h_popup);local x,y=point(held);love.mousereleased(x,y,1,true);held=nil
end)
step('requirements_and_unlock_receipts',function()
 local info=U.info('profitable_sale');assert(info.text[3]=='0 / 20')
 U.record('sales',12,'first');U.record('sales',12,'first');assert(U.info('profitable_sale').text[3]=='12 / 20')
 local old=copy_table(G.GAME.portrait_modifier_progress)
 U.record('sales',8,'last');assert(U.unlocked('profitable_sale'))
 G.GAME.portrait_modifier_progress=old;U.record('sales',8,'last');assert(U.profile().stats.sales==20)
 close();M.state().pending={'discounts','boosted_mult','boosted_chips'};M.offer()
end,2)
step('selection_layout_and_hold',function()
 local list=choices();assert(math.abs(list[1].T.y-list[3].T.y)<0.05)
 assert(list[1].T.x+list[1].T.w<list[2].T.x+0.05)
 held=list[2];local x,y=point(held);love.mousepressed(x,y,1,true)
end,0.6)
step('hold_does_not_choose',function()
 assert(M.state().pending and not M.state().levels.boosted_mult)
 assert(held.config.pg_run_holding and held.config.h_popup)
 local x,y=point(held);love.mousereleased(x,y,1,true)
 assert(M.state().pending and not M.state().levels.boosted_mult)
end)
step('tap_and_double_tap',function()
 local list=choices();local x,y=point(list[1]);love.mousepressed(x,y,1,true);love.mousereleased(x,y,1,true)
 assert(M.state().levels.discounts==1 and not M.state().pending)
 G.FUNCS.dm_choose(list[2]);assert(not M.state().levels.boosted_mult)
end,2)
step('stacked_rules',function()
 assert(not G.OVERLAY_MENU)
 for _,id in ipairs({'inflation','cheap_jokers','cheap_consumables','cheap_packs','easy_sale','profitable_sale','boosted_mult','boosted_chips','first_hand','high_stakes','extra_reward','strong_boss','weak_boss','double_interest','free_discard','frequent_packs','second_pick','large_packs','free_reroll','empowered_jokers','strong_editions','strong_enhancements','fortune'}) do acquire(id) end
 assert(G.GAME.modifiers.extra_boosters==1 and G.GAME.modifiers.booster_choice_mod==1 and G.GAME.modifiers.booster_size_mod==1)
 assert(G.GAME.current_round.free_rerolls>=1 and G.GAME.current_round.reroll_cost==0)
 local small=R.blind_values(G.P_BLINDS.bl_small);assert(small.mult==G.P_BLINDS.bl_small.mult*1.25)
 local boss=R.blind_values(G.P_BLINDS.bl_hook);assert(math.abs(boss.mult-G.P_BLINDS.bl_hook.mult*1.25*1.5*.8)<.001)
 local c=SMODS.create_card{key='j_joker',area=G.jokers,skip_materialize=true};c:add_to_deck();G.jokers:emplace(c)
 local effect=c:calculate_joker{joker_main=true,cardarea=G.jokers};assert(math.abs((effect.mult_mod or effect.mult)-4.4)<.001)
 local cost=c.cost;c:set_cost();assert(c.cost==cost)
 local enhanced=G.playing_cards[1];enhanced:set_ability(G.P_CENTERS.m_bonus);assert(enhanced:get_chip_bonus()==enhanced.base.nominal+33)
 enhanced:set_ability(G.P_CENTERS.m_mult);assert(math.abs(enhanced:get_chip_mult()-4.4)<.001)
 c:set_edition({foil=true},true,true);assert(math.abs(c:calculate_edition{pre_joker=true}.chips-55)<.001)
 G.GAME.dollars=10;assert(R.interest()==4);G.GAME.dollars=500;assert(R.interest()==G.GAME.interest_amount*G.GAME.interest_cap/5)
 local a,b=SMODS.get_probability_vars(c,1,4,'space');assert(math.abs(a/b-.3)<.001)
 local a,b=SMODS.get_probability_vars(c,1,4,'gros_michel');assert(a/b==.25)
 dimensions={hand=G.hand.config.card_limit,jokers=G.jokers.config.card_limit,boosters=G.GAME.modifiers.extra_boosters}
 save_run();snapshot=copy_table(G.culled_table);profile=copy_table(U.profile())
end,2)
step('save_load',function() G:delete_run();G:start_run{savetext=snapshot} end,4)
step('no_reapply_after_load',function()
 assert(G.hand.config.card_limit==dimensions.hand and G.jokers.config.card_limit==dimensions.jokers)
 assert(G.GAME.modifiers.extra_boosters==dimensions.boosters and G.GAME.modifiers.booster_choice_mod==1)
 assert(U.profile().stats.sales==20 and U.unlocked('profitable_sale'))
 G.FUNCS.select_blind{config={ref_table=G.P_BLINDS.bl_small},UIBox=G.blind_select}
end,4)
step('first_discard',function()
 assert(G.STATE==G.STATES.SELECTING_HAND)
 selected=G.GAME.current_round.discards_left
 G.hand:add_to_highlighted(G.hand.cards[1]);G.FUNCS.discard_cards_from_highlighted(nil)
end,3)
step('second_discard',function()
 assert(G.GAME.current_round.discards_left==selected and G.GAME.current_round.discards_used==1)
 G.hand:add_to_highlighted(G.hand.cards[1]);G.FUNCS.discard_cards_from_highlighted(nil)
end,3)
step('real_hand',function()
 assert(G.GAME.current_round.discards_left==selected-1)
 G.hand:add_to_highlighted(G.hand.cards[1]);G.FUNCS.play_cards_from_highlighted()
end,7)
step('score_and_profile_disk',function()
 assert(G.GAME.current_round.hands_played==1 and G.GAME.chips>0)
 local disk=STR_UNPACK(assert(get_compressed(G.SETTINGS.profile..'/profile.jkr')))
 assert(disk.modifier_unlocks.unlocked.profitable_sale and disk.modifier_unlocks.stats.sales==20)
 G.PROFILES[G.SETTINGS.profile].modifier_unlocks=disk.modifier_unlocks
 assert(U.unlocked('profitable_sale'))
 close();G.FUNCS.profile_select()
 G.FUNCS.unlock_all{config={}}
 if not G.PROFILES[G.SETTINGS.profile].all_unlocked then G.FUNCS.unlock_all{config={}} end
 assert(PortraitCollection.count('mutations').tally==79)
 for _,d in ipairs(M.definitions) do assert(U.unlocked(d.id)) end
 PortraitCollection.open('mutations',12)
end,2)
step('legacy_profile_and_mods_off',function()
 close();local p=G.PROFILES[G.SETTINGS.profile];local saved=copy_table(p)
 p.all_unlocked=nil;p.modifier_unlocks=nil;p.portrait_collection={mutations={heavy_hearts=1}}
 U.profile();assert(U.discovered('heavy_hearts') and not U.unlocked('rare_market') and not U.unlocked('free_reroll'))
 G.PROFILES[G.SETTINGS.profile]=saved
 local on=M.mod.config.enabled;M.mod.config.enabled=false
 G:delete_run();G:start_run{seed='MODOFF'};assert(not M.enabled())
 assert(PortraitCollection.count('mutations').of==79 and U.unlocked('rare_market'))
 M.mod.config.enabled=on
end,3)
step('locked_pool_and_stable_offer',function()
 G:start_run{seed='POOLFINAL'}
 local p=G.PROFILES[G.SETTINGS.profile];p.all_unlocked=nil;p.modifier_unlocks.unlocked.free_reroll=nil
 local old=PortraitGameplay.choose;local checked=false
 PortraitGameplay.choose=function(entries,weight,key)
  checked=true;for _,id in ipairs(entries) do assert(U.unlocked(id),'Locked entry in pool: '..id) end
  return old(entries,weight,key)
 end
 G.GAME.facing_blind=true;G.GAME.blind:set_blind(G.P_BLINDS.bl_hook)
 G.GAME.chips=G.GAME.blind.chips;M.mod:calculate{end_of_round=true,main_eval=true,beat_boss=true}
 PortraitGameplay.choose=old;assert(checked and #M.state().pending==3)
 local offered=table.concat(M.state().pending,',');U.unlock('free_reroll',true)
 assert(table.concat(M.state().pending,',')==offered)
 M.state().pending=nil;PortraitGameplay.offer_queued=false;G.GAME.facing_blind=false
 for _,id in ipairs({'large_packs','second_pick','frequent_packs'}) do acquire(id) end
 G.GAME.dollars=500;G.STATE=G.STATES.SHOP;G.STATE_COMPLETE=false
end,4)
step('native_arcana_pack',function()
 local pack=SMODS.create_card{key='p_arcana_normal_1',area=G.shop_booster,skip_materialize=true};G.shop_booster:emplace(pack)
 G.FUNCS.use_card{config={ref_table=pack}}
end,5)
step('pack_size_and_choices',function()
 assert(#G.pack_cards.cards==4 and G.GAME.pack_choices==2)
end,2)
step('complete',function() log('PASS native modifier interactions, rules, profile persistence and real hand');love.event.quit() end)
local update,draw=love.update,love.draw;local i,t,pending=0,0
function love.update(dt)
 update(dt);t=t+dt
 if t<(i==0 and 3 or steps[i].delay) then return end
 if i>0 then log('PASS '..steps[i].name) end
 i=i+1;t=0;if steps[i] then steps[i].fn();pending=steps[i].name end
end
function love.draw()
 draw();if pending then local name=pending;pending=nil;love.graphics.captureScreenshot(function(img)
 local f=assert(io.open(QA.out..'/'..name..'.png','wb'));f:write(img:encode('png'):getString());f:close() end) end
end
