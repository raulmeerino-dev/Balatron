return function(H)
 local C,X,P=H.challenges,H.X,H.P
 function C.shop_card(card)
  if not card or not card.area then return false end
  if card.area==G.shop_jokers or card.area==G.shop_booster or card.area==G.shop_vouchers then return true end
  local B=PortraitEvents and PortraitEvents.black_market
  if B and B.active then
   return card.area==B.area or card.area==G.black_market or (card.area.config and card.area.config.type=='shop')
  end
  return false
 end
 function C.hidden(card) return C.active('CH07') and C.shop_card(card) and not card.ability.hz_revealed end
 local function victims()
  local out={};if #G.playing_cards<=1 then return out end
  for _,card in ipairs(G.playing_cards) do if not card.removed and not SMODS.is_eternal(card,{hz_payment=true}) then out[#out+1]=card end end
  return out
 end
 function C.can_pay(card) return not C.active('CH03') or not C.shop_card(card) or card.ability.hz_paid_in_kind or #victims()>0 end
 function C.pay(card)
  if not C.active('CH03') or not C.shop_card(card) or card.ability.hz_paid_in_kind then return true end
  local pool=victims();if #pool==0 then return false end
  local s=C.state();s.purchase_serial=(s.purchase_serial or 0)+1
  local chosen=pseudorandom_element(pool,pseudoseed('hz_payment_'..s.purchase_serial))
  card.ability.hz_paid_in_kind=true;card.ability.hz_zero_purchase=true;card.cost=0
  -- The sacrifice is committed before the native purchase checkpoint. Its
  -- destruction context is native; only this card's removal is synchronous.
  local dissolve,shatter=chosen.start_dissolve,chosen.shatter
  local function retire(self)
   self:remove_from_deck();if self.area then self.area:remove_card(self) end;self:remove()
  end
  chosen.start_dissolve=retire;chosen.shatter=retire
  SMODS.destroy_cards({chosen},false,true)
  chosen.start_dissolve=dissolve;chosen.shatter=shatter
  return true
 end
 local cost=Card.set_cost
 function Card:set_cost(...)
  local r=cost(self,...)
  if C.active('CH03') and (C.shop_card(self) or self.ability.hz_zero_purchase) then self.cost=0 end
  return r
 end
 local emplace=CardArea.emplace
 function CardArea:emplace(card,...)
  local r=emplace(self,card,...)
  if C.active('CH03') and C.shop_card(card) then card:set_cost() end
  if self==G.jokers then C.joker_debuff(card) end
  return r
 end
 local open=Card.open
 function Card:open(...)
  if not C.pay(self) then return end
  if C.hidden(self) then self.ability.hz_revealed=true end
  return open(self,...)
 end
 local redeem=Card.redeem
 function Card:redeem(...)
  if not C.pay(self) then return end
  if C.hidden(self) then self.ability.hz_revealed=true end
  return redeem(self,...)
 end
 local check=Card.check_use
 function Card:check_use(...) if not C.can_pay(self) then return true end;return check(self,...) end
 H.on(function(c)
  if c.buying_card and c.card and c.card.ability.hz_zero_purchase then
   local card=c.card
   G.E_MANAGER:add_event(Event{trigger='after',delay=0.2,func=function() if card and not card.removed then card.ability.hz_zero_purchase=nil;card:set_cost() end;return true end})
  end
 end)
 local limit=CardArea.handle_card_limit
 local limiting=false
 function C.shared_limit(area)
  local j,c=G.jokers,G.consumeables
  if not C.active('CH06') or not j or not c or (area~=j and area~=c) then return end
  local jl,cl=j.config.card_limits,c.config.card_limits
  if not jl or not cl then return end
  local total=5+((jl.base or 5)-5)+((cl.base or 5)-5)+(jl.mod or 0)+(cl.mod or 0)+j:count_property('card_limit')+c:count_property('card_limit')
  local other=area==j and c or j
  local buffer=area==j and (G.GAME.consumeable_buffer or 0) or (G.GAME.joker_buffer or 0)
  return total-#other.cards-other:count_property('extra_slots_used')-buffer-area:count_property('extra_slots_used')
 end
 local function shared_config(area)
  local old=getmetatable(area.config)
  if not old or old.hz_shared then return end
  local mt={};for k,v in pairs(old) do mt[k]=v end;mt.hz_shared=true
  mt.__index=function(t,key)
   if key=='card_limit' then local value=C.shared_limit(area);if value~=nil then return value end end
   if type(old.__index)=='function' then return old.__index(t,key) end
   return old.__index and old.__index[key]
  end
  mt.__newindex=function(t,key,value)
   local current=key=='card_limit' and C.shared_limit(area)
   if current~=nil and current~=false then
    t.card_limits.mod=(t.card_limits.mod or 0)+value-current
    area:handle_card_limit();return
   end
   if old.__newindex then return old.__newindex(t,key,value) end
   rawset(t,key,value)
  end
  setmetatable(area.config,mt)
 end
 function CardArea:handle_card_limit(...)
  local r=limit(self,...)
  if limiting or not C.active('CH06') or not G.jokers or not G.consumeables or G.TAROT_INTERRUPT then return r end
  if self~=G.jokers and self~=G.consumeables then return r end
  limiting=true;shared_config(G.jokers);shared_config(G.consumeables);limit(G.jokers);limit(G.consumeables)
  local j,c=G.jokers,G.consumeables;local jl,cl=j.config.card_limits,c.config.card_limits
  if jl and cl then
   jl.total_slots=C.shared_limit(j)+jl.extra_slots_used
   cl.total_slots=C.shared_limit(c)+cl.extra_slots_used
  end
  limiting=false;return r
 end
 local function shadow_def(shadow)
  local original=G.P_BLINDS[shadow.original_key];local source=G.P_BLINDS[shadow.boss_key]
  if not original or not source then return original end
  local def=copy_table(source);def.boss=nil;def.mult=original.mult;def.dollars=original.dollars
  def.pos=original.pos;def.atlas=original.atlas;return def
 end
 local set=Blind.set_blind
 function Blind:set_blind(blind,reset,silent,...)
  if not reset then
   self.hz_shadow=nil
   if C.active('CH08') and blind and (blind.key=='bl_small' or blind.key=='bl_big') then
    self.hz_shadow={slot=blind.key=='bl_small' and 'Small' or 'Big',original_key=blind.key,boss_key=G.GAME.round_resets.blind_choices.Boss}
    blind=shadow_def(self.hz_shadow)
   end
  end
  local r=set(self,blind,reset,silent,...)
  if self.hz_shadow then self.boss=false end
  return r
 end
 local get_type=Blind.get_type
 function Blind:get_type(...) if self.hz_shadow then return self.hz_shadow.slot end;return get_type(self,...) end
 local text=Blind.set_text
 function Blind:set_text(...)
  local r=text(self,...)
  if self.hz_shadow then self.loc_name=localize{type='name_text',key=self.hz_shadow.original_key,set='Blind'} end
  return r
 end
 local disable=Blind.disable
 function Blind:disable(...)
  if self.hz_shadow and self.disabled then return end
  local chips=self.chips;local wall=self.hz_shadow and (self.hz_shadow.boss_key=='bl_wall' or self.hz_shadow.boss_key=='bl_final_vessel')
  local r=disable(self,...)
  if wall then self.chips=chips;self.chip_text=number_format(chips) end
  return r
 end
 local save=Blind.save
 function Blind:save(...) local data=save(self,...);data.hz_shadow=self.hz_shadow and copy_table(self.hz_shadow);return data end
 local load=Blind.load
 function Blind:load(data,...)
  self.hz_shadow=data.hz_shadow and copy_table(data.hz_shadow)
  local r=load(self,data,...)
  if self.hz_shadow then
   self.config.blind=shadow_def(self.hz_shadow);self.boss=false
   self.children.animatedSprite.atlas=SMODS.get_atlas(self.config.blind.atlas) or G.ANIMATION_ATLAS.blind_chips
   self.children.animatedSprite:set_sprite_pos(self.config.blind.pos)
   self:set_text()
  end
  return r
 end
 H.installers[#H.installers+1]=function()
  local use=G.FUNCS.use_card
  G.FUNCS.use_card=function(e,...)
   local card=e and e.config and e.config.ref_table
   if card and C.shop_card(card) and (card.ability.set=='Booster' or card.ability.set=='Voucher') then
    if card:check_use() then return end
    if not C.pay(card) then return end
    if C.hidden(card) then card.ability.hz_revealed=true end
   end
   return use(e,...)
  end
  local buy=G.FUNCS.buy_from_shop
  G.FUNCS.buy_from_shop=function(e,...)
   local card=e.config.ref_table
   if C.hidden(card) and e.config.id=='buy_and_use' then return end
   if C.active('CH03') and C.shop_card(card) then
    if e.config.id~='buy_and_use' and not G.FUNCS.check_for_buy_space(card) then return end
    if not C.pay(card) then return end
   end
   return buy(e,...)
  end
  for _,fn in ipairs({'can_buy','can_buy_and_use','can_open','can_redeem'}) do
   local original=G.FUNCS[fn]
   G.FUNCS[fn]=function(e,...)
    local r=original(e,...);local card=e.config.ref_table
    if not C.can_pay(card) or (fn=='can_buy_and_use' and C.hidden(card)) then e.config.button=nil;e.config.colour=G.C.UI.BACKGROUND_INACTIVE end
    return r
   end
  end
  local F=PortraitFusion
  if F then
   local afford,pay,options=F.source_afford,F.source_pay,F.context_options
   function F.source_afford(source) return C.can_pay(source.card) and afford(source) end
   function F.source_pay(source) if not C.pay(source.card) then return false end;return pay(source) end
   function F.context_options(card,...) if C.hidden(card) then return {} end;return options(card,...) end
  end
 end
end
