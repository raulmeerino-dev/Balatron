local function log(s) local f=assert(io.open(QA.out..'/result.txt','a'));f:write(s..'\n');f:close() end
love.errorhandler=function(err) log('FAIL '..tostring(err)..'\n'..debug.traceback());return function() return 1 end end
love.errhand=love.errorhandler
local steps={};local function step(name,fn,delay) steps[#steps+1]={name=name,fn=fn,delay=delay or 3} end
local dimensions,C
local function pack()
 local c=SMODS.create_card{key='p_arcana_normal_1',area=G.shop_booster,skip_materialize=true};G.shop_booster:emplace(c)
 G.FUNCS.use_card{config={ref_table=c}}
end
step('shop',function()
 G.SETTINGS.tutorial_complete=true;G.SETTINGS.tutorial_progress=nil;G.SETTINGS.SOUND.volume=0;G.SETTINGS.GAMESPEED=4
 G:delete_run();G:start_run{seed='POLISH'};G.GAME.dollars=500
 G.STATE=G.STATES.SHOP;G.STATE_COMPLETE=false;C=PortraitGameplay.modules.contracts
end,4)
step('pack_without_contract',pack,4)
step('pack_selected_action',function()
 dimensions={w=G.pack_cards.cards[1].T.w,h=G.pack_cards.cards[1].T.h,scale=G.pack_cards.config.portrait_pack_scale}
 assert(dimensions.scale>1.1);G.pack_cards:add_to_highlighted(G.pack_cards.cards[1])
end)
step('skip_and_accept_contract',function()
 G.FUNCS.skip_booster();C.state().offer='clean_hands';C.accept();C.refresh_hud()
end,4)
step('pack_with_contract',pack,4)
step('same_scale_with_contract',function()
 assert(math.abs(G.pack_cards.cards[1].T.w-dimensions.w)<.01 and math.abs(G.pack_cards.cards[1].T.h-dimensions.h)<.01)
 assert(G.HUD:get_UIE_by_ID('portrait_contracts'))
end)
step('last_contract_removed',function()
 C.state().actives={};C.refresh_hud();assert(not G.HUD:get_UIE_by_ID('portrait_contracts'))
 G.FUNCS.skip_booster()
end,4)
step('blind_selection_title',function() G.FUNCS.toggle_shop() end)
step('select_blind',function() G.FUNCS.select_blind{config={ref_table=G.P_BLINDS.bl_small},UIBox=G.blind_select} end,4)
step('vanilla_flames_large_panels',function()
 update_hand_text({immediate=true,delay=0},{chips=500,mult=80,chip_total=40000})
end,3)
step('flames_and_record',function()
 assert(G.ARGS[G.ARGS.flame_handler.chips.arg_tab].real_intensity>0 and G.ARGS[G.ARGS.flame_handler.mult.arg_tab].real_intensity>0)
 require('portrait_reward_fx').record(40000)
end,1)
step('consumable_above_jokers',function()
 for _,key in ipairs({'j_joker','j_blueprint','j_brainstorm'}) do
  local c=SMODS.create_card{key=key,area=G.jokers,skip_materialize=true};c:add_to_deck();G.jokers:emplace(c)
 end
 local c=SMODS.create_card{key='c_hermit',area=G.consumeables,skip_materialize=true};c:add_to_deck();G.consumeables:emplace(c)
 G.consumeables:add_to_highlighted(c)
end)
step('done',function() log('PASS pack scale with/without contracts, dynamic HUD, native flames and layering review');love.event.quit() end)
local update,draw=love.update,love.draw;local i,t,pending=0,0
function love.update(dt)
 update(dt);t=t+dt;if t<(i==0 and 3 or steps[i].delay) then return end
 if i>0 then log('PASS '..steps[i].name) end;i=i+1;t=0
 if steps[i] then steps[i].fn();pending=steps[i].name end
end
function love.draw()
 draw();if pending and t>.6 then local name=pending;pending=nil;love.graphics.captureScreenshot(function(img)
 local f=assert(io.open(QA.out..'/'..name..'.png','wb'));f:write(img:encode('png'):getString());f:close() end) end
end
