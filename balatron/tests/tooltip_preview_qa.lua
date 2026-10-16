-- Requested focused regression: native popup geometry, class labels and previews.
-- Only packaged by the isolated desktop QA runner, never production.
local function log(s) local f=assert(io.open(QA.out..'/result.txt','a'));f:write(s..'\n');f:close() end
love.errorhandler=function(e) log('FAIL '..tostring(e)..'\n'..debug.traceback());return function() return 1 end end
love.errhand=love.errorhandler
local T=require('portrait_tooltips')
local steps={};local function step(name,fn,delay) steps[#steps+1]={name=name,fn=fn,delay=delay or 0.6} end
local live,failures= nil,0
local function check(name,fn)
 local ok,err=xpcall(fn,debug.traceback)
 log((ok and 'PASS ' or 'FAIL ')..name..(ok and '' or '\n'..err))
 if not ok then failures=failures+1 end
end
local function clear()
 if live then live:remove();live=nil end
 PortraitRunGallery.dismiss()
 if G.OVERLAY_MENU and G.OVERLAY_MENU.pc_collection_underlay then require('portrait_collection_info').close() end
 if G.OVERLAY_MENU then G.FUNCS.exit_overlay_menu() end
end
local function check_def(def)
 local valid,reason=T.valid_node(def)
 assert(valid,'Malformed popup node tree: '..tostring(reason))
 local function visit(node)
  if node.config.func=='show_infotip' and node.config.ref_table then
   for _,info in ipairs(node.config.ref_table) do
    assert(T.valid_node(info),'Malformed info_boxes entry')
    local box=UIBox{definition={n=G.UIT.ROOT,config={align='cm'},nodes={info}},config={align='cm',major=G.ROOM_ATTACH}}
    assert(box.T.w>=0 and box.T.h>=0);box:remove()
   end
  end
  for _,child in ipairs(node.nodes or {}) do visit(child) end
 end
 visit(def)
 local box=UIBox{definition=def,config={align='cm',major=G.ROOM_ATTACH}}
 assert(box.T.w>0 and box.T.h>0);box:remove()
end
local function check_aut(card)
 local a=card.ability_UIBox_table
 assert(type(a.main)=='table' and type(a.info)=='table' and type(a.badges)=='table')
 for _,row in ipairs(a.main) do for _,node in ipairs(row) do assert(T.valid_node(node)) end end
 for _,info in ipairs(a.info) do
  assert(type(info)=='table')
  for _,row in ipairs(info) do for _,node in ipairs(row) do assert(T.valid_node(node)) end end
 end
 for _,badge in ipairs(a.badges) do assert(type(badge)=='string','AUT badge must be a native label key') end
 log('AUT '..card.config.center.key..' type='..a.card_type..' main_rows='..#a.main..' info='..#a.info..' badge_keys='..#a.badges..' T='..type(card.T))
end
local keys={'j_upg_wayfinder','j_upg_orrery','j_upg_metamorphosis','j_upg_bottomless',
 'j_incj_options','j_incj_color_call','j_incj_double_entry','cb_evt_bribe','cb_evt_forgery','cb_evt_loaded_dice',
 'j_joker','j_blueprint','c_mercury','c_familiar'}
step('menu',function()
 G.SETTINGS.tutorial_complete=true;G.SETTINGS.tutorial_progress=nil;G.SETTINGS.SOUND.volume=0
 G:delete_run();G:main_menu()
end,3)
step('preview_matrix',function()
 local rng=STR_PACK(G.GAME.pseudorandom or {});local cards=#G.I.CARD
 for _,key in ipairs(keys) do
  check('standalone preview '..key,function()
   local center=assert(G.P_CENTERS[key]);local initial=STR_PACK(center.config)
   check_def(T.preview(center));assert(initial==STR_PACK(center.config))
  end)
 end
 assert(rng==STR_PACK(G.GAME.pseudorandom or {}) and cards==#G.I.CARD,'Preview must not spawn cards or consume RNG')
 check('invalid nodes rejected, optional nodes omitted',function()
  local nodes={};assert(not T.append_node(nodes,nil))
  assert(not T.append_node(nodes,{n=G.UIT.O,config={object={}}}))
  assert(not T.append_node(nodes,{n=G.UIT.R,config={},nodes={[2]={n=G.UIT.B,config={w=1,h=1}}}}))
  assert(#nodes==0)
  for _,class in ipairs({'UPG','Double','Contraband','Contract','Mutation'}) do
   assert(T.append_node(nodes,T.badge{class=class}))
  end
  assert(#nodes==5)
 end)
end)
for _,id in ipairs({'wayfinder','orrery','metamorphosis','bottomless'}) do
 local target=id
 step('collection_'..id,function()
  clear()
  for _,name in ipairs({'wayfinder','orrery','metamorphosis','bottomless'}) do
   G.P_CENTERS['j_upg_'..name].unlocked=true;G.P_CENTERS['j_upg_'..name].discovered=true
  end
  PortraitCollection.filter=4;G.FUNCS.your_collection_jokers()
  local found
  for _,area in ipairs(G.your_collection) do for _,card in ipairs(area.cards) do
   if card.config.center.key=='j_upg_'..target then found=card end
  end end
  assert(found,'UPG card missing from Collection')
  found.ability_UIBox_table=found:generate_UIBox_ability_table();check_aut(found)
  check_def(G.UIDEF.card_h_popup(found));found:click()
  assert(G.OVERLAY_MENU.pc_collection_underlay,'Family preview did not open')
 end)
end
step('collection_doubles',function()
 clear();PortraitCollection.filter=7;G.FUNCS.your_collection_jokers()
 local seen={}
 for _,area in ipairs(G.your_collection) do for _,card in ipairs(area.cards) do
  card.ability_UIBox_table=card:generate_UIBox_ability_table();check_aut(card)
  check_def(G.UIDEF.card_h_popup(card));card:hover();card:stop_hover()
  seen[card.config.center.key]=true
 end end
 for _,key in ipairs({'j_incj_options','j_incj_color_call','j_incj_double_entry'}) do assert(seen[key],key) end
end)
step('start_run',function() clear();G:delete_run();G:start_run{seed='TIPCHECK'};G.SETTINGS.GAMESPEED=4 end,3)
step('select_blind',function() G.FUNCS.select_blind{config={ref_table=G.P_BLINDS.bl_small},UIBox=G.blind_select} end,3)
local function physical(key,area,decorated)
 local center=assert(G.P_CENTERS[key]);center.unlocked=true;center.discovered=true
 local card=SMODS.create_card{key=key,area=area,no_edition=true,skip_materialize=true}
 area:emplace(card)
 if center.upg_id then
  card.ability.extra.stage=2
  if center.upg_id=='bottomless' then card.ability.extra.accumulated_mult=37;card.ability.extra.stage_progress=3
  else card.ability.extra.progress=3 end
 end
 if decorated then card:set_edition({foil=true},true,true);card.ability.eternal=true end
 local previous=STR_PACK({extra=card.ability.extra})
 card.ability_UIBox_table=card:generate_UIBox_ability_table();check_aut(card)
 check_def(G.UIDEF.card_h_popup(card))
 card:hover();card:stop_hover()
 assert(previous==STR_PACK({extra=card.ability.extra}),'Tooltip changed Joker progression')
 card:remove()
end
step('gameplay_native_hover_matrix',function()
 for _,key in ipairs(keys) do check('gameplay hover '..key,function()
  physical(key,G.P_CENTERS[key].set=='Joker' and G.jokers or G.consumeables)
 end) end
 check('vanilla Edition + eternal badges',function() physical('j_joker',G.jokers,true) end)
 check('UPG Edition + eternal badges',function() physical('j_upg_wayfinder',G.jokers,true) end)
end)
local function item_hover(info)
 local def=PortraitRunGallery.tooltip(info);check_def(def)
 local tile=PortraitRunGallery.tile({n=G.UIT.B,config={w=1,h=1}},function() return PortraitRunGallery.tooltip(info) end,nil,info.title)
 live=UIBox{definition={n=G.UIT.ROOT,config={align='cm'},nodes={tile}},config={align='cm',major=G.ROOM_ATTACH}}
 local entry=live.UIRoot.children[1];entry:hover();entry:stop_hover();live:remove();live=nil
end
step('contracts_mutations_hover_matrix',function()
 local C=PortraitGameplay.modules.contracts;local M=PortraitGameplay.modules.deck_mutations
 for _,status in ipairs({'active','complete','failed'}) do check('Contract '..status..' with progress',function()
  item_hover(C.info{id='clean_hands',uid=1,status=status,progress=1,target=2,duration='blinds'})
 end) end
 check('Contract completed with pending reward',function()
  local state=C.state();local pending=state.pending_spectral;state.pending_spectral=1
  local groups=PortraitRunGallery.groups('contract');assert(#groups==1)
  check_def({n=G.UIT.ROOT,config={align='cm'},nodes=groups[1].items})
  C.inspect({id='no_safety_net',uid=1,status='complete',progress=1,target=1,
   duration='next_boss',feedback_shown=true,reward={dollars=0,pending_spectral=true}},true)
  assert(G.OVERLAY_MENU.ct_result_uid==1);clear();state.pending_spectral=pending
 end)
 for _,id in ipairs({'double_planets','joker_habitat','heavy_hearts'}) do check('Mutation '..id,function()
  local profile=PortraitModifierUnlocks.profile()
  profile.unlocked[id]=id~='joker_habitat';profile.discovered[id]=true
  assert(PortraitModifierUnlocks.unlocked(id)==(id~='joker_habitat'))
  local info=M.visual_info(id,1)
  if id=='joker_habitat' then info.secondary=PortraitModifierUnlocks.info(id).text end
  item_hover(info)
 end) end
 for _,kind in ipairs({'contracts','mutations','contraband'}) do check('Collection item hovers '..kind,function()
  clear();local entries=PortraitCollection.entries(kind)
  for _,id in ipairs(entries) do PortraitCollection.mark(kind,id) end
  PortraitCollection.open(kind,1)
  local count=0
  local function walk(node)
   if node.config and node.config.pg_visual_tooltip then
    node:hover();node:stop_hover();count=count+1
   end
   for _,child in ipairs(node.children or {}) do walk(child) end
  end
  walk(G.OVERLAY_MENU.UIRoot);assert(count>0,'No gallery tooltip exercised')
 end) end
 clear()
end)
step('shop',function() clear();G.GAME.facing_blind=false;G.STATE=G.STATES.SHOP;G.STATE_COMPLETE=false end,3)
step('shop_native_hover_matrix',function()
 for _,key in ipairs(keys) do check('shop hover '..key,function() physical(key,G.shop_jokers) end) end
end)
step('final_wayfinder',function()
 clear();PortraitCollection.filter=4;G.FUNCS.your_collection_jokers()
 require('portrait_collection_family').open('upg','wayfinder')
end,1)
step('wayfinder_scroll_and_layout',function()
 local view=assert(G.OVERLAY_MENU:get_UIE_by_ID('pc_family_view')).config.object
 local root=view.content.UIRoot;local count=0;local previous
 local function walk(node)
  if node~=root then assert(node.UIT~=G.UIT.ROOT,'Embedded ROOT resets preview coordinates') end
  for _,child in ipairs(node.children or {}) do walk(child) end
 end
 walk(root)
 for _,node in ipairs(root.children) do
  if node.config.colour==G.C.BLACK then
   if previous then assert(node.T.y>=previous.T.y+previous.T.h,'Evolution panels overlap') end
   count=count+1;previous=node
  end
 end
 assert(count==3 and view.limit>0);view:scroll(view.limit)
 assert(view.offset==view.limit)
end,1)
step('done',function() log('DONE failures='..failures);love.event.quit(failures==0 and 0 or 1) end)
local update,draw=love.update,love.draw;local index,t,pending=0,0,nil
function love.update(dt)
 update(dt);t=t+dt
 if t<(index==0 and 3 or steps[index].delay) then return end
 index=index+1;t=0
 if steps[index] then check(steps[index].name,steps[index].fn);pending=steps[index].name end
end
function love.draw()
 draw()
 if pending and t>0.25 then
  local name=pending;pending=nil
  love.graphics.captureScreenshot(function(img)
   local f=assert(io.open(QA.out..'/'..name..'.png','wb'));f:write(img:encode('png'):getString());f:close()
  end)
 end
end
