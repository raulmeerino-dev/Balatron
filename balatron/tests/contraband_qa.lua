-- Isolated native LÖVE/Steamodded integration run; never bundled in the IPA.
local out=QA.out
local function log(s) local f=assert(io.open(out..'/result.txt','a'));f:write(s..'\n');f:close() end
love.errorhandler=function(err) log('FAIL '..tostring(err)..'\n'..debug.traceback());return function() return 1 end end
love.errhand=love.errorhandler
local steps={};local function step(name,fn,delay) steps[#steps+1]={name=name,fn=fn,delay=delay or 1.5} end
local B,C,card,choice,target,before,forecast,tag,snapshot
local function clear(area) for i=#area.cards,1,-1 do area.cards[i]:remove() end end
local function make(id,area)
 local key=G.P_CENTERS[id] and id or 'cb_evt_'..id
 local c=SMODS.create_card{key=key,set=G.P_CENTERS[key].set,area=area or G.consumeables,skip_materialize=true}
 if not area then c:add_to_deck();G.consumeables:emplace(c) else area:emplace(c) end
 return c
end
local function choose(c,n)
 G.FUNCS.use_card{config={ref_table=c}}
 local ch=C.prepare(c)[n or 1];assert(ch,'No choice')
 G.FUNCS.evt_cb_select{config={ref_table={card=c,choice=ch}}}
 G.FUNCS.evt_cb_confirm{config={ref_table={card=c,choice=ch}}}
 return ch
end
step('start',function()
 G.SETTINGS.tutorial_complete=true;G.SETTINGS.tutorial_progress=nil;G.SETTINGS.SOUND.volume=0;G.SETTINGS.GAMESPEED=4
 G:delete_run();G:start_run{seed='CBFINAL'}
end,3)
step('native_registration_and_shop',function()
 B=PortraitEvents.black_market;C=B.contraband
 assert(#C.order==10);assert(SMODS.ConsumableTypes.Contraband)
 for _,id in ipairs(C.order) do local c=G.P_CENTERS['cb_evt_'..id]
  assert(c and c.consumeable and c.set=='Contraband');assert(G.ASSET_ATLAS[c.atlas])
 end
 G.GAME.dollars=500;G.GAME.facing_blind=false;G.STATE=G.STATES.SHOP;G.STATE_COMPLETE=false
end,4)
step('buy_and_store',function()
 card=make('loaded_dice',G.shop_booster);before=G.GAME.dollars
 G.FUNCS.buy_from_shop{config={ref_table=card,id='buy'}}
end,3)
step('no_automatic_effect_and_full_slots',function()
 assert(card.area==G.consumeables and G.GAME.dollars<before);assert(not B.state().dice_ante)
 target=make('c_pluto');local extra=make('forgery',G.shop_booster)
 assert(not G.FUNCS.check_for_buy_space(extra));extra:remove()
 G.FUNCS.use_card{config={ref_table=card}}
end,4)
step('loaded_dice_one_native_probability',function()
 assert(B.state().dice_ante==G.GAME.round_resets.ante and #G.consumeables.cards==1)
 local n,d=SMODS.get_probability_vars(target,1,5,'lucky_mult');assert(math.abs(n/d-0.36)<0.00001)
 local a,b=SMODS.get_probability_vars(target,1,5,'unrelated');assert(a/b==0.2)
 local repeatcard=make('loaded_dice');assert(not C.can_use(repeatcard));repeatcard:remove()
 card=make('forgery');assert(C.can_use(card));C.open(card);choice=C.prepare(card)[1]
 G.FUNCS.evt_cb_cancel();assert(card.area==G.consumeables and not card.ability.cb_applied)
end)
step('forgery_native_use',function() choose(card) end,4)
step('forgery_slot_and_sell',function()
 assert(#G.consumeables.cards==2 and G.consumeables.cards[1].config.center.key=='c_pluto' and G.consumeables.cards[2].config.center.key=='c_pluto')
 clear(G.consumeables);card=make('forgery');target=make('loaded_dice');assert(not C.can_use(card));target:remove()
 before=G.GAME.dollars;G.FUNCS.sell_card{config={ref_table=card}}
end,3)
step('sell_and_no_targets',function()
 assert(G.GAME.dollars>before and #G.consumeables.cards==0)
 card=make('stolen_negative');assert(not C.can_use(card))
 target=make('j_joker',G.jokers);target:add_to_deck();target.ability.eternal=true
 target:set_edition({foil=true},true,true);assert(not C.can_use(card));target:set_edition(nil,true,true)
 choose(card)
end,4)
step('negative_preserves_stickers',function()
 assert(target.edition.negative and target.ability.eternal)
 card=make('marked_card');choice=choose(card)
end,4)
step('marked_enhancement_and_seal',function()
 local found;for _,c in ipairs(G.playing_cards) do if c.sort_id==choice.sort_id then found=c end end
 assert(found and found.config.center.key~='c_base' and found.seal)
 card=make('dealers_choice');C.open(card);forecast=copy_table(C.prepare(card));assert(#forecast==3)
 for _,ch in ipairs(forecast) do local center=G.P_CENTERS[ch.saved.save_fields.center];assert(center.rarity==3) end
 G.FUNCS.evt_cb_cancel();assert(C.prepare(card)[1].saved.save_fields.center==forecast[1].saved.save_fields.center)
 local saved=copy_table(card:save());card:remove();card=C.preview(saved);card.cb_preview=nil;card:add_to_deck();G.consumeables:emplace(card)
 assert(C.prepare(card)[1].saved.save_fields.center==forecast[1].saved.save_fields.center)
 choose(card)
end,4)
step('rare_choice_and_full_jokers',function()
 assert(#G.jokers.cards==2)
 card=make('hot_merchandise');local old=G.jokers.config.card_limit;rawset(G.jokers.config,'card_limit',#G.jokers.cards)
 assert(not C.can_use(card));rawset(G.jokers.config,'card_limit',nil)
 C.open(card);for _,ch in ipairs(C.prepare(card)) do assert(ch.saved.edition) end
 G.FUNCS.evt_cb_cancel();choose(card)
end,4)
step('voucher_choices',function()
 card=make('counterfeit_voucher');local list=C.prepare(card);assert(#list==3)
 for _,ch in ipairs(list) do assert(not G.GAME.used_vouchers[ch.key]) end
 choice=choose(card)
end,10)
step('voucher_redeemed_and_bribe',function()
 assert(G.GAME.used_vouchers[choice.key]);card=make('bribe');assert(C.can_use(card),'bribe state '..tostring(G.STATE));local old=C.boss()
 C.open(card);local list=C.prepare(card);assert(#list>0)
 for _,ch in ipairs(list) do assert(ch.key~=old) end
 G.FUNCS.evt_cb_cancel();choice=choose(card)
end,4)
step('boss_and_tag',function()
 assert(C.boss()==choice.key,'boss='..tostring(C.boss())..' wanted='..tostring(choice.key)..' applied='..tostring(card.ability.cb_applied)..' state='..tostring(G.STATE)..' pending='..tostring(card.ability.cb_pending))
 local c=make('bribe');local old=G.GAME.round_resets.blind_states.Boss
 G.GAME.round_resets.blind_states.Boss='Current';assert(not C.can_use(c));G.GAME.round_resets.blind_states.Boss=old;c:remove()
 card=make('stolen_tag');C.open(card);local list=C.prepare(card);assert(#list==3)
 for i,ch in ipairs(list) do if G.P_TAGS[ch.key].config.type~='immediate' then choice=i;break end end
 G.FUNCS.evt_cb_cancel();choose(card,choice)
end,4)
step('real_shop_preview',function()
 for i=#G.GAME.tags,1,-1 do G.GAME.tags[i]:remove() end
 tag=Tag('tag_foil');add_tag(tag)
 card=make('inside_information');local live=G.shop_jokers.cards[1]
 C.open(card);forecast=copy_table(B.state().next_stock);assert(#forecast.choices>=3)
 assert(G.shop_jokers.cards[1]==live and not tag.triggered)
 G.FUNCS.evt_cb_cancel();assert(B.state().next_stock.token==forecast.token)
 choice=choose(card);assert(B.state().reservation)
end,4)
step('next_shop_delivery',function()
 assert(B.state().reservation);for _,name in ipairs(B.areas) do clear(G[name]) end
 G:populate_shop_stock()
end,3)
step('reservation_delivered_once_and_buy_use_cancel',function()
 assert(not B.state().next_stock and not B.state().reservation)
 local actual=G[choice.area].cards[choice.index]
 assert(actual.config.center.key==choice.saved.save_fields.center)
 card=make('marked_card',G.shop_booster);G.FUNCS.buy_from_shop{config={id='buy_and_use',ref_table=card}}
end,4)
step('buy_use_cancel_keeps_inventory',function()
 assert(G.OVERLAY_MENU and card.area==G.consumeables,'buy/use overlay='..tostring(G.OVERLAY_MENU~=nil)..' owned='..tostring(card.area==G.consumeables)..' state='..tostring(G.STATE)..' locks='..tostring(G.CONTROLLER.locks.use))
 G.FUNCS.evt_cb_cancel();assert(card.area==G.consumeables)
 clear(G.consumeables);card=make('stolen_tag');C.open(card);forecast=copy_table(C.prepare(card))
 save_run();assert(G.culled_table.GAME.portrait_events.black_market.dice_ante)
 snapshot=copy_table(G.culled_table)
 G.FUNCS.evt_cb_cancel();G.GAME.portrait_events.config.events.black_market=false
 assert(C.can_use(card));G.GAME.portrait_events.config.events.black_market=true
 G.PROFILES[G.SETTINGS.profile].all_unlocked=true
 for _,id in ipairs(C.order) do assert(PortraitCollection.known('contraband',id)) end
 G.FUNCS.your_collection_jokers()
end,2)
step('resume_pending_choice',function()
 G.FUNCS.exit_overlay_menu();G:start_run{savetext=snapshot}
end,4)
step('pending_choice_restored',function()
 assert(G.OVERLAY_MENU and #G.consumeables.cards==1)
 card=G.consumeables.cards[1];assert(card.ability.cb_pending and C.prepare(card)[1].key==forecast[1].key)
 assert(B.state().dice_ante==G.GAME.round_resets.ante)
 G.FUNCS.evt_cb_cancel();assert(card.area==G.consumeables and not card.ability.cb_applied)
end)
step('complete',function() log('PASS all native Contraband integration scenarios');love.event.quit() end)
local update,draw=love.update,love.draw
local i,t,pending=0,0,nil
function love.update(dt)
 update(dt);t=t+dt
 if t<(i==0 and 3 or steps[i].delay) then return end
 if i>0 then log('PASS '..steps[i].name) end
 i=i+1;t=0;if steps[i] then steps[i].fn();pending=steps[i].name end
end
function love.draw()
 draw()
 if pending then local name=pending;pending=nil;love.graphics.captureScreenshot(function(img)
  local f=assert(io.open(out..'/'..name..'.png','wb'));f:write(img:encode('png'):getString());f:close()
 end) end
end
