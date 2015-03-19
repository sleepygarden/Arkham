//
//  GameLoop.h
//  ArkhamHorror
//
//  Created by Michael Cornell on 2/23/15.
//  Copyright (c) 2015 Sleepy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Defines.h"

@interface GameLoop : NSObject
@property (nonatomic) GamePhase currentPhase;
@property (strong, nonatomic) NSMutableArray *phaseEvents;
@end

/*
 
 //// SkillChecks
 
 willMakeSkillCheck
 shouldPassSkillCheck // skip skill check with auto success
 didMakeSkillCheck:(BOOL)passFail // all
 
 willMakeSpeedCheck
 shouldPassSpeedCheck
 didMakeSpeedCheck:(BOOL)passFail
 
 willMakeSneakCheck
 shouldPassSneakCheck
 didMakeSneakCheck:(BOOL)passFail
 
 willMakeEvadeCheck
 shouldPassEvadeCheck
 didMakeEvadeCheck:(BOOL)passFail // will make sneak check
 
 willMakeFightCheck
 shouldPassFightCheck
 didMakeFightCheck:(BOOL)passFail
 
 willMakeWillCheck
 shouldPassWillCheck
 didMakeWillCheck:(BOOL)passFail
 
 willMakeCombatCheck
 shouldPassCombatCheck
 didMakeCombatCheck:(BOOL)passFail // special fight check
 
 willMakeHorrorCheck
 shouldPassHorrorCheck
 didMakeHorrorCheck:(BOOL)passFail // special will check
 
 willMakeLoreCheck
 shouldPassLoreCheck
 didMakeLoreCheck:(BOOL)passFail
 
 willMakeLuckCheck
 shouldPassLuckCheck
 didMakeLuckCheck:(BOOL)passFail
 
 willMakeSpellCheck
 shouldPassSpellCheck
 didMakeSpellCheck:(BOOL)passFail // special lore check
 
 
 ///// Damage
 
 willLoseStamina:(int)amount
 (int)reduceStaminaLoss:(int)incomingDamage // skills which skip damage reduce it to zero
 didLoseStamina:(int)value
 
 willLoseSanity:(int)value
 (int)reduceSanityLoss
 didLoseSanity:(int)value
 
 
 //// Expenses
 
 willGainMoney
 didGainMoney
 
 willSpendMoney
 didSpendMoney:(int)value
 
 willGainClues
 didGainClues
 
 willSpendClues
 didSpendClues:(int)value
 
 willGainGateTrophies
 didGainGateTrophies
 
 willSpendGateTrophies
 didSpendGateTrophies
 
 willGainMonsterTrophies
 didGainMonsterTrophies
 
 willSpendMonsterTrophies
 didSpendMonsterTrophies
 
 willDrawCommonItem
 didDrawCommonItem
 
 willDrawUniqueItem
 didDrawUniqueItem
 
 willDrawSpell
 didDrawSpell
 
 willDrawSkill
 didDrawSkill
 
 willDrawAlly
 didDrawAlly
 
 
 //// Movement
 
 playerWillMove
 playerShouldMove
 playerDidMove
 
 willEnterOtherWorld
 didEnterOtherWorld
 
 willMoveThroughOtheWorld
 didMoveThroughOtherWorld
 
 
 willExitOtherWorld
 didExitOtherWorld
 
 willCloseGate
 didCloseGate
 
 willSealGate
 didSealGate
 
 willBeLostInTimeAndSpace
 didGetLostInTimeAndSpace
 
 ///// Monsters
 monsterWillAppear
 monsterDidAppear
 
 monsterWillMove
 monsterDidMove
 
 ancientOneWillAwaken
 ancientOneDidAwaken
 
 upkeepPhase
 
 willDrawArkhamEncounter
 didDrawArkhamEncounter
 
 willDrawOtherWorldEncounter
 didDrawOtherWorldEncounter
 
 
 
 */