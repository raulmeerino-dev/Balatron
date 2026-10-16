local categories={
    doubles={title='DOUBLES',text={'Jokers with two states you can','choose between during a run.','','Each card keeps its own selection.','Check its description for the','effects of each side.'}},
    mutations={title='MUTATIONS',text={
        'Mutations change the rules', 'of the current run.', '',
        'After defeating a Boss Blind,', 'you can choose one from several options.', '',
        'They can improve:', '- hands and discards', '- cards and suits', '- economy', '- slots', '- other run rules', '',
        'Obtained Mutations last until', 'the run ends.', '',
        'The counter tracks discovered Mutations.', 'Unknown entries hide their identity.',
        'Progress in a related mechanic reveals', 'locked entries. Hold to see the goal.',
        'Only unlocked entries enter choices.', 'Unlocks persist in this profile;',
        'their notices appear in the main menu.'}},
    contraband={title='CONTRABAND',text={
        'Contraband are special items', 'found only in the Black Market.', '',
        'Buying them grants unusual effects', 'that do not behave like normal', 'Jokers or consumables.', '',
        'Some are immediate, while others', 'can last for part of the run.', '',
        'Buying Contraband increases Heat.'}},
    contracts={title='CONTRACTS',text={
        'Contracts are optional challenges', 'that can appear during a run.', '',
        'You may accept or decline each contract.', '',
        'Complete its objective to receive', 'the listed reward.', '',
        'Normally only one Contract can be', 'active at a time.'}},
    extra={title='EXTRA JOKERS',text={
        'Additional Jokers added to the', 'normal game pools.', '',
        'They behave like standard Jokers,', 'but introduce new mechanics', 'and combinations.'}},
    upg={title='UPGRADED JOKERS',text={
        'UPG Jokers can evolve during a run', 'after meeting specific conditions.', '',
        'Evolution can change:', '- sprite', '- name', '- effect', '- stats', '',
        'Each UPG Joker has its own', 'evolution requirements.'}},
    risk={title='RISK JOKERS',text={
        'Very powerful Jokers with', 'a significant drawback or risk.', '',
        'They can provide major bonuses', 'in exchange for:', '- money', '- time', '- destruction risk', '- special conditions'}},
    fusion={title='FUSION JOKERS',text={
        'Certain Joker pairs can be fused', 'to create a new exclusive Joker.', '',
        'Recipes are initially hidden.', '',
        'A Fusion is discovered when', 'you perform it for the first time.'}},
    skins={title='CARD SKINS',text={
        'Card skins only change', 'the visual appearance of playing cards.', '',
        'They do not affect rules,', 'probabilities or scoring.'}},
}
for _,data in pairs(categories) do data.close='Close' end
return categories
