return function(B,C)
 C.register('counterfeit_voucher',17,{can=function() return #C.vouchers()>0 end,
 choices=function()
  local pool,out=C.vouchers(),{}
  for i=1,math.min(3,#pool) do local key=B.choose(pool,'counterfeit');out[#out+1]={key=key}
   for n=#pool,1,-1 do if pool[n]==key then table.remove(pool,n) end end
  end
  return out
 end,
 valid=function(card,choice) for _,key in ipairs(C.vouchers()) do if key==choice.key then return true end end end,
 apply=function(source,choice)
  local card=SMODS.create_card{set='Voucher',key=choice.key,skip_materialize=true}
  local previous=G.STATE
  card.cost=0;card.shop_voucher=false;card:redeem()
  -- Native redeem has its own transient state; this nested redemption is
  -- owned by the consumable's use transaction and must not strand it there.
  G.STATE=previous
  G.E_MANAGER:add_event(Event{func=function() card:remove();return true end})
 end})
end
