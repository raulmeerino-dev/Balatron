return function(X,A,P,M,R,definitions)
 local T=X.text
 local function owned(card,area) return card and card.area==area and not card.removed and not card.getting_sliced end
 local function target_tarot(c)
  return c.ability.set=='Tarot' and c.ability.consumeable and c.ability.consumeable.max_highlighted
 end
 A.actions.workbench=function()
  if not A.has('M02') or not P.normal_shop() then return end
  A.cards(T('Elige un Tarot de tu inventario','Choose a Tarot from your inventory'),G.consumeables.cards,'workbench_tarot',target_tarot)
 end
 A.actions.workbench_tarot=function(id)
  local card=A.find(id);if not owned(card,G.consumeables) or not target_tarot(card) then return end
  A.state().workbench_selection={tarot=id,targets={}};A.actions.workbench_targets()
 end
 A.actions.workbench_targets=function()
  local plan=A.state().workbench_selection;local tarot=plan and A.find(plan.tarot)
  if not tarot then return A.open() end
  local rows={P.text(T('Orden de selección: Death copia la derecha','Selection order: Death copies the rightmost'))}
  for _,card in ipairs(G.playing_cards) do if not card.removed and not card.getting_sliced then
   local n;for i,id in ipairs(plan.targets) do if id==X.id(card) then n=i end end
   rows[#rows+1]=A.button((n and '['..n..'] ' or '')..A.label(card),'workbench_target',X.id(card))
  end end
  rows[#rows+1]=A.button(T('Usar Tarot','Use Tarot'),'workbench_confirm')
  A.menu(A.label(tarot),rows)
 end
 A.actions.workbench_target=function(id)
  local p=A.state().workbench_selection;local tarot=p and A.find(p.tarot);if not tarot then return end
  for i,value in ipairs(p.targets) do if value==id then table.remove(p.targets,i);return A.actions.workbench_targets() end end
  if #p.targets<tarot.ability.consumeable.max_highlighted then p.targets[#p.targets+1]=id end
  A.actions.workbench_targets()
 end
 function A.restore_workbench()
  local s=A.state();local active=s and s.workbench_active;if not active then return end
  if G.CONTROLLER.locks.use or G.STATE==G.STATES.PLAY_TAROT then return false end
  G.hand:unhighlight_all()
  for _,info in ipairs(active) do
   local card=X.find(info.id);local area=G[info.area]
   if card and card.area==G.hand and area and area~=G.hand then
    G.hand:remove_card(card);area:emplace(card)
    -- Restore the pre-action relative location; new/copied cards keep native positions.
    for i,v in ipairs(area.cards) do if v==card then table.remove(area.cards,i);break end end
    table.insert(area.cards,math.min(info.index,#area.cards+1),card)
   end
  end
  s.workbench_active=nil;s.workbench_selection=nil;A.save();return true
 end
 A.actions.workbench_confirm=function()
  local s=A.state();local p=s.workbench_selection;local tarot=p and A.find(p.tarot)
  if not A.has('M02') or not P.normal_shop() or not owned(tarot,G.consumeables) or not target_tarot(tarot) then return end
  local targets={};for _,id in ipairs(p.targets) do local c=X.find(id);if c and not c.getting_sliced then targets[#targets+1]=c end end
  local limit=tarot.ability.consumeable
  if #targets<(limit.min_highlighted or 1) or #targets>limit.max_highlighted then return end
  local old_highlighted=G.hand.highlighted;G.hand.highlighted=targets
  local state=G.STATE;G.STATE=G.STATES.SELECTING_HAND
  local valid=tarot:can_use_consumeable(true,true);G.STATE=state;G.hand.highlighted=old_highlighted
  if not valid then return end
  G.hand:unhighlight_all();s.workbench_active={}
  for i,c in ipairs(targets) do
   local area=c.area;local area_key
   for key,value in pairs(G) do if value==area and type(key)=='string' then area_key=key;break end end
   area_key=area_key or 'deck'
   local index=1;for j,v in ipairs(area and area.cards or {}) do if v==c then index=j;break end end
   s.workbench_active[#s.workbench_active+1]={id=X.id(c),area=area_key,index=index}
   if area~=G.hand then if area then area:remove_card(c) end;G.hand:emplace(c) end
   c.T.x=G.hand.T.x+i*0.5;c.highlighted=true;G.hand.highlighted[#G.hand.highlighted+1]=c
  end
  A.close();G.FUNCS.use_card({config={ref_table=tarot}})
  G.E_MANAGER:add_event(Event{blocking=false,blockable=false,func=function() return A.restore_workbench() end})
 end
 -- A row reroll uses exactly the same cost/counter event as an item reroll,
 -- but never re-enters the shop or reapplies its Tags.
 local reroll=G.FUNCS.reroll_shop
 G.FUNCS.reroll_shop=function(e)
  if A.state() and A.has('M03') and P.normal_shop() and (G.GAME.current_round.reroll_cost or 0)>0 then
   return A.menu(T('Carrusel','Carousel'),{
    A.button(T('Renovar artículos','Reroll items'),'reroll_items'),A.button(T('Renovar sobres','Reroll packs'),'reroll_packs')},'exit_overlay_menu')
  end
  return reroll(e)
 end
 A.actions.reroll_items=function()
  if not A.has('M03') or not P.normal_shop() or not A.afford(G.GAME.current_round.reroll_cost) then return end
  A.close();reroll()
 end
 A.actions.reroll_packs=function()
  local cost=G.GAME.current_round.reroll_cost or 0
  if not A.has('M03') or not P.normal_shop() or cost<=0 or not A.afford(cost) or not G.shop_booster then return end
  A.close();stop_use()
  inc_career_stat('c_shop_dollars_spent',cost);inc_career_stat('c_shop_rerolls',1);ease_dollars(-cost,true)
  G.GAME.round_scores.times_rerolled.amt=G.GAME.round_scores.times_rerolled.amt+1
  calculate_reroll_cost(false)
  local count=G.shop_booster.config.card_limit or 2
  for i=#G.shop_booster.cards,1,-1 do local c=G.shop_booster.cards[i];G.shop_booster:remove_card(c);c:remove() end
  G.GAME.current_round.used_packs={}
  for i=1,count do
   local center=get_pack('exp48_carousel_'..A.state().shop..'_'..G.GAME.round_scores.times_rerolled.amt..'_'..i)
   G.GAME.current_round.used_packs[i]=center.key
   local c=Card(G.shop_booster.T.x,G.shop_booster.T.y,G.CARD_W*1.27,G.CARD_H*1.27,G.P_CARDS.empty,center,
    {bypass_discovery_center=true,bypass_discovery_ui=true})
   c.ability.booster_pos=i;create_shop_card_ui(c,'Booster',G.shop_booster);G.shop_booster:emplace(c)
  end
  SMODS.calculate_context{reroll_shop=true};play_sound('coin2');A.save()
 end
 function A.next_hands()
  local n=G.GAME.round_resets.hands+(G.GAME.round_bonus.next_hands or 0)
  for _,c in ipairs(G.jokers.cards) do if not c.debuff and c.config.center.key=='j_burglar' then n=n+3 end end
  if R.has('field_reserves') and G.GAME.blind_on_deck=='Boss' then n=n+1 end
  return math.max(1,n)-(A.state().mortgage or 0)
 end
 A.actions.mortgage=function()
  local s=A.state();if not A.has('M04') or not P.normal_shop() or s.mortgaged_shop then return end
  local rows={};for n=1,math.min(2,A.next_hands()-1) do
   rows[#rows+1]=A.button(T('Cobrar $','Receive $')..(8*n)..T(' / manos siguientes: ',' / next hands: ')..(A.next_hands()-n),'mortgage_confirm',n)
  end
  A.menu(T('Mercado de futuros','Futures Market'),rows)
 end
 A.actions.mortgage_confirm=function(n)
  local s=A.state()
  if not A.has('M04') or not P.normal_shop() or s.mortgaged_shop or n<1 or n>2 or A.next_hands()-n<1 then return end
  s.mortgaged_shop=true;s.mortgage=(s.mortgage or 0)+n;ease_dollars(n*8,true);A.close()
 end
 A.actions.blacklist=function()
  if not A.has('M11') or not P.normal_shop() or A.state().blacklisted_shop then return end
  A.cards(T('Vetar una oferta sin cobrar ni reponer','Ban an offer without selling or replacing it'),G.shop_jokers.cards,'blacklist_confirm',function(c) return c.ability.set=='Joker' end)
 end
 A.actions.blacklist_confirm=function(id)
  local s=A.state();local c=A.find(id)
  if not A.has('M11') or not P.normal_shop() or s.blacklisted_shop or not owned(c,G.shop_jokers) or c.ability.set~='Joker' then return end
  local pool=P.pool('Joker',c.config.center.rarity);local others=false
  for _,key in ipairs(pool) do if key~=c.config.center.key and not s.blacklist[key] then others=true;break end end
  if not others then return end
  s.blacklist[c.config.center.key]=true;s.blacklisted_shop=true
  G.shop_jokers:remove_card(c);c:remove();A.close()
 end
 local pool=get_current_pool
 function get_current_pool(set,...)
  local entries,key=pool(set,...);local s=A.state()
  if set~='Joker' or not s or not next(s.blacklist) then return entries,key end
  local out={};for _,v in ipairs(entries) do if not s.blacklist[v] then out[#out+1]=v end end
  return out,key
 end
 local function can_rent(c)
  return c.ability.set=='Joker' and not SMODS.is_eternal(c,{exp48_rent=true}) and not c.ability.exp48_lease
 end
 A.actions.rent=function()
  if not A.has('M12') or not P.normal_shop() then return end
  local rows={};for _,c in ipairs(G.shop_jokers.cards) do if can_rent(c) then
   rows[#rows+1]=A.button(A.label(c)..' ($'..math.ceil(c.cost/3)..')','rent_confirm',X.id(c))
  end end;A.menu(T('Alquilar hasta terminar la siguiente ciega','Rent until the next played Blind ends'),rows)
 end
 A.actions.rent_confirm=function(id)
  local c=A.find(id)
  if not A.has('M12') or not P.normal_shop() or not owned(c,G.shop_jokers) or not can_rent(c) then return end
  local price=math.ceil(c.cost/3);local extra=(c.ability.card_limit or 0)-(c.ability.extra_slots_used or 0)
  if not A.afford(price) or #G.jokers.cards+(G.GAME.joker_buffer or 0)>=G.jokers.config.card_limit+extra then return end
  c.ability.exp48_lease={pending=true};c.cost=price
  ease_dollars(-price,true);inc_career_stat('c_shop_dollars_spent',price)
  G.GAME.round_scores.cards_purchased.amt=G.GAME.round_scores.cards_purchased.amt+1
  G.GAME.current_round.jokers_purchased=(G.GAME.current_round.jokers_purchased or 0)+1
  for _,key in ipairs({'price','buy_button'}) do if c.children[key] then c.children[key]:remove();c.children[key]=nil end end
  G.shop_jokers:remove_card(c);c:add_to_deck();G.jokers:emplace(c)
  SMODS.calculate_context{buying_card=true,card=c}
  if G.GAME.modifiers.inflation then
   G.GAME.inflation=G.GAME.inflation+1
   for _,v in ipairs(G.I.CARD) do if v.set_cost then v:set_cost() end end
  end
  A.close()
 end
 local sell=Card.can_sell_card
 function Card:can_sell_card(...) if self.ability.exp48_lease then return false end;return sell(self,...) end
 local sellcard=Card.sell_card
 function Card:sell_card(...) if self.ability.exp48_lease then return end;return sellcard(self,...) end
 X.listen(function(c)
  local s=A.state();if not s or not P.real(c) then return end
  if c.setting_blind then
   for _,j in ipairs(G.jokers.cards) do if j.ability.exp48_lease and j.ability.exp48_lease.pending then
    j.ability.exp48_lease={blind=P.token()}
   end end
  end
  if c.first_hand_drawn and (s.mortgage or 0)>0 then
   local amount=math.min(s.mortgage,math.max(0,G.GAME.current_round.hands_left-1))
   s.mortgage=s.mortgage-amount;ease_hands_played(-amount);A.save()
  end
  if P.won(c) then
   local expired={};for _,j in ipairs(G.jokers.cards) do if j.ability.exp48_lease and not j.ability.exp48_lease.pending then expired[#expired+1]=j end end
   if #expired>0 then G.E_MANAGER:add_event(Event{func=function()
    for _,j in ipairs(expired) do if not j.removed then j:remove_from_deck();if j.area then j.area:remove_card(j) end;j:remove() end end
    A.save();return true
   end}) end
  end
 end)
 -- Recipe validation stays native. Only the candidate key is substituted during
 -- this synchronous transaction, so capacity, stickers and inherited state agree.
 function A.install()
  local F=PortraitFusion;if not F or F.exp48_installed then return end;F.exp48_installed=true
  local can=F.can
  function F.can(d,a,b,source)
   if a and a.ability.exp48_lease or b and b.ability.exp48_lease then return false end
   return can(d,a,b,source)
  end
 end
 A.actions.spare_parts=function()
  local F=PortraitFusion
  if not A.has('M15') or not P.normal_shop() or not F or not F.enabled() or not A.afford(6) then return end
  local rows={}
  for _,key in ipairs(F.order) do local d=F.entries[key]
   if F.config().recipes[key] and X.eligible('j_fuse_'..key) then
    for side=1,2 do for _,exact in ipairs(G.jokers.cards) do
     if exact.config.center.key==d.components[side] and not exact.ability.exp48_lease then
      local missing=G.P_CENTERS[d.components[3-side]]
      for slot,other in ipairs(G.jokers.cards) do
       if other~=exact and missing and other.config.center.rarity==missing.rarity and not other.ability.exp48_lease and
        not SMODS.is_eternal(other,{fusion=true}) and other.config.center.key~=d.components[3-side] then
        local old=d.components[3-side];d.components[3-side]=other.config.center.key
        local a,b=side==1 and exact or other,side==1 and other or exact
        local valid=F.can(d,a,b);d.components[3-side]=old
        if valid then rows[#rows+1]=A.button(localize{type='name_text',set='Joker',key='j_fuse_'..key}..' / Joker '..slot,'spare_parts_review',
         {recipe=key,side=side,a=X.id(a),b=X.id(b)}) end
       end
      end
     end
    end end
   end
  end
  A.menu(T('Piezas intercambiables — $6','Spare Parts — $6'),rows)
 end
 A.actions.spare_parts_review=function(data)
  local a,b=A.find(data.a),A.find(data.b);if not a or not b then return end
  A.menu(localize{type='name_text',set='Joker',key='j_fuse_'..data.recipe},{
   P.text(A.label(a)),P.text('+'),P.text(A.label(b)),
   A.button(T('Fusionar por $6','Fuse for $6'),'spare_parts_confirm',data)})
 end
 A.actions.spare_parts_confirm=function(data)
  local F=PortraitFusion;local d=F and F.entries[data.recipe];local a,b=A.find(data.a),A.find(data.b)
  if not A.has('M15') or not P.normal_shop() or not d or not a or not b or not A.afford(6) then return end
  local side=data.side;local exact=side==1 and a or b;local other=side==1 and b or a
  local original=d.components[3-side];local missing=G.P_CENTERS[original]
  if exact.config.center.key~=d.components[side] or not missing or missing.rarity~=other.config.center.rarity or SMODS.is_eternal(other,{fusion=true}) then return end
  d.components[3-side]=other.config.center.key
  local valid=F.can(d,a,b)
  if valid then
   ease_dollars(-6,true);A.close();valid=F.fuse{id=data.recipe,a=a,b=b}
   if not valid then ease_dollars(6,true) end
  end
  d.components[3-side]=original;A.save()
 end
end
