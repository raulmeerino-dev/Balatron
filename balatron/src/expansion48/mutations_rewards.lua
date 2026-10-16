return function(X,A,P,M,R,definitions)
 local T=X.text
 local by_key={};for _,d in ipairs(definitions) do by_key[d.id]=d end
 -- A failed Contract remains a failed attempt for missions. The Contracts owner
 -- calls this after recording failure and preserves the original reward template.
 local install=A.install
 function A.install()
  if install then install() end
  local C=PortraitContracts
  if C and not C.exp48_retry_installed then
   C.exp48_retry_installed=true
   local previous=C.retry_failed
   C.retry_failed=function(a,event,data)
    if previous and previous(a,event,data) then return true end
    if A.has('M13') and not a.exp48_retry and event~='lost_run' and C.reset then
     a.exp48_retry=true
     a.exp48_retry_wait={duration=a.duration,token=P.token(),ante=G.GAME.round_resets.ante,shop=C.state().shop_serial or 0}
     C.reset(a);return true
    end
    return false
   end
  end
  -- Every native Booster is opened by the same center:create_card route. A
  -- frozen pack substitutes its saved objects before any fresh RNG is requested.
  for _,center in ipairs(G.P_CENTER_POOLS.Booster or {}) do
   if center.create_card and not center.exp48_frozen_pack then
    center.exp48_frozen_pack=true;local native=center.create_card
    center.create_card=function(self,booster,i,...)
     local contents=booster.ability.exp48_pack_contents
     if contents and contents[i] then
      local card=Card(0,0,G.CARD_W,G.CARD_H,G.P_CARDS.empty,G.P_CENTERS.c_base,{bypass_discovery_center=true})
      card:load(copy_table(contents[i]));return card
     end
     return native(self,booster,i,...)
    end
   end
  end
 end
 -- Capture only reversible acquisition bonuses. Monetary/deck changes are never
 -- undone when Molting replaces the rule that caused them.
 local function snapshot()
  return {hand=G.hand.config.card_limit,jokers=G.jokers.config.card_limit,consumables=G.consumeables.config.card_limit,
   hands=G.GAME.round_resets.hands,discards=G.GAME.round_resets.discards,reroll=G.GAME.round_resets.reroll_cost,
   shop=G.GAME.shop.joker_max,interest=G.GAME.interest_cap,no_interest=G.GAME.modifiers.no_interest}
 end
 for _,d in ipairs(definitions) do if d.apply then
  local original,id=d.apply,d.id
  d.apply=function(...)
   local before=snapshot();local result=original(...);local after=snapshot();local s=A.state()
   if s then
    s.bonuses=s.bonuses or {};local recorded=s.bonuses[id] or {};s.bonuses[id]=recorded
    for key,value in pairs(after) do if type(value)=='number' then recorded[key]=(recorded[key] or 0)+value-(before[key] or 0) end end
    if id=='no_interest' then recorded.previous_no_interest=before.no_interest or false end
   end
   return result
  end
 end end
 function A.remove_mutation(id)
  local s=A.state();local levels=M.state().levels;local n=levels[id] or 0
  if n<=0 or id=='molting' then return false end
  local d=by_key[id];local bonus=s.bonuses and s.bonuses[id]
  if not bonus then
   bonus={hand=(d.hand_size or (id=='deep_pockets' and 1 or 0))*n,
    jokers=id=='joker_habitat' and n or id=='consumable_exchange' and -n or 0,
    consumables=id=='bigger_pockets' and n or id=='consumable_exchange' and 2*n or 0,
    hands=id=='second_chance' and n or 0,discards=(d.discards or (id=='loose_hands' and 1 or 0))*n,
    reroll=(d.reroll or 0)*n,shop=(d.shop or 0)*n,interest=id=='interest_rate' and n*5/G.GAME.interest_amount or 0}
  end
  levels[id]=nil
  if bonus.hand~=0 then G.hand:change_size(-(bonus.hand or 0)) end
  if bonus.jokers~=0 then G.jokers:change_size(-(bonus.jokers or 0)) end
  if bonus.consumables~=0 then G.consumeables:change_size(-(bonus.consumables or 0)) end
  G.GAME.round_resets.hands=G.GAME.round_resets.hands-(bonus.hands or 0)
  G.GAME.round_resets.discards=G.GAME.round_resets.discards-(bonus.discards or 0)
  G.GAME.round_resets.reroll_cost=G.GAME.round_resets.reroll_cost-(bonus.reroll or 0)
  if (bonus.shop or 0)~=0 then change_shop_size(-bonus.shop) end
  G.GAME.interest_cap=G.GAME.interest_cap-(bonus.interest or 0)
  if d.rate then G.GAME[d.rate]=(G.GAME[d.rate] or 0)/2 end
  if id=='rare_market' then G.GAME.rare_mod=(G.GAME.rare_mod or 2)/2 end
  if id=='fewer_commons' then G.GAME.common_mod=(G.GAME.common_mod or .2)/.2 end
  if id=='no_interest' and bonus.previous_no_interest~=nil then G.GAME.modifiers.no_interest=bonus.previous_no_interest or nil end
  if d.pack_options then G.GAME.modifiers.booster_size_mod=(G.GAME.modifiers.booster_size_mod or 0)-d.pack_options end
  if id=='frequent_packs' then G.GAME.modifiers.extra_boosters=(G.GAME.modifiers.extra_boosters or 0)-1 end
  if id=='second_pick' then G.GAME.modifiers.booster_choice_mod=(G.GAME.modifiers.booster_choice_mod or 0)-1 end
  if id=='free_reroll' then SMODS.change_free_rerolls(-1) end
  if id=='chaos' and M.state().chaos_bonus then
   local key=M.state().chaos_bonus
   if key=='hand_size' then G.hand:change_size(-1) else G.GAME.round_resets[key]=G.GAME.round_resets[key]-1 end
   M.state().chaos_bonus=nil;M.state().chaos_ante=nil
  end
  if s.bonuses then s.bonuses[id]=nil end
  calculate_reroll_cost(true)
  for _,area in ipairs({G.jokers,G.consumeables,G.shop_jokers,G.shop_booster}) do
   for _,card in ipairs(area and area.cards or {}) do card:set_cost() end
  end
  return true
 end
 A.actions.decanting=function()
  local s=A.state();if not s.decanting then return end
  local rows={A.button(T('No trasladar niveles','Keep levels'),'decanting_skip')}
  for _,key in ipairs(G.handlist) do local h=G.GAME.hands[key]
   if h and h.visible and h.level>1 then rows[#rows+1]=A.button(localize(key,'poker_hands')..' ('..h.level..')','decanting_from',key) end
  end
  A.menu(T('Trasvase: mano donante','Decanting: source hand'),rows)
 end
 A.actions.decanting_skip=function() A.state().decanting=nil;A.close();P.schedule_offers() end
 A.actions.decanting_from=function(from)
  if not A.state().decanting then return end
  local rows={};for _,to in ipairs(G.handlist) do local h=G.GAME.hands[to]
   if h and h.visible and to~=from then
    for n=1,math.min(3,G.GAME.hands[from].level-1) do
     rows[#rows+1]=A.button(localize(to,'poker_hands')..' +'..n,'decanting_confirm',{from=from,to=to,n=n})
    end
   end
  end
  A.menu(T('Trasvase: mano receptora','Decanting: destination hand'),rows)
 end
 A.actions.decanting_confirm=function(data)
  local s=A.state();local from,to=G.GAME.hands[data.from],G.GAME.hands[data.to]
  if not s.decanting or not from or not to or not from.visible or not to.visible or data.from==data.to or data.n<1 or data.n>3 or from.level-data.n<1 then return end
  s.decanting=nil
  level_up_hand(nil,data.from,true,-data.n,'mutation');level_up_hand(nil,data.to,true,data.n,'mutation')
  A.close();P.schedule_offers()
 end
 A.actions.molting=function()
  local s=A.state();if not s.molting then return end
  local rows={A.button(T('Conservar Mutations','Keep Mutations'),'molting_skip')}
  for _,d in ipairs(definitions) do if d.id~='molting' and (M.state().levels[d.id] or 0)>0 then
   rows[#rows+1]=A.button(localize('k_dm_'..d.id),'molting_from',d.id)
  end end
  A.menu(T('Muda: elige qué Mutation retirar','Molting: choose a Mutation to remove'),rows)
 end
 A.actions.molting_skip=function() A.state().molting=nil;A.close();P.schedule_offers() end
 A.actions.molting_from=function(id)
  local s=A.state();if not s.molting or id=='molting' or (M.state().levels[id] or 0)==0 then return end
  local rows={}
  for _,key in ipairs(s.molting.choices) do if PortraitModifierUnlocks.unlocked(key) and (M.state().levels[key] or 0)==0 then
   rows[#rows+1]=A.button(localize('k_dm_'..key),'molting_confirm',{from=id,to=key})
  end end
  A.menu(T('Muda: elige el reemplazo','Molting: choose the replacement'),rows)
 end
 A.actions.molting_confirm=function(data)
  local s=A.state();local found=false
  for _,id in ipairs(s.molting and s.molting.choices or {}) do if id==data.to then found=true end end
  if not found or not by_key[data.to] or not PortraitModifierUnlocks.unlocked(data.to) or (M.state().levels[data.to] or 0)>0 then return end
  if not A.remove_mutation(data.from) then return end
  M.state().levels[data.to]=1;s.molting=nil
  if by_key[data.to].apply then by_key[data.to].apply() end
  if PortraitCollection then PortraitCollection.mark('mutations',data.to,1) end
  A.close();P.schedule_offers()
 end
 -- Cashout is offered before its single native receipt. No skip event is emitted.
 local cash=G.FUNCS.cash_out
 G.FUNCS.cash_out=function(e)
  local s=A.state()
  if s and A.has('M06') and not G.GAME.blind.boss and not s.cashout_choice and G.round_eval then
   local key=s.won_skip_tag
   if key and G.P_TAGS[key] then
    A.cashout_button=e
    return A.menu(T('Entrada doble','Two-Way Ticket'),{
     A.button(T('Cobrar $','Collect $')..tostring(G.GAME.current_round.dollars),'cashout_money'),
     A.button(localize{type='name_text',set='Tag',key=key},'cashout_tag')},'exit_overlay_menu')
   end
  end
  return cash(e)
 end
 A.actions.cashout_money=function()
  A.state().cashout_choice='money';local e=A.cashout_button
  A.close();if G.round_eval then cash(e or {config={}}) end
 end
 A.actions.cashout_tag=function()
  local s=A.state();if not G.round_eval or not s.won_skip_tag or s.cashout_choice then return end
  s.cashout_choice='tag';G.GAME.current_round.dollars=0
  local overkill=G.GAME.current_round.portrait_overkill;if overkill then overkill.paid=true end
  local tag=Tag(s.won_skip_tag,nil,s.won_blind_type);add_tag(tag)
  for _,owned_tag in ipairs(G.GAME.tags) do if owned_tag==tag then tag:apply_to_run{type='immediate'};break end end
  A.close();cash(A.cashout_button or {config={}})
 end
 -- Stored Tags never enter G.GAME.tags until released: Double Tag cannot copy
 -- them early, and vanilla owns every actual activation.
 local add=add_tag
 function add_tag(tag,...)
  local s=A.state()
  if s and A.has('M18') and not A.releasing_tag then
   if #s.tags<3 then s.tags[#s.tags+1]=copy_table(tag:save());A.save();return end
   s.incoming_tags=s.incoming_tags or {};s.incoming_tags[#s.incoming_tags+1]=copy_table(tag:save())
   A.save();G.E_MANAGER:add_event(Event{blocking=false,blockable=false,func=function()
    if G.OVERLAY_MENU or G.CONTROLLER.locked or G.CONTROLLER.locks.use or
      not (G.STATE==G.STATES.SELECTING_HAND or G.STATE==G.STATES.SHOP or G.STATE==G.STATES.BLIND_SELECT or G.STATE==G.STATES.ROUND_EVAL) then return false end
    A.actions.tags();return true
   end});return
  end
  return add(tag,...)
 end
 function A.release_tag(saved)
  local tag=Tag(saved.key,true);tag:load(copy_table(saved));A.releasing_tag=true;add_tag(tag);A.releasing_tag=nil
  tag:apply_to_run{type='immediate'}
  if G.STATE==G.STATES.BLIND_SELECT then tag:apply_to_run{type='new_blind_choice'} end
 end
 A.actions.tags=function()
  local s=A.state();local rows={}
  if s.incoming_tags and s.incoming_tags[1] then
   rows[#rows+1]=A.button(T('Activar el nuevo Tag','Activate the incoming Tag'),'tag_incoming')
  end
  for i,tag in ipairs(s.tags) do rows[#rows+1]=A.button(localize{type='name_text',set='Tag',key=tag.key},'tag_release',i) end
  A.menu(T('Consigna: liberar un Tag','Left Luggage: release a Tag'),rows)
 end
 A.actions.tag_incoming=function()
  local s=A.state();local tag=s.incoming_tags and table.remove(s.incoming_tags,1)
  if tag then A.close();A.release_tag(tag);A.save() end
 end
 A.actions.tag_release=function(i)
  local s=A.state();local tag=s.tags[i];if not tag then return end
  table.remove(s.tags,i)
  if s.incoming_tags and s.incoming_tags[1] then s.tags[#s.tags+1]=table.remove(s.incoming_tags,1) end
  A.close();A.release_tag(tag);A.save()
 end
 function A.convert_money(amount,card,source)
  if not A.state() or not A.has('M16') or amount<=0 or not G.GAME.facing_blind or not G.GAME.blind then return false end
  if source=='sale' or source=='reward' or source=='loan' or source=='cashout' or source=='refund' then return false end
  local score=G.GAME.blind.chips*.02*amount
  G.GAME.chips=(G.GAME.chips or 0)+score;X.money_converted=(X.money_converted or 0)+1
  if G.HUD then G.HUD:recalculate() end
  return true
 end
 -- Direct vanilla ability payouts (Hermit, Mail-in Rebate, etc.) can be queued
 -- events. Preserve their provenance across those events, excluding sale and
 -- externally issued reward/loan transactions.
 local add_event=EventManager.add_event
 function EventManager:add_event(event,...)
  local source=A.money_source
  if source and event.func and not event.exp48_money_wrapped then
   event.exp48_money_wrapped=true;local native=event.func
   event.func=function(...)
    local before=A.money_source;A.money_source=source
    local result=native(...);A.money_source=before;return result
   end
  end
  return add_event(self,event,...)
 end
 local money=ease_dollars
 function ease_dollars(amount,...)
  local source=A.money_source
  if source and amount>0 and not SMODS.ease_dollars_calc and A.state() and G.GAME.facing_blind then
   local converted=A.convert_money(amount,source,'ability')
   if converted then
    X.track{exp48_money=true,amount=amount,card=source,native_playing=source.playing_card~=nil,converted=true}
    return
   end
   local result=money(amount,...)
   X.track{exp48_money=true,amount=amount,card=source,native_playing=source.playing_card~=nil,converted=false}
   return result
  end
  return money(amount,...)
 end
 local joker=Card.calculate_joker
 function Card:calculate_joker(context,...)
  local before=A.money_source
  if G.GAME and G.GAME.facing_blind and not context.selling_self and not context.selling_card and
    not context.buying_card and not context.reroll_shop then A.money_source=self end
  local effect,post=joker(self,context,...);A.money_source=before;return effect,post
 end
 local consume=Card.use_consumeable
 function Card:use_consumeable(...)
  local before=A.money_source
  if G.GAME and G.GAME.facing_blind then A.money_source=self end
  local result=consume(self,...);A.money_source=before;return result
 end
 -- Freeze by using the Booster's native creation API at purchase, serializing
 -- actual cards. There is no second implementation of Tarot/Seal/Edition effects.
 -- Native saves do not reconstruct OPENED_BOOSTER or its UI. Keep one atomic
 -- checkpoint before this pack and one after it: a reload during the animation
 -- returns to the pending receipt with identical contents and no partial payout.
 local save_native=save_run
 function save_run(...)
  if A.frozen_pack_active then A.frozen_pack_dirty=true;return end
  return save_native(...)
 end
 function A.freeze_pack(booster)
  A.install()
  local center=booster.config.center;if not center.create_card then return end
  local size=math.max(1,booster.ability.extra+(G.GAME.modifiers.booster_size_mod or 0))
  local choices=math.min((booster.ability.choose or center.config.choose or 1)+(G.GAME.modifiers.booster_choice_mod or 0),size)
  local saved={card=booster:save(),contents={},size=size,choices=choices}
  local used=copy_table(G.GAME.used_jokers)
  for i=1,size do
   local args=center:create_card(booster,i)
   local c=type((args or {}).is)=='function' and args:is(Card) and args or SMODS.create_card(args)
   saved.contents[i]=c:save();c:remove()
  end
  for key in pairs(G.GAME.used_jokers) do G.GAME.used_jokers[key]=nil end
  for key,value in pairs(used) do G.GAME.used_jokers[key]=value end
  return saved
 end
 function A.open_pack(saved,source)
  if not saved or G.GAME.PACK_INTERRUPT or G.booster_pack then return false end
  A.save();A.frozen_pack_active=true;A.frozen_pack_source=source
  local c=Card(0,0,G.CARD_W,G.CARD_H,G.P_CARDS.empty,G.P_CENTERS.c_base,{bypass_discovery_center=true})
  c:load(copy_table(saved.card));c.cost=0;c.from_tag=true;c.ability.booster_pos=nil
  c.ability.extra=saved.size-(G.GAME.modifiers.booster_size_mod or 0)
  c.ability.choose=saved.choices-(G.GAME.modifiers.booster_choice_mod or 0)
  c.ability.exp48_pack_contents=copy_table(saved.contents)
  if G.STATE==G.STATES.SELECTING_HAND then A.state().pack_preserve_hand=true end
  G.FUNCS.use_card({config={ref_table=c}},nil,true);return true
 end
 A.actions.takeaway=function()
  if not A.has('M20') or not P.normal_shop() or A.state().takeaway then return end
  A.cards(T('Comprar y guardar un sobre','Buy and store a pack'),G.shop_booster.cards,'takeaway_confirm')
 end
 A.actions.takeaway_confirm=function(id)
  local s=A.state();local c=A.find(id)
  if not A.has('M20') or not P.normal_shop() or s.takeaway or not c or c.area~=G.shop_booster or not A.afford(c.cost) then return end
  local saved=A.freeze_pack(c);if not saved then return end
  s.takeaway=saved;ease_dollars(-c.cost,true);inc_career_stat('c_shop_dollars_spent',c.cost)
  G.GAME.round_scores.cards_purchased.amt=G.GAME.round_scores.cards_purchased.amt+1
  if c.ability.booster_pos then G.GAME.current_round.used_packs[c.ability.booster_pos]='USED' end
  SMODS.calculate_context{buying_card=true,card=c}
  G.shop_booster:remove_card(c);c:remove();A.close()
 end
 A.actions.open_takeaway=function()
  local s=A.state()
  if not s.takeaway or not (A.safe() or P.normal_shop() or G.STATE==G.STATES.BLIND_SELECT) then return end
  local saved=s.takeaway;A.close()
  A.open_pack(saved,'takeaway')
 end
 local draw=G.FUNCS.draw_from_deck_to_hand
 G.FUNCS.draw_from_deck_to_hand=function(...)
  local s=A.state();if s and s.pack_preserve_hand and G.GAME.PACK_INTERRUPT then return end
  return draw(...)
 end
 local return_hand=G.FUNCS.draw_from_hand_to_deck
 G.FUNCS.draw_from_hand_to_deck=function(...)
  local s=A.state();if s and s.pack_preserve_hand and G.GAME.PACK_INTERRUPT then return end
  return return_hand(...)
 end
 local open=Card.open
 function Card:open(...)
  local result=open(self,...);local s=A.state()
  if s and self.ability.set=='Booster' then
   local base=G.GAME.pack_choices or 1;local credit=A.has('M09') and (s.rain_credit or 0) or 0
   local size=math.max(1,self.ability.extra+(G.GAME.modifiers.booster_size_mod or 0))
   s.rain_pack={base=base,credit=math.min(credit,math.max(0,size-base)),choices=0};s.rain_credit=0
   G.GAME.pack_choices=math.min(size,base+credit)
  end
  return result
 end
 local use=G.FUNCS.use_card
 G.FUNCS.use_card=function(e,...)
  local s=A.state();local c=e.config.ref_table
  local selected=s and s.rain_pack and c and c.area==G.pack_cards and s.rain_pack
  local result=use(e,...)
  if selected and c.area~=G.pack_cards then selected.choices=selected.choices+1 end
  return result
 end
 local finish=G.FUNCS.end_consumeable
 G.FUNCS.end_consumeable=function(...)
  local s=A.state()
  if s and s.rain_pack then
   -- Base choices are spent first. Unused old credit can never be carried again.
   s.rain_credit=A.has('M09') and math.min(2,math.max(0,s.rain_pack.base-s.rain_pack.choices)) or 0
   s.rain_pack=nil
  end
  local result=finish(...)
  if A.frozen_pack_active then
   G.E_MANAGER:add_event(Event{blocking=false,blockable=false,func=function()
    if G.GAME.PACK_INTERRUPT or G.booster_pack or G.STATE==G.STATES.PLAY_TAROT then return false end
    A.frozen_pack_active=nil;A.frozen_pack_dirty=nil;A.frozen_pack_source=nil;A.save();return true
   end})
  end
  if s and s.pack_preserve_hand then
   G.E_MANAGER:add_event(Event{blocking=false,blockable=false,func=function()
    if G.GAME.PACK_INTERRUPT then return false end;s.pack_preserve_hand=nil;A.save();return true
   end})
  end
  return result
 end
 X.listen(function(c)
  local s=A.state();if not s or not P.real(c) then return end
  if c.ending_booster and A.frozen_pack_source=='takeaway' then s.takeaway=nil end
  if c.setting_blind then
   s.cashout_choice=nil;s.won_blind_type=G.GAME.blind_on_deck;s.won_skip_tag=G.GAME.round_resets.blind_tags[G.GAME.blind_on_deck]
  end
  if P.won(c) and c.beat_boss and X.once('exp48_mutation_boss:'..P.token()) then
   if A.has('M07') then s.decanting={blind=P.token()} end
   if A.has('M19') then
    local candidates={};for _,d in ipairs(definitions) do
     local weights=M.config().mutation_weights or {}
     local weight=weights[d.id]~=nil and weights[d.id] or M.mod.config.mutation_weights[d.id] or 6
     if d.id~='molting' and weight>0 and (M.state().levels[d.id] or 0)==0 and PortraitModifierUnlocks.unlocked(d.id) then candidates[#candidates+1]=d.id end
    end
    local choices={}
    for i=1,math.min(3,#candidates) do local index=math.min(#candidates,math.floor(P.roll('exp48_molting_'..P.token()..'_'..i)*#candidates)+1)
     choices[#choices+1]=table.remove(candidates,index)
    end
    if #choices>0 then s.molting={choices=choices} end
   end
  end
 end)
end
