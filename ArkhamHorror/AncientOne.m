//
//  AncientOne.m
//  ArkhamHorror
//
//  Created by Michael Cornell on 2/23/15.
//  Copyright (c) 2015 Sleepy. All rights reserved.
//

#import "AncientOne.h"
#import "Monster.h"
#import "Game.h"
#import "SetupUtils.h"

#pragma mark - Prototype

@implementation AncientOne
-(instancetype)init {
    self = [super init];
    if (self){
        self.name = @"Prototype Ancient One";
        self.combatRating = 0;
        self.maxDoom = 15;
        self.doomCounter = 0;
        self.attackDifficultyModifier = 1;
        self.physicalResistance = MonsterDamageImmunityNone;
        self.magicalResistance = MonsterDamageImmunityNone;
    }
    return self;
}
-(void)applySetupEffect:(Game*)game{
    //pass
}
-(void)buffWorshippers:(Game*)game{
    //pass
}
-(void)awaken:(Game*)game{
    //pass
}
-(void)attack:(Game*)game{
    //pass
}

@end

#pragma mark - Azathoth

@implementation AncientOneAzathoth
-(instancetype)init {
    self = [super init];
    if (self){
        self.name = @"Azathoth";
        self.combatRating = 0;
        self.maxDoom = 14;
        self.doomCounter = 0;
    }
    return self;
}

-(void)buffWorshippers:(Game*)game {
    for (Monster *monster in [Game currentGame].monsterCup){
        if ([monster.name isEqualToString:@"Maniac"]){
            monster.toughness+=1;
        }
    }
}
-(void)awaken:(Game*)game {
    // lose game
}

@end

#pragma mark - Cthulhu

@implementation AncientOneCthulhu
-(instancetype)init {
    self = [super init];
    if (self){
        self.name = @"Cthulhu";
        self.combatRating = -6;
        self.maxDoom = 13;
        self.doomCounter = 0;
    }
    return self;
}
-(void)applySetupEffect:(Game*)game {
    // all players max SAN -1, max STA -1
    for (Investigator *investigator in [Game currentGame].investigators){
        investigator.maxSanity--;
        investigator.maxStamina--;
    }
}
-(void)buffWorshippers:(Game*)game {
    for (Monster *monster in [Game currentGame].monsterCup){
        if ([monster.name isEqualToString:@"Cultist"]){
            monster.horrorRating = -2;
            monster.horrorDamage = 2;
        }
    }
}

-(void)attack:(Game*)game {
    for (Investigator *player in [Game currentGame].investigators){
        // prompt, pick lose 1 max SAN or 1 max STA
        
        player.maxSanity--; // OR
        player.maxStamina--;
        
        if (player.sanity == 0 || player.stamina == 0){
            // devoured!
        }
    }
    
    // heal 1
    if (self.doomCounter < self.maxDoom){
        self.doomCounter++;
    }
}
@end

#pragma mark - Hastur

@implementation AncientOneHastur
-(instancetype)init {
    self = [super init];
    if (self){
        self.name = @"Hastur";
        self.combatRating = 0;// on awaken == game's terror level
        self.maxDoom = 13;
        self.doomCounter = 0;
        self.physicalResistance = MonsterDamageImmunityResist;
    }
    return self;
}
-(void)applySetupEffect:(Game*)game {
    [Game currentGame].gateSealCost = 8;
}
-(void)awaken:(Game*)game {
    self.combatRating = [Game currentGame].terrorLevel * -1;
}
-(void)buffWorshippers:(Game*)game {
    for (Monster *monster in [Game currentGame].monsterCup){
        if ([monster.name isEqualToString:@"Cultist"]){
            monster.movementType = MonsterMovementTypeFlying;
            monster.combatRating = -2;
        }
    }
}
-(void)attack:(Game*)game{
    for (Investigator *player in [Game currentGame].investigators){
        // prompt luck check of self.attackDifficultyModifer
        // on fail, lose 2 SAN
        player.sanity-=2;
        if (player.sanity <= 0){
            // devoured!
        }
    }
    self.attackDifficultyModifier--;
}
@end

#pragma mark - Ithaqua

@implementation AncientOneIthaqua
-(instancetype)init {
    self = [super init];
    if (self){
        self.name = @"Ithaqua";
        self.combatRating = -3;
        self.maxDoom = 11;
        self.doomCounter = 0;
    }
    return self;
}
-(void)applySetupEffect:(Game*)game{
    [Game currentGame].ignoresWeatherMythos = YES;
    // tell game to inflict 1 sta of damage to every player in street at end of mythos phase
}
-(void)buffWorshippers:(Game*)game {
    for (Monster *monster in [Game currentGame].monsterCup){
        if ([monster.name isEqualToString:@"Cultist"]){
            monster.toughness+=2;
        }
    }
}
-(void)awaken:(Game*)game{
    // foreach player, foreach item, roll, if fail, discard item
    
}
-(void)attack:(Game*)game{
    for (Investigator *player in [Game currentGame].investigators){
        // prompt fight check of self.attackDifficultyModifer
        // on fail, lose 2 STA
        player.stamina-=2;
        if (player.stamina == 0){
            // devoured!
        }
    }
    self.attackDifficultyModifier--;
}
@end

#pragma mark - Nyarlathotep

@implementation AncientOneNyarlathotep

-(instancetype)init {
    self = [super init];
    if (self){
        self.name = @"Nyarlathotep";
        self.combatRating = -4;
        self.maxDoom = 11;
        self.doomCounter = 0;
        self.magicalResistance = MonsterDamageImmunityResist;

    }
    return self;
}

-(void)applySetupEffect:(Game*)game{
    // add the 5 mask mosnters    ;
    [[Game currentGame].monsterCup addObjectsFromArray:[SetupUtils arkhamHorrorMaskMonsters]];
}

-(void)attack:(Game*)game{
    for (Investigator *player in [Game currentGame].investigators){
        // prompt lore check of self.attackDifficultyModifer
        // on fail, lose 1 clue
        if (player.clues == 0){
            //devoured!
        }
    }
    self.attackDifficultyModifier--;
}
@end

#pragma mark - Shub Niggurath

@implementation AncientOneShubNiggurath

-(instancetype)init {
    self = [super init];
    if (self){
        self.name = @"Shub-Niggurath";
        self.combatRating = -5;
        self.maxDoom = 12;
        self.doomCounter = 0;
        self.physicalResistance = MonsterDamageImmunityImmune;
    }
    return self;
}

-(void)applySetupEffect:(Game*)game{
    for (Monster *monster in [Game currentGame].monsterCup){
        monster.toughness++;
    }
}

-(void)attack:(Game*)game{
    for (Investigator *player in [Game currentGame].investigators){
        // prompt sneak check of self.attackDifficultyModifer
        // on fail, lose 1 monsterTrophy
        if (player.monsterTrophies == 0){
            //devoured!
        }
    }
    self.attackDifficultyModifier--;
}
@end

#pragma mark - Yig

@implementation AncientOneYig

-(instancetype)init {
    self = [super init];
    if (self){
        self.name = @"Yig";
        self.combatRating = -3;
        self.maxDoom = 10;
        self.doomCounter = 0;
    }
    return self;
}

-(void)applySetupEffect:(Game*)game{
    // gain 1 doom token when investigator is lost in time and space
}

-(void)attack:(Game*)game{
    for (Investigator *player in [Game currentGame].investigators){
        // prompt speed check of self.attackDifficultyModifer
        // on fail lose 1 SAN + 1 STA
        player.sanity--;
        player.stamina--;
        if (player.sanity == 0 || player.stamina == 0){
            //devoured!
        }
    }
    self.attackDifficultyModifier--;
}
@end

#pragma mark - Yog Sothoth

@implementation AncientOneYogSothoth
-(instancetype)init {
    self = [super init];
    if (self){
        self.name = @"Yog-Sothoth";
        self.combatRating = -5;
        self.maxDoom = 12;
        self.doomCounter = 0;
        self.magicalResistance = MonsterDamageImmunityImmune;
    }
    return self;
}

-(void)applySetupEffect:(Game*)game{
    [Game currentGame].gateDifficultyModifier++;
    
    //TODO if player is lost in time+space they are instead devoured
}

-(void)attack:(Game*)game{
    for (Investigator *player in [Game currentGame].investigators){
        // prompt will check of self.attackDifficultyModifer
        // on fail, lose 1 gate trophy
        if (player.gateTrophies == 0){
            //devoured!
        }
    }
    self.attackDifficultyModifier--;
}
@end


