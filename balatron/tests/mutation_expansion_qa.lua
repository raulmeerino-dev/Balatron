-- Requested focused native checks. Runs only in a separately packaged desktop harness.
local function log(s) local f=assert(io.open(QA.out..'/result.txt','a'));f:write(s..'\n');f:close() end
love.errorhandler=function(err) log('FAIL '..tostring(err)..'\n'..debug.traceback());return function() return 1 end end
love.errhand=love.errorhandler
local steps={};local function step(name,fn,delay) steps[#steps+1]={name=name,fn=fn,delay=delay or 1.5} end
local M,U,R,D,snapshot,saved_profile,held,before,after,card,seal_target,oldmod
local function close() if G.OVERLAY_MENU then G.FUNCS.exit_overlay_menu() end end
local function walk(node,fn)
 fn(node);for _,c in pairs(node.children or {}) do walk(c,fn) end
 if node.config and node.config.object and node.config.object.content then walk(node.config.object.content.UIRoot,fn) end
end
local function point(n) local u=G.TILESCALE*G.TILESIZE;return (n.T.x+n.T.w/2)*u,(n.T.y+n.T.h/2)*u end
local function acquire(id) M.state().levels[id]=1;if D[id].apply then D[id].apply() end end
local function fresh(seed)
 close();G:delete_run();G:start_run{seed=seed}
end
step('new_profile_79_entries_39_initial',function()
 G.SETTINGS.tutorial_complete=true;G.SETTINGS.tutorial_progress=nil;G.SETTINGS.SOUND.volume=0;G.SETTINGS.GAMESPEED=4
 M=PortraitGameplay.modules.deck_mutations;U=PortraitModifierUnlocks;R=PortraitRunRules;D={}
 local p=G.PROFILES[G.SETTINGS.profile];p.all_unlocked=nil;p.portrait_collection=nil;p.modifier_unlocks=nil
 fresh('MUTATIONS11');local locked,available=0,0
 for _,d in ipairs(M.definitions) do D[d.id]=d;if d.unlock_required then locked=locked+1 end;if U.unlocked(d.id) then available=available+1 end end
 assert(#M.definitions==79 and locked==40 and available==39)
 assert(PortraitCollection.count('mutations').tally==0)
 local old=M.icon;M.icon=function() error('Unknown Collection leaked a real sprite') end
 PortraitCollection.open('mutations',12);M.icon=old
 local titles={};walk(G.OVERLAY_MENU.UIRoot,function(n) if n.config and n.config.text then titles[n.config.text]=true end end)
 assert(titles['???'] and not titles[localize('k_dm_seal_relay')])
end,3)
step('discovered_locked_progress',function()
 close();U.record('seal_discards',1,'first');assert(U.discovered('seal_relay') and not U.unlocked('seal_relay'))
 assert(U.info('seal_relay').text[3]=='1 / 5');assert(PortraitCollection.count('mutations').tally==1)
 PortraitCollection.open('mutations',12)
end,2)
step('locked_long_press',function()
 local tiles={};walk(G.OVERLAY_MENU.UIRoot,function(n) if n.config and n.config.button=='pg_gallery_inspect' then tiles[#tiles+1]=n end end)
 table.sort(tiles,function(a,b) if math.abs(a.T.y-b.T.y)>.1 then return a.T.y<b.T.y end;return a.T.x<b.T.x end)
 held=tiles[5];assert(held);local x,y=point(held);love.mousepressed(x,y,1,true)
end,.7)
step('locked_long_press_tooltip',function()
 assert(held.config.h_popup,'Long press did not produce a tooltip')
 local x,y=point(held);love.mousereleased(x,y,1,true);close()
 U.record('seal_discards',4,'rest');assert(U.unlocked('seal_relay') and #U.profile().pending_notifications==1)
 U.record('seal_discards',4,'rest');assert(U.profile().stats.seal_discards==5 and #U.profile().pending_notifications==1)
 PortraitCollection.open('mutations',12)
end,2)
step('offers_immutable_and_locked_choice_rejected',function()
 close();M.state().pending={'discounts','boosted_mult','boosted_chips'};local offer=table.concat(M.state().pending,',')
 U.record('fusions',3,'first');assert(U.unlocked('frequent_fusion') and U.unlocked('fusion_workshop'))
 assert(table.concat(M.state().pending,',')==offer)
 M.state().pending={'orbital_echo','discounts'}
 G.FUNCS.dm_choose{config={ref_table='orbital_echo'}};assert(not M.state().levels.orbital_echo)
 M.offer();assert(#M.state().pending==1 and M.state().pending[1]=='discounts');close();M.state().pending=nil
 -- Restoring active/pending entries must not permanently unlock them.
 M.state().levels.orbital_echo=1;M.state().pending={'contraband_credit','discounts'}
 save_run();snapshot=copy_table(G.culled_table);saved_profile=copy_table(U.profile())
end,2)
step('load_cannot_unlock_entries',function() fresh('PLACEHOLDER');G:delete_run();G:start_run{savetext=snapshot} end,4)
step('restored_profile_and_pool',function()
 assert(not U.unlocked('orbital_echo') and not U.unlocked('contraband_credit'))
 assert(U.discovered('orbital_echo') and not U.discovered('contraband_credit'))
 assert(U.unlocked('fusion_workshop') and #U.profile().pending_notifications==3)
 M.state().pending=nil;M.state().levels.orbital_echo=nil
 local choose=PortraitGameplay.choose;local checked=false
 PortraitGameplay.choose=function(entries,weight,key)
  checked=true;for _,id in ipairs(entries) do assert(U.unlocked(id),'Locked pool entry '..id) end;return choose(entries,weight,key)
 end
 G.GAME.facing_blind=true;G.GAME.blind:set_blind(G.P_BLINDS.bl_hook);G.GAME.chips=G.GAME.blind.chips
 M.mod:calculate{end_of_round=true,main_eval=true,beat_boss=true}
 PortraitGameplay.choose=choose;assert(checked and #M.state().pending==3)
 M.state().pending=nil;G.GAME.facing_blind=false;PortraitGameplay.offer_queued=false
end,2)
step('old_profile_migration',function()
 local p=G.PROFILES[G.SETTINGS.profile];local old=copy_table(p)
 p.portrait_collection={mutations={heavy_hearts=2,enhanced_genetics=1}}
 p.modifier_unlocks={version=1,unlocked={strong_seals=true,enhanced_genetics=true,rare_market=true},stats={packs=9},runs={['old']={packs=9}},serial=4}
 U.profile();U.check()
 assert(U.discovered('heavy_hearts') and U.unlocked('enhanced_genetics') and U.unlocked('rare_market'))
 assert(not U.discovered('strong_seals') and not U.unlocked('strong_seals'))
 assert(U.profile().stats.packs==9 and U.unlocked('frequent_packs'))
 G.PROFILES[G.SETTINGS.profile]=old
end)
step('consumable_tradeoff_native_event',function()
 before={slots=G.consumeables.config.card_limit,jokers=G.jokers.config.card_limit};acquire('consumable_exchange')
end,2)
step('consumable_tradeoff_and_orbital_native_level',function()
 assert(G.consumeables.config.card_limit==before.slots+2 and G.jokers.config.card_limit==before.jokers-1)
 acquire('orbital_echo');local hand
 for _,key in ipairs(G.handlist) do local h=G.GAME.hands[key];if h.visible and (not hand or h.level<G.GAME.hands[hand].level) then hand=key end end
 local level=G.GAME.hands[hand].level
 card=SMODS.create_card{key='c_pluto',area=G.consumeables,skip_materialize=true}
 R.calculate{using_consumeable=true,consumeable=card};assert(G.GAME.hands[hand].level==level+1);card:remove()
end)
step('seal_relay_one_copy_first_discard_only',function()
 acquire('seal_relay');local a,b,c=G.playing_cards[1],G.playing_cards[2],G.playing_cards[3]
 a:set_seal('Red',true,true);b:set_seal(nil,true,true);c:set_seal(nil,true,true)
 a.T.x=0;b.T.x=1;c.T.x=2;M.state().seal_relay_used=false
 R.calculate{pre_discard=true,full_hand={c,b,a}};assert(b.seal=='Red' and not c.seal)
 R.calculate{pre_discard=true,full_hand={a,c}};assert(not c.seal)
end)
step('boss_reserves_and_nonboss_tradeoff',function()
 acquire('field_reserves');acquire('discard_reserve');M.state().reserved_discards=2;M.state().expansion_blind=nil
 before={hands=G.GAME.current_round.hands_left,discards=G.GAME.current_round.discards_left}
 R.calculate{setting_blind=true,blind=G.P_BLINDS.bl_hook}
 assert(R.blind_values(G.P_BLINDS.bl_small).dollars==G.P_BLINDS.bl_small.dollars-1)
end,2)
step('reserves_applied_once',function()
 assert(G.GAME.current_round.hands_left==before.hands+1 and G.GAME.current_round.discards_left==before.discards+3)
 R.calculate{setting_blind=true,blind=G.P_BLINDS.bl_hook}
 assert(M.state().reserved_discards==0)
 local C=PortraitGameplay.modules.contracts;C.state().offer='clean_hands';C.accept();local old=C.active()[1];before={old_target=old.target}
 acquire('contract_shortcut');C.state().offer='execution';local terms=C.offer_terms('execution');assert(terms.target==1)
 C.accept();assert(C.active()[1].target==before.old_target and C.active()[2].target==1)
 before.money=G.GAME.dollars;before.reward=math.floor(C.config().execution_reward*.75+.5)
 C.reward('cash_execution',C.active()[2].mutation_cash_factor)
end,2)
step('contract_cash_and_shop',function()
 assert(G.GAME.dollars==before.money+before.reward)
 G.GAME.facing_blind=false;G.GAME.dollars=100;G.STATE=G.STATES.SHOP;G.STATE_COMPLETE=false
 acquire('fusion_workshop');acquire('contraband_credit');acquire('pack_refund')
end,4)
step('actual_fusion_and_native_purchase_credit',function()
 local F=PortraitFusion;local d=F.entries[F.order[1]]
 local function joker(key) local c=SMODS.create_card{key=key,area=G.jokers,skip_materialize=true};c:add_to_deck();G.jokers:emplace(c);return c end
 local a,b=joker(d.components[1]),joker(d.components[2]);before.slots=G.consumeables.config.card_limit
 assert(F.fuse{id=d.id,a=a,b=b})
 assert(U.profile().stats.fusions==4)
 R.contraband_used();assert(M.state().purchase_credit)
 card=SMODS.create_card{key='j_joker',area=G.shop_jokers,skip_materialize=true};G.shop_jokers:emplace(card);create_shop_card_ui(card)
 before.money=G.GAME.dollars;G.FUNCS.buy_from_shop{config={ref_table=card,id='buy'}}
end,4)
step('refund_then_native_pack_open',function()
 assert(G.consumeables.config.card_limit==before.slots+1)
 assert(G.GAME.dollars==before.money and not M.state().purchase_credit)
 local pack=SMODS.create_card{key='p_arcana_normal_1',area=G.shop_booster,skip_materialize=true};G.shop_booster:emplace(pack)
 G.FUNCS.use_card{config={ref_table=pack}}
end,5)
step('native_pack_skip_refund',function()
 assert(G.pack_cards and #G.pack_cards.cards==3)
 before.money=G.GAME.dollars;before.choices=G.GAME.pack_choices
 G.FUNCS.skip_booster{}
end,4)
step('pack_paid_once_and_native_pruning',function()
 assert(G.GAME.dollars==before.money+2*before.choices)
 R.calculate{skipping_booster=true};assert(G.GAME.dollars==before.money+2*before.choices)
 acquire('deck_pruning');before.cards=#G.playing_cards
 G.GAME.blind:set_blind(G.P_BLINDS.bl_hook)
 G.GAME.facing_blind=true;G.GAME.chips=G.GAME.blind.chips;M.state().expansion_win=nil
 assert(PortraitGameplay.won{end_of_round=true,main_eval=true,beat_boss=true},'Fixture must represent a won Boss')
 R.calculate{end_of_round=true,main_eval=true,beat_boss=true};G.GAME.facing_blind=false
end,4)
step('contract_result_keeps_pending_pruning_saveable',function()
 assert(G.OVERLAY_MENU and G.OVERLAY_MENU.ct_result_uid)
 assert(U.profile().stats.destroyed==1)
 local pending=false;for _,c in ipairs(G.playing_cards) do if c.ability.dm_pruning_pending then pending=true end end
 assert(pending);save_run();snapshot=copy_table(G.culled_table)
 G.FUNCS.ct_result_close();G:delete_run();G:start_run{savetext=snapshot}
end,4)
step('resume_pending_pruning_without_double_rewards',function()
 if G.OVERLAY_MENU and G.OVERLAY_MENU.ct_result_uid then G.FUNCS.ct_result_close() end
end,3)
step('pruning_native_destruction_and_save',function()
 assert(#G.playing_cards==before.cards-1,'Pruning count '..#G.playing_cards..' before '..before.cards)
 assert(U.profile().stats.destroyed==1,'Destroyed progress '..tostring(U.profile().stats.destroyed))
 local filter=G.ASSET_ATLAS.dm_seal_relay.image:getFilter();assert(filter=='nearest')
 before.slots=G.consumeables.config.card_limit;save_run();snapshot=copy_table(G.culled_table)
end,2)
step('effects_save_load',function() G:delete_run();G:start_run{savetext=snapshot} end,4)
step('saved_effects_not_applied_twice',function()
 assert(G.consumeables.config.card_limit==before.slots)
 assert(M.state().levels.consumable_exchange==1 and M.state().levels.fusion_workshop==1)
 oldmod=M.mod.config.enabled;M.mod.config.enabled=false;fresh('MUTATIONSOFF')
end,3)
step('mods_off_profile_preserved',function()
 assert(not M.enabled() and not M.state().levels.fusion_workshop and U.unlocked('fusion_workshop'))
 assert(PortraitCollection.count('mutations').of==79)
 M.mod.config.enabled=oldmod;fresh('MUTATIONSON')
end,3)
step('unlock_all_native_no_flood',function()
 assert(M.enabled());close();G.FUNCS.profile_select();G.FUNCS.unlock_all{config={}}
 if not G.PROFILES[G.SETTINGS.profile].all_unlocked then G.FUNCS.unlock_all{config={}} end
 assert(PortraitCollection.count('mutations').tally==79 and #U.profile().pending_notifications==0)
 for _,d in ipairs(M.definitions) do assert(U.unlocked(d.id) and U.discovered(d.id)) end
 close();G.SETTINGS.language='es_ES';G:set_language();M.mod.process_loc_text();init_localization()
 PortraitCollection.open('mutations',12)
end,3)
step('all_new_sprites_spanish',function() close();PortraitCollection.open('mutations',13) end,3)
step('complete',function() log('PASS expansion, three Collection states, native effects and persistence');love.event.quit() end)
local update,draw=love.update,love.draw;local i,t,pending=0,0
function love.update(dt)
 update(dt);t=t+dt;if t<(i==0 and 4 or steps[i].delay) then return end
 if i>0 then log('PASS '..steps[i].name) end
 i=i+1;t=0;if steps[i] then steps[i].fn();pending=steps[i].name end
end
function love.draw()
 draw();if pending and t>.35 then local name=pending;pending=nil;love.graphics.captureScreenshot(function(img)
 local f=assert(io.open(QA.out..'/'..name..'.png','wb'));f:write(img:encode('png'):getString());f:close() end) end
end
