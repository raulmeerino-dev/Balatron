-- Isolated native-input regression requested for portrait touch inspection.
local function log(s) local f=assert(io.open(QA.out..'/touch-result.txt','a'));f:write(s..'\n');f:close() end
love.errorhandler=function(e) log('CRASH '..tostring(e)..'\n'..debug.traceback());return function() return 1 end end
love.errhand=love.errorhandler
local steps={};local function step(name,fn,delay) steps[#steps+1]={name=name,fn=fn,delay=delay or .3} end
local card,x,y,clicks,hovers,popups,failed= nil,0,0,0,0,0,0
local function point()
 -- Native cards can live in a translated UIBox (shop/Collection).
 return card:put_focused_cursor()
end
local function info(label)
 local c=G.CONTROLLER;local p=c.tooltip_press or {}
 log(label..' target='..tostring(p.node==card)..' down='..tostring(c.is_cursor_down)..' cancelled='..tostring(p.cancelled)..
  ' hover='..hovers..' popup_calls='..popups..' popup='..tostring(card.children.h_popup~=nil)..' definition='..tostring(card.config.h_popup~=nil)..' clicks='..clicks)
end
step('menu',function()
 G.SETTINGS.tutorial_complete=true;G.SETTINGS.tutorial_progress=nil;G.SETTINGS.SOUND.volume=0
 G:delete_run();G:main_menu()
end,3)
step('run',function() G:delete_run();G:start_run{seed='TOUCHQA'};G.SETTINGS.GAMESPEED=4 end,3)
local cases={
 {'j_joker'}, {'j_joker','foil'}, {'j_joker','eternal'},
 {'j_incj_compound_interest'},{'j_incj_hipster'},
 {'j_risk_greed'},{'j_risk_glass_cannon'}, {'j_fuse_midas'},{'j_fuse_broken_copier'},
 {'j_upg_wayfinder'},{'j_upg_orrery'},
 {'j_incj_options'},{'j_incj_color_call'},{'j_incj_double_entry'}}
local initial_mode
local function close()
 PortraitRunGallery.dismiss()
 if G.OVERLAY_MENU and G.OVERLAY_MENU.pc_collection_underlay then require('portrait_collection_info').close() end
 if G.OVERLAY_MENU then G.FUNCS.exit_overlay_menu() end
end
for _,context in ipairs({'selection','gameplay','shop','pack','collection'}) do
 local ctx=context
 step(ctx..' context',function()
  if card and not card.REMOVED then card:remove() end;card=nil
  close()
  if ctx=='gameplay' then G.FUNCS.select_blind{config={ref_table=G.P_BLINDS.bl_small},UIBox=G.blind_select}
  elseif ctx=='shop' then G.GAME.facing_blind=false;G.STATE=G.STATES.SHOP;G.STATE_COMPLETE=false
  elseif ctx=='pack' then
   local booster=SMODS.create_card{key='p_buffoon_normal_1',area=G.shop_booster,skip_materialize=true}
   G.shop_booster:emplace(booster);booster.cost=0;booster:open()
  end
 end,3)
 for index,case in ipairs(cases) do
  local k,decoration=case[1],case[2];local label=ctx..' '..k..' '..(decoration or '')
  local jitter=index%2==0 and 6 or 2
  step(label..' create',function()
   if card and not card.REMOVED then card:remove() end
   local center=assert(G.P_CENTERS[k]);center.discovered=true;center.unlocked=true
   if ctx=='collection' then
    close();PortraitCollection.filter=1
    local pool=SMODS.collection_pool
    SMODS.collection_pool=function() return {center} end
    G.FUNCS.your_collection_jokers();SMODS.collection_pool=pool
    card=assert(G.your_collection[1].cards[1])
   else
    local area=ctx=='shop' and G.shop_jokers or ctx=='pack' and G.pack_cards or G.jokers
    for i=#area.cards,1,-1 do area.cards[i]:remove() end
    card=SMODS.create_card{key=k,area=area,no_edition=true,skip_materialize=true};area:emplace(card)
   end
   if decoration=='foil' then card:set_edition({foil=true},true,true) end
   if decoration=='eternal' then card.ability.eternal=true end
   clicks=0;hovers=0;popups=0
   initial_mode=type(card.ability.extra)=='table' and card.ability.extra.selected
   local click,hover=card.click,card.hover
   card.click=function(self,...) clicks=clicks+1;return click(self,...) end
   card.hover=function(self,...) hovers=hovers+1;return hover(self,...) end
  end,.35)
  step(label..' touch down',function() x,y=point();love.event.push('touchpressed',1,x,y,0,0,1) end,.15)
  step(label..' jitter',function()
   assert(not card.children.h_popup,'Tooltip opened before long-press threshold')
   love.event.push('touchmoved',1,x+jitter,y+jitter,jitter,jitter,1)
  end,.45)
  step(label..' hold',function()
   info(label..' HOLD');assert(card.children.h_popup,'Long press did not create popup')
   assert(G.CONTROLLER.tooltip_press.shown,'Long press was not consumed')
   if initial_mode then assert(card.ability.extra.selected==initial_mode,'Hold changed A/B') end
  end,.05)
  step(label..' release',function() love.event.push('touchreleased',1,x+jitter,y+jitter,0,0,1) end,.15)
  step(label..' released',function()
   assert(clicks==0,'Long press also clicked');assert(not card.children.h_popup)
   if initial_mode then assert(card.ability.extra.selected==initial_mode,'Release changed A/B') end
  end,.05)
  step(label..' tap',function() x,y=point();love.event.push('touchpressed',2,x,y,0,0,1) end,.08)
  step(label..' tap release',function()
   assert(not card.children.h_popup,'Short tap opened tooltip');love.event.push('touchreleased',2,x,y,0,0,1)
  end,.15)
  step(label..' tapped',function()
   assert(clicks==1,'Short tap did not click exactly once')
   if initial_mode and card.area==G.jokers then assert(card.ability.extra.selected~=initial_mode,'Tap did not switch A/B') end
   if ctx=='collection' and card.config.center.upg_id then assert(G.OVERLAY_MENU.pc_collection_underlay,'UPG tap did not open evolutions') end
  end,.05)
 end
end
step('done',function() log('DONE failures='..failed);love.event.quit(failed==0 and 0 or 1) end)
local popup=G.UIDEF.card_h_popup
G.UIDEF.card_h_popup=function(c,...) if c==card then popups=popups+1 end;return popup(c,...) end
local update,draw=love.update,love.draw;local i,t,pending=0,0,nil
function love.update(dt)
 update(dt);t=t+dt
 if t<(i==0 and 3 or steps[i].delay) then return end
 i=i+1;t=0
 if steps[i] then
  local ok,e=xpcall(steps[i].fn,debug.traceback);log((ok and 'PASS ' or 'FAIL ')..steps[i].name..(ok and '' or '\n'..e))
  if not ok then failed=failed+1 end;pending=steps[i].name:gsub(' ','_')
 end
end
function love.draw()
 draw()
 if pending and t>.02 then local name=pending;pending=nil
  if name:find('_hold$') then love.graphics.captureScreenshot(function(img)
   local f=assert(io.open(QA.out..'/touch-'..name..'.png','wb'));f:write(img:encode('png'):getString());f:close()
  end) end
 end
end
