-- Focused native integration checks requested for contextual Fusion and WAKE UP, NEO.
local function log(s) local f=assert(io.open(QA.out..'/result.txt','a'));f:write(s..'\n');f:close() end
love.errorhandler=function(err) log('FAIL '..tostring(err)..'\n'..debug.traceback());return function() return 1 end end
love.errhand=love.errorhandler
local steps={};local function step(name,fn,delay) steps[#steps+1]={name=name,fn=fn,delay=delay or 1.2} end
local F,P,a,b,snapshot,money,option,old_id
local function clear(area) for i=#area.cards,1,-1 do area.cards[i]:remove() end;area:handle_card_limit() end
local function make(key,area,owned,edition)
 local c=SMODS.create_card{key=key,area=area,no_edition=true,skip_materialize=true}
 if edition then c:set_edition(edition,true,true) end
 if owned then c:add_to_deck() end;area:emplace(c);area:handle_card_limit();return c
end
local function setup(n,limit,edition)
 clear(G.jokers);clear(G.shop_jokers);G.jokers.config.card_limit=limit or 5
 a=make('j_blueprint',G.jokers,true,edition)
 for i=2,n do make('j_greedy_joker',G.jokers,true) end
 b=make('j_joker',G.shop_jokers,false);b.cost=7
 G.GAME.dollars=100;G.jokers:handle_card_limit()
 return F.context_options(b)
end
step('start',function()
 G.SETTINGS.tutorial_complete=true;G.SETTINGS.tutorial_progress=nil;G.SETTINGS.SOUND.volume=0;G.SETTINGS.GAMESPEED=4
 G:delete_run();G:start_run{seed='FUSION11'}
end,3)
step('shop',function()
 F=PortraitFusion;P=PortraitGameplay;F.config().enabled=true
 for _,id in ipairs(F.order) do F.config().recipes[id]=true end
 G.GAME.dollars=100;G.GAME.facing_blind=false;G.STATE=G.STATES.SHOP;G.STATE_COMPLETE=false
end,4)
step('full_slots_context',function()
 assert(#setup(5,5)==1);G.shop_jokers:add_to_highlighted(b)
end)
step('single_payment_atomic_save',function()
 assert(b.children.fuse_button);local selected=F.context_options(b)[1]
 assert(F.fuse(selected));assert(not F.fuse(selected));assert(G.GAME.dollars==93)
 assert(a.removed and b.removed and #G.jokers.cards==5)
 assert(G.jokers.cards[5].config.center.key=='j_fuse_broken_copier')
 snapshot=copy_table(G.ARGS.save_run);assert(snapshot.GAME.dollars==93)
 assert(#snapshot.cardAreas.jokers.cards==5 and #snapshot.cardAreas.shop_jokers.cards==0)
end)
step('reload_shop',function() G:delete_run();G:start_run{savetext=snapshot} end,4)
step('no_repurchase',function()
 assert(G.GAME.dollars==93 and #G.jokers.cards==5 and #G.shop_jokers.cards==0)
 local choices=setup(4,5);assert(#choices==1 and F.fuse(choices[1]));assert(#G.jokers.cards==4)
 choices=setup(6,6);assert(#choices==1 and F.fuse(choices[1]));assert(#G.jokers.cards==6)
end)
step('restrictions_and_stale_actions',function()
 local choices=setup(5,5);G.GAME.dollars=6
 assert(#choices==1 and not F.source_afford(choices[1].source));assert(not F.fuse(choices[1]))
 assert(not a.removed and not b.removed and G.GAME.dollars==6)
 G.GAME.dollars=100;a:remove();assert(not F.fuse(choices[1]) and G.GAME.dollars==100)
 setup(5,5);F.config().enabled=false;assert(#F.context_options(b)==0);F.config().enabled=true
 F.config().recipes.broken_copier=false;assert(#F.context_options(b)==0);F.config().recipes.broken_copier=true
 G.GAME.banned_keys.j_fuse_broken_copier=true;assert(#F.context_options(b)==0);G.GAME.banned_keys.j_fuse_broken_copier=nil
 local stale=F.context_options(b)[1];b:remove();assert(not F.fuse(stale))
end)
step('negative_and_stickers',function()
 setup(6,5,{negative=true});a:set_eternal(true);b:set_rental(true);b:set_perishable(true)
 local choices=F.context_options(b);assert(#choices==1 and F.fuse(choices[1]))
 local c=G.jokers.cards[#G.jokers.cards]
 assert(c.edition.negative and c.ability.eternal and c.ability.rental and not c.ability.perishable)
 assert(#G.jokers.cards==6 and G.jokers.config.card_limit==6)
 -- Losing the owned negative to the external first component's foil must reject over-capacity.
 setup(5,5);a:set_edition({foil=true},true,true);a:remove()
 clear(G.shop_jokers);a=make('j_joker',G.jokers,true,{negative=true})
 make('j_greedy_joker',G.jokers,true);b=make('j_blueprint',G.shop_jokers,false,{foil=true})
 assert(#F.context_options(b)==0)
end)
step('multiple_choices',function()
 setup(4,5);make('j_blueprint',G.jokers,true,{holo=true});assert(#F.context_options(b)==2)
 G.FUNCS.fuse_context{config={ref_table=b}};assert(G.OVERLAY_MENU)
 G.FUNCS.exit_overlay_menu();assert(not a.removed and not b.removed)
end)
step('open_pack',function()
 setup(5,5);b:remove()
 local c=make('p_buffoon_mega_1',G.shop_booster,false)
 G.FUNCS.use_card{config={ref_table=c}}
end,4)
step('pack_choice',function()
 assert(G.pack_cards and G.GAME.pack_choices==2)
 clear(G.pack_cards);b=make('j_joker',G.pack_cards,false);make('j_jolly',G.pack_cards,false)
 money=G.GAME.dollars;assert(F.fuse(F.context_options(b)[1]))
 assert(G.GAME.pack_choices==1 and #G.jokers.cards==5 and G.GAME.dollars==money)
 snapshot=copy_table(G.ARGS.save_run);assert(not snapshot.ACTION and snapshot.GAME.fuse_pack)
end)
step('reload_pack',function() G:delete_run();G:start_run{savetext=snapshot} end,4)
step('remaining_pack_intact',function()
 assert(G.pack_cards and #G.pack_cards.cards==1 and G.GAME.pack_choices==1)
 assert(G.pack_cards.cards[1].config.center.key=='j_jolly' and G.GAME.dollars==money)
 assert(#G.jokers.cards==5);G.FUNCS.skip_booster()
end,4)
step('roulette_result',function()
 setup(5,5);b:remove();local R=P.roulette
 local c=SMODS.create_card{key='j_joker',no_edition=true,skip_materialize=true}
 local prizes={};for i=1,8 do prizes[i]=c:save() end;c:remove()
 G.GAME.pg_roulette={phase='result',winner=1,prizes=prizes,rerolls=0};R.open()
 assert(#F.context_options(R.cards[2])==0)
 b=R.feature;assert(#F.context_options(b)==1);b:highlight(true)
end)
step('roulette_claim_once',function()
 assert(F.fuse(F.context_options(b)[1]));assert(P.roulette.state().phase=='claimed')
 assert(P.roulette.state().accepted and P.roulette.state().fused and #G.jokers.cards==5)
 assert(not P.roulette.accept());snapshot=copy_table(G.ARGS.save_run)
end)
step('reward_pending',function()
 setup(5,5);b:remove();local c=SMODS.create_card{key='j_joker',no_edition=true,skip_materialize=true}
 assert(P.defer_fusion_reward(c));c:remove();save_run();snapshot=copy_table(G.ARGS.save_run)
 assert(#snapshot.GAME.fuse_rewards==1)
 G:delete_run();G:start_run{savetext=snapshot}
end,4)
step('reward_fusion',function()
 if not G.OVERLAY_MENU then assert(F.reward_offer()) end
 local c;for _,v in ipairs(G.I.CARD) do if v.fuse_reward_preview then c=v end end
 assert(c and F.fuse(F.context_options(c)[1]));assert(#G.GAME.fuse_rewards==0 and #G.jokers.cards==5)
end)
step('challenge_start',function()
 G:delete_run();G:start_run{challenge=SMODS.Challenges.c_incj_wake_up_neo,seed='NEO11'}
end,4)
step('anchored_options',function()
 option=G.jokers.cards[1];assert(option.config.center.key=='j_incj_options')
 assert(#G.jokers.cards==1 and G.jokers.config.card_limit==5)
 assert(IncJoker.options_challenge.anchored(option) and not option:can_sell_card())
 assert(SMODS.is_eternal(option,{fusion=true}))
 option:start_dissolve();option:shatter();option:remove();G.jokers:remove_card(option)
 option:set_ability(G.P_CENTERS.j_joker);option:set_edition({negative=true},true,true)
 assert(not option.removed and option.area==G.jokers and option.config.center.key=='j_incj_options' and not option.edition)
 assert(IncJoker.options.toggle(option));assert(option.ability.extra.selected=='B')
 G.STATE=G.STATES.HAND_PLAYED;assert(not IncJoker.options.toggle(option));G.STATE=G.STATES.BLIND_SELECT
 save_run();snapshot=copy_table(G.ARGS.save_run)
end)
step('challenge_reload',function() G:delete_run();G:start_run{savetext=snapshot} end,4)
step('challenge_persist_and_neutral_preview',function()
 option=G.jokers.cards[1];assert(IncJoker.options_challenge.anchored(option))
 assert(option.ability.extra.selected=='B' and #G.jokers.cards==1 and G.jokers.config.card_limit==5)
 local c=SMODS.create_card{key='j_incj_options',no_edition=true,skip_materialize=true}
 assert(c.children.center.sprite_pos.x==2);c:remove()
 local index;for i,d in ipairs(G.CHALLENGES) do if d.id=='c_incj_wake_up_neo' then index=i end end
 assert(index);G.SETTINGS.paused=true
 G.FUNCS.overlay_menu{definition=create_UIBox_generic_options{contents={G.UIDEF.challenge_description(index)}}}
end)
step('skin_native_selector',function()
 G.FUNCS.exit_overlay_menu();CardSkins.select(3)
 assert(CardSkins.active()=='four_realms')
 for _,c in ipairs(G.playing_cards) do
  local atlas,pos=CardSkins.front(c.config.card,c)
  assert(atlas.name=='skin_four_realms_lc' and pos==c.config.card.pos)
 end
 G.FUNCS.customize_deck()
end,2)
step('skin_high_contrast',function()
 G.SETTINGS.colourblind_option=true
 for _,c in ipairs(G.playing_cards) do
  local atlas=CardSkins.front(c.config.card,c);assert(atlas.name=='skin_four_realms_hc')
 end
 G.FUNCS.customize_deck()
end,2)
step('done',function() log('PASS contextual Fusion, anchored Options and native skin checks');love.event.quit() end)
local update,draw=love.update,love.draw;local i,t,pending=0,0
function love.update(dt)
 update(dt);t=t+dt;if t<(i==0 and 3 or steps[i].delay) then return end
 if i>0 then log('PASS '..steps[i].name) end;i=i+1;t=0
 if steps[i] then steps[i].fn();pending=steps[i].name end
end
function love.draw()
 draw();if pending and t>.5 then local name=pending;pending=nil;love.graphics.captureScreenshot(function(img)
 local f=assert(io.open(QA.out..'/'..name..'.png','wb'));f:write(img:encode('png'):getString());f:close() end) end
end
