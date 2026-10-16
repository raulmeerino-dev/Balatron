-- The approved catalog supplies identity and mission text; effects live in the
-- versioned run module, so Collection never creates gameplay state.
local X=PortraitExpansion48
local descriptions={
 M01={'Cards retain two different Enhancements.','When adding a third, choose which to replace.'},
 M02={'In the shop, targeted Tarot can select','playing cards from your entire deck.'},
 M03={'For each paid reroll, choose the item row','or the Booster Pack row.'},
 M04={'Once per shop, mortgage up to 2 hands','from your next played Blind for $8 each.'},
 M05={'Before playing, choose any valid poker hand','contained in your selected cards.'},
 M06={'After a Small or Big Blind victory, choose','its Skip Tag instead of the entire cashout.'},
 M07={'After each Boss, transfer up to 3 levels','between visible hands, keeping level 1.'},
 M08={'New copies share future rank, suit,','Enhancement, Seal and Edition changes.'},
 M09={'Carry up to 2 unused base pack choices','to the next pack; old credit expires there.'},
 M10={'Held-card scoring resolves before','played-card scoring. Joker main stays last.'},
 M11={'Once per shop, remove an offered Joker','and ban its center from future random offers.'},
 M12={'Rent a shop Joker for one third of its price,','rounded up, until the next played Blind ends.'},
 M13={'Each failed Contract gets one retry','with the same terms and reward.'},
 M14={'Stake a completed Contract reward. The next','completion doubles it; a failure loses it.'},
 M15={'Pay $6 to replace one Fusion component','with a Joker of the same rarity.'},
 M16={'Ability money earned during a Blind instead','adds 2% of its goal to score per $1.'},
 M17={'Use this hand\'s base Chips and the base Mult','of the last different hand played this Blind.'},
 M18={'Store up to 3 new Tags and release them','later for their normal activation phase.'},
 M19={'After a Boss, optionally swap another Mutation','for one of three fixed eligible alternatives.'},
 M20={'Buy and store one unopened pack. Open it','between hands; its contents are fixed on purchase.'},
}
local defs={}
for i=1,20 do
 local id=string.format('M%02d',i);local d=X.catalog[id]
 defs[#defs+1]={id=d.key,expansion48=id,expansion=true,icon64=true,en=d.name_en,es=d.name,
  text_en=descriptions[id],text_es={d.effect}}
end
return defs
