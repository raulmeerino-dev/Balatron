return function(H)
 local U,P,X=H.rewardUI,H.P,H.X
 local T={};H.tags=T
 local process_loc=H.mod.process_loc_text
 H.mod.process_loc_text=function(...)
  if process_loc then process_loc(...) end
  local es=G.SETTINGS.language:sub(1,2)=='es'
  G.localization.descriptions.Other.hz_interval_reserved={
   name=es and 'Visita adicional' or 'Extra visit',
   text=es and {'Los Tags de próxima tienda','y la reserva de información','esperan la tienda ordinaria.'}
    or {'Next-shop Tags and the','Inside Information reservation','wait for the ordinary shop.'}}
 end
 local food={j_ice_cream={'extra','chips',100},j_popcorn={'mult',nil,20},j_ramen={'x_mult',nil,2},j_turtle_bean={'extra','h_size',5},j_selzer={'extra',nil,10}}
 local function state() return U.state() end
 local function tags(id)
  local out={};for _,t in ipairs(G.GAME.tags or {}) do if t.key==H.key(id) and not t.triggered and not t.ability.hz_consumed then out[#out+1]=t end end;return out
 end
 local function first(id) return tags(id)[1] end
 local function consume(t)
  if not t or t.ability.hz_consumed then return false end
  t.ability.hz_consumed=true;t.triggered=true
  G.E_MANAGER:add_event(Event{func=function()
   for _,owned in ipairs(G.GAME.tags or {}) do if owned==t then
    if t.HUD_tag then t:remove() else t:remove_from_game() end;break
   end end;return true
  end})
  return true
 end
 local load_tag=Tag.load
 function Tag:load(...)
  local result=load_tag(self,...)
  if self.ability.hz_consumed then
   self.ability.hz_consumed=nil;consume(self)
  end
  return result
 end
 local function value(c)
  local f=food[c.config.center.key];if not f then return end
  return f[2] and c.ability[f[1]][f[2]] or c.ability[f[1]],f
 end
 function T.foods()
  local out={};for _,c in ipairs(G.jokers and G.jokers.cards or {}) do
   local v,f=value(c)
   if v and v>0 and v<f[3] and not c.removed and not c.getting_sliced and not c.ability.x48_last_performance and not c.ability.exp48_lease then out[#out+1]=c end
  end;return out
 end
 function T.pantry()
  if not first('TX04') then return end
  U.choose(U.text('Reponer una comida','Refill one food Joker'),U.card_entries(T.foods()),function(id)
   local c=U.find(id);local tag=first('TX04');if not c or not tag then return end
   local valid=false;for _,q in ipairs(T.foods()) do if q==c then valid=true end end;if not valid then return end
   local v,f=value(c);consume(tag)
   if f[2] then c.ability[f[1]][f[2]]=f[3] else c.ability[f[1]]=f[3] end
   if c.config.center.key=='j_turtle_bean' and not c.debuff and c.added_to_deck then G.hand:change_size(f[3]-v) end
   c:juice_up();U.save()
  end)
 end
 G.FUNCS.hz_pantry=T.pantry
 local function price_targets(except)
  local out={};for _,c in ipairs(G.shop_jokers and G.shop_jokers.cards or {}) do
   if not c.removed and not c.getting_sliced and c.cost>0 and not c.ability.couponed and X.id(c)~=except then out[#out+1]=c end
  end;return out
 end
 function T.mislabel()
  if not U.shop() or (state().mislabels or 0)<1 then return end
  U.choose(U.text('Primera etiqueta','First price label'),U.card_entries(price_targets()),function(id)
   U.choose(U.text('Intercambiar con','Swap with'),U.card_entries(price_targets(id)),function(other)
    local a,b=U.find(id),U.find(other)
    if not U.shop() or (state().mislabels or 0)<1 or not a or not b or a==b or a.area~=G.shop_jokers or b.area~=G.shop_jokers or a.cost<=0 or b.cost<=0 then return end
    local ac,bc=a.cost,b.cost
    state().mislabels=state().mislabels-1
    a.ability.hz_price={price=bc,visit=state().visit};b.ability.hz_price={price=ac,visit=state().visit}
    a:set_cost();b:set_cost();U.save()
   end)
  end)
 end
 G.FUNCS.hz_mislabel=T.mislabel
 local cost=Card.set_cost
 function Card:set_cost(...)
  local r=cost(self,...);local q=self.ability and self.ability.hz_price
  if q and self.area==G.shop_jokers and state() and q.visit==state().visit and not self.ability.couponed then self.cost=q.price end
  return r
 end
 function T.before_jokers(chips,mult)
  local tag=first('TX05');if not tag then return chips,mult end
  local token=X.blind()..':'..G.GAME.hands_played
  if state().swap_hand==token then return chips,mult end
  state().swap_hand=token;consume(tag)
  local a,b=mod_chips(mult),mod_mult(chips);update_hand_text({delay=0},{chips=a,mult=b});return a,b
 end
 function T.extra_shop(tag)
  local s=H.state();if s.extra_shop or G.GAME.PACK_INTERRUPT or G.shop then return end
  consume(tag)
  s.extra_shop={used_packs=copy_table(G.GAME.current_round.used_packs or {}),reroll_cost=G.GAME.current_round.reroll_cost,
   reroll_increase=G.GAME.current_round.reroll_cost_increase,free_rerolls=G.GAME.current_round.free_rerolls}
  G.GAME.current_round.used_packs={};G.GAME.current_round.reroll_cost=G.GAME.round_resets.reroll_cost
  G.GAME.current_round.reroll_cost_increase=0;G.GAME.current_round.free_rerolls=0;calculate_reroll_cost(true)
  -- create_UIBox_blind_select has already queued its prompt alignment. Let it
  -- finish before removing that UI, or its native waiting event blocks the shop.
  G.CONTROLLER.locks.hz_interval=true
  G.E_MANAGER:add_event(Event{func=function()
   for _,key in ipairs({'blind_select','blind_prompt_box','buttons'}) do if G[key] then G[key]:remove();G[key]=nil end end
   G.STATE=G.STATES.SHOP;G.STATE_COMPLETE=false;G.CONTROLLER.locks.hz_interval=nil;U.save();return true
  end})
 end
 function T.xray(card)
  if not card or card.ability.set~='Booster' then return end
  if card.ability.hz_xray_snapshot then return card.ability.hz_xray_snapshot end
  local saved
  if card.config.center.key=='p_pg_roulette' then
   local r=P.roulette;local prizes=r and r.generate()
   if prizes then saved={roulette=true,contents=prizes} end
  elseif card.config.center.horizons and H.packs and H.packs.freeze then saved=H.packs.freeze(card)
  elseif X.mutations and X.mutations.freeze_pack then saved=X.mutations.freeze_pack(card) end
  if saved then
   -- Card.save retains its ability table. Detach it before attaching the
   -- snapshot to that same card, otherwise save/load would contain a cycle.
   saved=copy_table(saved)
   if saved.card and saved.card.ability then saved.card.ability.hz_xray_snapshot=nil end
   card.ability.hz_xray_snapshot=saved
  end;return saved
 end
 function T.inspect_pack(card)
  local saved=card and card.ability.hz_xray_snapshot;if not saved then return false end
  if saved.hz and H.packs and H.packs.preview then H.packs.preview(card);return true end
  local entries={};for i,c in ipairs(saved.contents or {}) do entries[#entries+1]={id=i,saved=c} end
  U.choose(U.text('Contenido del sobre','Pack contents'),entries,function() T.inspect_pack(card) end)
  return true
 end
 function T.inspect_packs()
  local entries={};for _,c in ipairs(G.shop_booster and G.shop_booster.cards or {}) do
   if c.ability.hz_xray_snapshot then entries[#entries+1]={id=X.id(c),saved=c:save()} end
  end
  U.choose(U.text('Radiografía','X-Ray'),entries,function(id) T.inspect_pack(U.find(id)) end)
 end
 G.FUNCS.hz_xray=T.inspect_packs
 local open=Card.open
 function Card:open(...)
  local saved=self.ability.hz_xray_snapshot
  if saved and saved.roulette and P.roulette then
   local generate=P.roulette.generate;local used=false
   P.roulette.generate=function(...) if not used then used=true;return copy_table(saved.contents) end;return generate(...) end
   local ok,r=xpcall(function() return open(self) end,debug.traceback);P.roulette.generate=generate
   if not ok then error(r) end;return r
  elseif saved and not saved.hz then
   self.ability.exp48_pack_contents=copy_table(saved.contents)
   self.ability.extra=saved.size-(G.GAME.modifiers.booster_size_mod or 0)
   self.ability.choose=saved.choices-(G.GAME.modifiers.booster_choice_mod or 0)
  end
  return open(self,...)
 end
 -- Tags retain their original timing/state. Optional shop actions are exposed
 -- on the affected object, including after loading a consumed shop-start Tag.
 local function card_action(card)
  local s=state()
  if not s or not P.normal_shop() or card.hz_preview or card.removed or card.getting_sliced then return end
  if U.shop() and card.area==G.shop_booster and s.xray_visit==s.visit and card.ability.hz_xray_snapshot then
   return 'xray',U.text('Radiografía','X-Ray')
  elseif U.shop() and card.area==G.shop_jokers and (s.mislabels or 0)>0 and card.cost>0 and not card.ability.couponed then
   return 'mislabel',U.text('Etiqueta cambiada','Mislabel')
  elseif card.area==G.jokers and first('TX04') then
   for _,c in ipairs(T.foods()) do if c==card then return 'pantry',U.text('Despensa','Pantry') end end
  end
 end
 G.FUNCS.hz_tag_card_action=function(e)
  local card=e.config.ref_table;local action=card and card_action(card)
  if action=='xray' then T.inspect_pack(card)
  elseif action=='mislabel' then T.mislabel()
  elseif action=='pantry' then T.pantry() end
 end
 local function clear_action(card)
  if card.children.hz_tag_action then card.children.hz_tag_action:remove();card.children.hz_tag_action=nil end
  card.hz_tag_action=nil
 end
 local update=Card.update
 function Card:update(dt,...)
  local result=update(self,dt,...)
  local action,label
  if not G.OVERLAY_MENU and (self.highlighted or self.children.focused_ui) then action,label=card_action(self) end
  if self.hz_tag_action~=action then
   clear_action(self)
   if action then
    self.hz_tag_action=action
    local align,offset='bm',{x=0,y=0.1}
    if self.area==G.shop_jokers or self.area==G.shop_booster then
     -- Buy/Open already occupies the bottom; Buy and Use occupies mid-right.
     -- Place the Tag action beside the upper half, towards the room interior.
     align=self.T.x-G.ROOM.T.x<2.2 and 'cr' or 'cl'
     offset={x=align=='cl' and -0.08 or 0.08,y=-self.T.h/2+0.45}
    end
    self.children.hz_tag_action=UIBox{definition={n=G.UIT.ROOT,config={align='cm',padding=0.06,r=0.08,
     minw=1.2,maxw=2.1,minh=portrait_touch_height(0.65),colour=G.C.GOLD,shadow=true,hover=true,
     one_press=true,ref_table=self,button='hz_tag_card_action'},nodes={
      {n=G.UIT.T,config={text=label,scale=0.28,colour=G.C.UI.TEXT_DARK,shadow=true}}
     }},config={align=align,offset=offset,parent=self}}
   end
  end
  return result
 end
 local highlight=Card.highlight
 function Card:highlight(on,...)
  local result=highlight(self,on,...);if not on then clear_action(self) end;return result
 end
 for i=1,8 do
  local id=string.format('TX%02d',i);local d=H.meta[id];local key=d.key:gsub('^tag_hz_','')
  H.atlas(key,'tags/'..key..'.png',34,34)
  local loc=U.loc(id);for lang,v in pairs(loc) do v.unlock=U.wrap(lang=='en-us' and d.unlock_en or d.unlock) end
  SMODS.Tag{key=key,atlas=key,pos={x=0,y=0},unlocked=false,discovered=false,horizons=id,loc_txt=loc,config={},
   loc_vars=function(_,queue) if id=='TX06' then queue[#queue+1]={key='hz_interval_reserved',set='Other'} end;return {} end,
   min_ante=2,
   in_pool=function()
    if not H.enabled('tags',id) or not H.unlocked(id) or not state() then return false end
    if id=='TX02' then return state().last_sale~=nil elseif id=='TX04' then return #T.foods()>0 end
    return true
   end,
   set_ability=function(_,tag)
    if not state() then return end
    if id=='TX02' and state().last_sale then tag.ability.hz_sale=copy_table(state().last_sale) end
   end,
   apply=function(_,tag,context)
    local s=state();if not s or tag.ability.hz_consumed then return end
    if id=='TX02' and context.type=='shop_final_pass' and U.shop() then
     local sale=tag.ability.hz_sale or s.last_sale
     s.returned_sales=s.returned_sales or {}
     if not sale or s.returned_sales[sale.serial] then return end
     if U.find(sale.id) then return end
     s.returned_sales[sale.serial]=true;consume(tag)
     local c=U.preview(sale.saved);c.hz_preview=nil;c.ability.hz_price={price=math.max(G.P_CENTERS[c.config.center.key].cost or 0,2*sale.price+1),visit=s.visit}
     c.ability.couponed=nil;c.ability.evt_bm_price=nil;c.ability.exp48_lease=nil
     G.shop_jokers.config.card_limit=G.shop_jokers.config.card_limit+1;G.shop_jokers:emplace(c)
     c:set_cost();create_shop_card_ui(c);c:start_materialize();U.save();return true
    elseif id=='TX03' and context.type=='shop_start' and U.shop() then
     s.mislabels=(s.mislabels or 0)+1;consume(tag);return true
    elseif id=='TX04' and context.type=='new_blind_choice' and #T.foods()>0 and not G.OVERLAY_MENU then T.pantry();return true
    elseif id=='TX06' and context.type=='new_blind_choice' and not H.state().extra_shop and not G.shop then T.extra_shop(tag);return true
    elseif id=='TX07' and context.type=='round_start_bonus' and not s.procession then
     local amount=math.max(0,6-(G.GAME.starting_params.play_limit or 5));s.procession={amount=amount,blind=X.blind()};consume(tag);if amount>0 then SMODS.change_play_limit(amount) end;return true
    elseif id=='TX08' and context.type=='shop_start' and U.shop() then
     s.xray_visit=s.visit;consume(tag);return true
    end
   end}
 end
 -- Fool's delayed native creation consults the selected key once. No new effect.
 local create=create_card
 function create_card(set,area,legendary,rarity,skip,soulable,key,append,...)
  local s=state()
  if s and append=='fool' then
   if s.fool_target then key=s.fool_target;s.fool_target=nil end
   local m=U.metrics();m.fool_targets=m.fool_targets or {};if key then m.fool_targets[key]=true end
  end
  return create(set,area,legendary,rarity,skip,soulable,key,append,...)
 end
 local use=G.FUNCS.use_card
 local can_use=Card.can_use_consumeable
 function Card:can_use_consumeable(...)
  local s=state()
  if s and self.config.center.key=='c_fool' and first('TX01') and #(s.fool_history or {})>0 then
   local previous=G.GAME.last_tarot_planet;G.GAME.last_tarot_planet=self.ability.hz_fool_ready or s.fool_history[1]
   local result=can_use(self,...);G.GAME.last_tarot_planet=previous;return result
  end
  return can_use(self,...)
 end
 G.FUNCS.use_card=function(e,...)
  local c=e and e.config and e.config.ref_table;local s=state()
  if s and c and c.config.center.key=='c_fool' and first('TX01') and not c.ability.hz_fool_ready then
   local entries={};for _,key in ipairs(s.fool_history or {}) do if G.P_CENTERS[key] then entries[#entries+1]=U.key_entry(key) end end
   if #entries>0 then
    local ref=X.id(c)
    U.choose(U.text('Marcador: recuperar','Bookmark: recreate'),entries,function(key)
     local source=U.find(ref);if not source then return end
     source.ability.hz_fool_ready=key;G.FUNCS.use_card{config={ref_table=source}}
    end);return
   end
  end
  if s and c and c.ability.hz_fool_ready then
   if not c:can_use_consumeable() then c.ability.hz_fool_ready=nil;return end
  end
  return use(e,...)
 end
 H.installers[#H.installers+1]=function()
  local ready=P.shop_ready
  function P.shop_ready(...)
   if H.state() and H.state().extra_shop then
    local C=P.modules.contracts
    if C and C.state() and not H.state().extra_shop.entered then C.state().shop_serial=(C.state().shop_serial or 0)+1;H.state().extra_shop.entered=true end
    U.save();return
   end
   local r=ready(...)
   if state() and state().xray_visit==state().visit then for _,c in ipairs(G.shop_booster.cards) do T.xray(c) end;U.save() end
   return r
  end
  -- Preserve the next ordinary shop's Inside Information reservation.
  local populate=Game.populate_shop_stock
  function Game:populate_shop_stock(...)
   local B=PortraitEvents and PortraitEvents.black_market;local bs=B and B.state and B.state()
   local held
   if H.state() and H.state().extra_shop and bs then held={next_stock=bs.next_stock,reservation=bs.reservation};bs.next_stock=nil;bs.reservation=nil end
   local r=populate(self,...)
   if held then bs.next_stock=held.next_stock;bs.reservation=held.reservation end
   if state() and U.shop() and state().xray_visit==state().visit then for _,c in ipairs(G.shop_booster.cards) do T.xray(c) end end
   return r
  end
  local leave=G.FUNCS.toggle_shop
  G.FUNCS.toggle_shop=function(e,...)
   local s=state();if s and s.alembic_pending then H.vouchers.alembic_pending();return end
   if s and s.contract_pending then H.vouchers.choose_contract();return end
   local extra=H.state() and H.state().extra_shop
   local r=leave(e,...)
   if extra and G.CONTROLLER.locks.toggle_shop then
    G.E_MANAGER:add_event(Event{trigger='after',delay=0.55,blocking=false,blockable=false,func=function()
     if G.shop or G.CONTROLLER.locks.toggle_shop then return false end
     G.GAME.current_round.used_packs=extra.used_packs;G.GAME.current_round.reroll_cost=extra.reroll_cost
     G.GAME.current_round.reroll_cost_increase=extra.reroll_increase;G.GAME.current_round.free_rerolls=extra.free_rerolls
     H.state().extra_shop=nil;U.save();return true
    end})
   end
   return r
  end
 end
 H.on(function(c)
  local s=state();if not s then return end;local m=U.metrics()
  if c.using_consumeable and c.consumeable then
   local card=c.consumeable;local key=card.config.center.key
   if key=='c_fool' and card.ability.hz_fool_ready then
    s.fool_target=card.ability.hz_fool_ready;card.ability.hz_fool_ready=nil;consume(first('TX01'))
   end
   if key~='c_fool' and (card.ability.set=='Tarot' or card.ability.set=='Planet') then
    s.fool_history=s.fool_history or {};for i=#s.fool_history,1,-1 do if s.fool_history[i]==key then table.remove(s.fool_history,i) end end
    table.insert(s.fool_history,1,key);while #s.fool_history>3 do table.remove(s.fool_history) end
   end
  end
  if c.exp48_selling and c.card.ability.set=='Joker' and not c.card.ability.exp48_lease and not c.card.ability.x48_last_performance then
   local card=c.card;s.sale_serial=(s.sale_serial or 0)+1
   local price=(c.price or card.sell_cost or 0)+(PortraitRunRules and PortraitRunRules.has('profitable_sale') and 1 or 0)
   s.last_sale={serial=s.sale_serial,id=X.id(card),saved=copy_table(card:save()),price=price}
   if price>=20 then m.sale20=true end
   for _,tag in ipairs(tags('TX02')) do if tag.ability.hz_sale and s.returned_sales and s.returned_sales[tag.ability.hz_sale.serial] then tag.ability.hz_sale=copy_table(s.last_sale) end end
  end
  if c.starting_shop then m.shop_spent=false;m.shop_big_joker=false;m.shop_cheap_consumable=false end
  if c.buying_card and c.card and P.normal_shop() then
   m.shop_spent=true
   if c.card.ability.set=='Joker' and c.card.cost>=15 then m.shop_big_joker=true end
   if c.card.ability.consumeable and c.card.cost<=3 then m.shop_cheap_consumable=true end
   if m.shop_big_joker and m.shop_cheap_consumable then m.mislabel_ready=true end
  end
  if c.reroll_shop then m.shop_spent=true end
  if c.ending_shop then
   m.frugal_shops=m.shop_spent and 0 or (m.frugal_shops or 0)+1;s.mislabels=0;s.xray_visit=nil
  end
  if c.open_booster and c.card then
   if not c.card.from_tag then m.purchased_families=m.purchased_families or {};m.purchased_families[c.card.config.center.kind or c.card.config.center.key]=true end
   s.tag_pack_taken=false
  end
  if c.using_consumeable and c.area==G.pack_cards or c.buying_card and c.card and c.card.area==G.pack_cards then s.tag_pack_taken=true end
  if c.ending_booster and not s.tag_pack_taken then m.empty_pack=true end
  if c.before and G.GAME.blind.boss then
   if not m.boss_hands then m.boss_hands=0;m.boss_five=true end
   m.boss_hands=m.boss_hands+1;if #(c.full_hand or {})~=5 then m.boss_five=false end
  end
  if c.exp48_blind_paid then
   if s.procession then if s.procession.amount>0 then SMODS.change_play_limit(-s.procession.amount) end;s.procession=nil end
   if G.GAME.blind.boss then
    local ante=G.GAME.round_resets.ante
    m.five_bosses=m.boss_five and (m.boss_hands or 0)>0 and (m.five_bosses or 0)+1 or 0;m.boss_hands=nil;m.boss_five=nil
    if m.five_bosses>=3 then H.unlock('TX07') end
    if ante>=6 then
     if X.count(m.fool_targets)>=3 then H.unlock('TX01') end
     if m.sale20 then H.unlock('TX02') end
     if m.mislabel_ready then H.unlock('TX03') end
     if X.count(m.exhausted_foods)>=3 then H.unlock('TX04') end
     if (m.frugal_shops or 0)>=3 then H.unlock('TX06') end
     if X.count(m.purchased_families)>=4 and m.empty_pack then H.unlock('TX08') end
    end
   end
  end
 end)
 -- Native foods queue removal without first decrementing their last use to zero.
 local calculate=Card.calculate_joker
 function Card:calculate_joker(context,...)
  local a,b=calculate(self,context,...)
  if state() and self.area==G.jokers and food[self.config.center.key] and not context.blueprint and type(a)=='table'
   and (a.message==localize('k_eaten_ex') or a.message==localize('k_melted_ex') or a.message==localize('k_drank_ex')) then
   self.ability.hz_food_exhausted=true
  end
  return a,b
 end
 -- Only physical exhaustion counts; a healthy food sold or destroyed does not.
 local remove=Card.remove
 function Card:remove(...)
  if state() and not self.hz_preview and self.added_to_deck and self.ability.set=='Joker' then
   if self.ability.hz_food_exhausted then local m=U.metrics();m.exhausted_foods=m.exhausted_foods or {};m.exhausted_foods[self.config.center.key]=true end
  end
  return remove(self,...)
 end
 function T.final_score(chips,mult)
  if not state() or not G.GAME.blind.boss or G.GAME.round_resets.ante<6 then return end
  local editions=false;for _,c in ipairs(G.jokers.cards) do if not c.debuff and c.edition and c.edition.polychrome then editions=true end end
  if not editions and chips>=500 and mult>=100 and G.GAME.chips+math.floor(chips*mult)>=G.GAME.blind.chips then state().metrics.topsy_ready=X.blind() end
 end
 H.on(function(c)
  if c.exp48_blind_paid and state().metrics.topsy_ready==X.blind() then H.unlock('TX05') end
 end)
end
