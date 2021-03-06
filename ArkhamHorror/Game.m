//
//  Game.m
//  ArkhamHorror
//
//  Created by Michael Cornell on 3/2/15.
//  Copyright (c) 2015 Sleepy. All rights reserved.
//

#import "Game.h"
#import "Neighborhood.h"
#import "Movable.h"
#import "PathFinder.h"
#import "Monster.h"
#import "Macros.h"
#import "Skill.h"
#import "Item.h"
#import "AncientOne.h"
#import "SetupUtils.h"

@interface Game ()
@property (strong, nonatomic) PESGraph *pathFindingGraph;
@end

@implementation Game

static Game *singletonInstance = nil;
+(instancetype)initializeWithSettings:(NSDictionary *)gameSetupDict {
    static dispatch_once_t singletonOnceToken;
    dispatch_once(&singletonOnceToken, ^{
        singletonInstance = [[Game alloc] initWithSettings:gameSetupDict];
    });
    return singletonInstance;
}

+(instancetype)currentGame {
    if (singletonInstance){
        return singletonInstance;
    }
    else {
        logError(@"Game is un-initialized!");
    }
    return nil;
}

#pragma mark - UI API comm

-(void)runPhase {
    switch (self.currentPhase) {
        case GamePhaseSetupAncientOne: {
            [self pickAncientOne];
            break;
        }
        case GamePhaseSetupInvestigators: {
            [self pickInvestigator];
            break;
        }
        case GamePhaseUpkeepRefresh: {
            [self upkeepRefresh];
            break;
        }
        case GamePhaseUpkeepAction: {
            [self upkeepAction];
            break;
        }
        case GamePhaseUpkeepFocus: {
            [self upkeepFocus];
            break;
        }
        case GamePhaseMovementArkham: {
            [self movementArkham];
            break;
        }
        case GamePhaseMovementOtherWorld: {
            [self movementOtherWorld];
            break;
        }
        case GamePhaseMovementDelayed: {
            [self movementDelayed];
            break;
        }
        case GamePhaseEncounterArkhamGate: {
            [self encounterArkhamGate];
            break;
        }
        case GamePhaseEncounterArkhamNoGate: {
            [self encounterArkhamNoGate];
            break;
        }
        case GamePhaseEncounterOtherWorld: {
            [self encounterOtherWorld];
            break;
        }
        case GamePhaseMythosGatesSpawn: {
            [self mythosGatesSpawn];
            break;
        }
        case GamePhaseMythosPlaceClues: {
            [self mythosPlaceClues];
            break;
        }
        case GamePhaseMythosMoveMonsters: {
            [self mythosMoveMonsters];
            break;
        }
        case GamePhaseMythosEffect: {
            [self mythosEffect];
            break;
        }
        case GamePhaseTurnOver: {
            [self turnOver];
            break;
        }
        case GamePhaseNone: {
            logError(@"GamePhaseNone triggered");
            // investigate failure condition
            self.gameOver = YES;
            break;
        }
        default:
            logError(@"Found unknown game state");
            self.exitCode = ExitCodeUnknownGamePhase;
            self.gameOver = YES;
            break;
    }
}

#pragma mark - init

-(instancetype)initWithSettings:(NSDictionary*)settings {
    self = [super init];
    if (self){
        self.exitCode = ExitCodeNormal;
        self.currentPhase = GamePhaseSetupAncientOne;
        self.gameOver = NO;
        
        [self setupBoard:settings];
        [self setupDecks:settings];
        [self setupMonsters:settings];
        
        self.outskirts = [NSMutableArray new];
        
        self.gateSealCost = 5;
        self.gateDifficultyModifier = 0;
        
        self.investigators = [NSMutableArray new];
        
        self.maxMonstersInOutskirts = 8 - self.investigators.count;
        self.maxMonstersInArkham = self.investigators.count + 3;
        
        self.maxGatesOpen = 9 - floor(self.investigators.count/2); // if this many gates open at the same time, ancient one awakens
    }
    return self;
}

#pragma mark - logging

-(void)logGameInfo {
    NSLog(@"ARKHAM HORROR");
    NSLog(@"Ancient One:");
    NSLog(@"---> %@",self.ancientOne.name);
    NSLog(@"Investigators:");
    for (Investigator *player in self.investigators){
        NSLog(@"---> %@",player.name);
    }
}

#pragma mark - setup

-(void)setupBoard:(NSDictionary*)settings {
    NSArray *neighborhoodJSONArr = settings[@"Neighborhoods"];
    NSMutableArray *hoodsAccumulator = [NSMutableArray new];
    for (NSDictionary *hoodJSON in neighborhoodJSONArr){
        Neighborhood *hood = [Neighborhood generate:hoodJSON];
        [hoodsAccumulator addObject:hood];
    }
    self.neighborhoods = [NSArray arrayWithArray:hoodsAccumulator];
    
    // wire up neighborhoods
    self.pathFindingGraph = [PathFinder setupBoardGraph:self.neighborhoods];
    
    for (Neighborhood *hood in self.neighborhoods){
        for (Location *loc in hood.locations){
            if (!loc.isStable){
                [self placeClue:loc];
            }
        }
    }
}

-(void)setupDecks:(NSDictionary*)settings {
    
    
    [self setupItems:settings];
    self.uniquesDeck = [NSMutableArray new];
    self.spellsDeck = [NSMutableArray new];
    self.alliesDeck = [NSMutableArray new];
    self.mythosDeck = [NSMutableArray new];
    [self setupSkillsDeck:settings];
    [self setupAlliesDeck:settings];
}

-(void)setupItems:(NSDictionary*)settings {
    self.commonsDeck = [NSMutableArray new];
    NSDictionary *itemsDict = settings[@"Items"];
    NSArray *commonsArr = itemsDict[@"Commons"];
    for (NSDictionary *itemSetupDict in commonsArr){
        NSUInteger count = [itemSetupDict[@"count"] unsignedIntegerValue];
        NSDictionary *itemProperties = itemSetupDict[@"setup_dict"];
        for (int idx = 0; idx < count; idx++) {
            Item *item = [Item generate:itemProperties];
            [self.commonsDeck addObject:item];
        }
    }
}

-(void)setupSkillsDeck:(NSDictionary*)settings {
    self.skillsDeck = [NSMutableArray new];
    NSArray *skillsArr = settings[@"Skills"];
    for (NSDictionary *skillSetupDict in skillsArr){
        NSUInteger count = [skillSetupDict[@"count"] unsignedIntegerValue];
        NSDictionary *skillProperties = skillSetupDict[@"setup_dict"];
        for (int idx = 0; idx < count; idx++) {
            Skill *skill = [Skill generate:skillProperties];
            [self.skillsDeck addObject:skill];
        }
    }
}

-(void)setupAlliesDeck:(NSDictionary*)settings {
    self.alliesDeck = [NSMutableArray new];
    NSArray *alliesArr = settings[@"Allies"];
    for (NSDictionary *allyDict in alliesArr){
        Ally *ally = [Ally generate:allyDict];
        [self.alliesDeck addObject:ally];
    }
}

-(void)setupMonsters:(NSDictionary*)settings {
    self.monsterCup = [NSMutableArray new];
    for (NSDictionary *monsterJSON in settings[@"Monsters"]){
        NSUInteger count = [monsterJSON[@"count"] unsignedIntegerValue];
        for (int idx = 0; idx < count; idx++){
            Monster *monster = [Monster generate:monsterJSON[@"setup_dict"]];
            [self.monsterCup addObject:monster];
        }
    }
}

#pragma mark - player interactive setup

-(void)pickAncientOne {
    // pop dialog listing available ancient ones
    // palyer picks ancient one
    [self.uiDelegate enqueue(ancientOneSetup:^(NSString *selected) {
        if ([selected isEqualToString:@"Azathoth"]){
            self.ancientOne = [[AncientOneAzathoth alloc] init];
        }
        [self.ancientOne applySetupEffect:self];
        [self advanceGamePhase];
    })];
}

-(void)pickInvestigator {
    // pop dialog listing availible investigators
    // player picks investgator
    [self.uiDelegate enqueue(playerSetupEvent:^(NSString *selected, BOOL done) {
        if ([selected isEqualToString:@"Mike"]){
            [self setupPlayer:[Investigator testingInvestigator]];
        }
        
        if (done){
            [self advanceGamePhase];
        }
    })];
}

-(void)setupPlayer:(Investigator*)investigator {
    
    for (NSString *itemName in investigator.startingItems){
        // add to respective array
        NSLog(@"search for itemID %@",itemName);
        Card *card = [self.commonsDeck cardNamed:itemName];
        if (card) {
            [investigator.commonItems addObject:card];
        }
        else {
            card = [self.uniquesDeck cardNamed:itemName];
        }
        if (card) {
            [investigator.uniqueItems addObject:card];
        }
        else {
            card = [self.spellsDeck cardNamed:itemName];
        }
        if (card) {
            [investigator.spells addObject:card];
        }
        else {
            card = [self.skillsDeck cardNamed:itemName];
        }
        if (card) {
            [investigator.skills addObject:card];
        }
        else {
            card = [self.alliesDeck cardNamed:itemName];
        }
        if (card) {
            [investigator.allies addObject:card];
        }
        else {
            NSLog(@"Starting item: %@ coudln't be found.",itemName);
            
        }
    }
    // draw this many cards from the decks
    NSUInteger randomCommons = investigator.startingRandomCommons;
    NSUInteger randomUniques = investigator.startingRandomUniques;
    NSUInteger randomSpells = investigator.startingRandomSpells;
    NSUInteger randomSkills = investigator.startingRandomSkills;
    
    [self investigator:investigator selectCards:randomCommons fromCards:[self.commonsDeck draw:randomCommons]];
    [self investigator:investigator selectCards:randomUniques fromCards:[self.uniquesDeck draw:randomUniques]];
    [self investigator:investigator selectCards:randomSpells fromCards:[self.spellsDeck draw:randomSpells]];
    [self investigator:investigator selectCards:randomSkills fromCards:[self.skillsDeck draw:randomSkills]];
    
    [self.investigators addObject:investigator];
}

#pragma mark - game phases

-(void)advanceGamePhase {
    self.currentPhase++;
    if (self.currentPhase > GamePhaseTurnOver){
        self.currentPhase = GamePhaseUpkeepRefresh;
    }
}

-(void)advanceCurrentPlayer {
    self.currentPlayerIndex++;
    if (self.currentPlayerIndex == self.investigators.count){
        self.currentPlayerIndex = 0;
    }
}

-(void)upkeepRefresh { // all investigators items, spells, etc refresh
    NSLog(@"phase: upkeep refresh");
    
    for (Investigator *investigator in self.investigators){
        for (Item *item in investigator.commonItems){
            item.exhausted = NO;
        }
        for (Item *item in investigator.uniqueItems){
            item.exhausted = NO;
        }
        for (Item *item in investigator.spells){
            item.exhausted = NO;
        }
    }
    [self advanceGamePhase];
}

// player must roll for blessings/curses/retainers, pay bank loans, and deal with any card effects which occur during upkeep.
// investigator abilities that affect upkeep occur now
// players may complete these in any order (IE completing a retainer roll to gain it's profit before paying off a bank loan)
// bank loans, retainers, blessings, and curses are not rolled for during the first upkeep after they are gained, you still get the effect
-(void)upkeepAction {
    NSLog(@"phase: upkeep action");
    
    Investigator *currentPlayer = self.investigators[self.currentPlayerIndex];
    
    // TODO - a player may resolve these events in any order
    
    // BLESSED
    if (currentPlayer.blessed){
        if (currentPlayer.blessedSkipRolling){
            currentPlayer.blessedSkipRolling = NO;
        }
        else {
            [self.uiDelegate push(dieRoll:6 callback:^(NSUInteger roll) {
                if (roll == 1){ // lost blessing
                    currentPlayer.blessed = NO;
                }
            })];
        }
    }
    
    // CURSES
    if (currentPlayer.cursed){
        if (currentPlayer.cursedSkipRolling){
            currentPlayer.cursedSkipRolling = NO;
        }
        else {
            [self.uiDelegate push(dieRoll:6 callback:^(NSUInteger roll) {
                if (roll == 1){ // lost curse
                    currentPlayer.cursed = NO;
                }
            })];
        }
    }
    
    // BANK LOAN
    if (currentPlayer.hasBankLoan){
        if (currentPlayer.bankLoanSkipRolling){
            currentPlayer.bankLoanSkipRolling = NO;
        }
        else {
            // offer chance to pay $10 to remove bank loan
            [self.uiDelegate push(dieRoll:6 callback:^(NSUInteger roll) {
                if (roll < 4){
                    // pay $1 or discard all items + can no longer get bank loan
                }
            })];
        }
    }
    
    // RETAINERS
    if (currentPlayer.retainers > 0){
        // gain $2
        for (int idx = 0; idx < currentPlayer.retainers-currentPlayer.retainersSkipRolling; idx++){
            [self.uiDelegate push(dieRoll:6 callback:^(NSUInteger roll) {
                if (roll == 1){ // lose the retainer
                    if (currentPlayer.retainers > 0){
                        currentPlayer.retainers--;
                    }
                }
            })];
        }
    }
    
    // ITEMS
    // items with upkeep functions happen now
    
    // if all actions resolved then
    [self advanceCurrentPlayer];
    
    if (self.currentPlayerIndex == self.firstPlayerIndex){
        // everyone has gone
        [self advanceGamePhase];
    }
}

// players adjust skills based on focus
-(void)upkeepFocus {
    NSLog(@"phase: upkeep focus");
    [self.uiDelegate priority:YES focusEvent:^{
        NSLog(@"Did Focus!");
        [self advanceGamePhase];
    }];
}
-(void)movementArkham {
    NSLog(@"phase: move arkham");
    
    [self advanceGamePhase];
}
-(void)movementOtherWorld {
    NSLog(@"phase: move other world");
    
    [self advanceGamePhase];
}
-(void)movementDelayed {
    NSLog(@"phase: move delayed");
    
    [self advanceGamePhase];
}
-(void)encounterArkhamNoGate {
    NSLog(@"phase: arkham no gate");
    
    [self advanceGamePhase];
}
-(void)encounterArkhamGate {
    NSLog(@"phase: arkham gate");
    
    [self advanceGamePhase];
}
-(void)encounterOtherWorld {
    NSLog(@"phase: encounter other world");
    
    [self advanceGamePhase];
}
-(void)mythosGatesSpawn {
    NSLog(@"phase: gates spawn");
    
    [self advanceGamePhase];
}
-(void)mythosPlaceClues {
    NSLog(@"phase: mythos place clues");
    
    [self advanceGamePhase];
}
-(void)mythosMoveMonsters {
    NSLog(@"phase: mythos move monsters");
    
    [self advanceGamePhase];
}
-(void)mythosEffect {
    NSLog(@"phase: mythos effect");
    
    [self advanceGamePhase];
}

-(void)turnOver {
    NSLog(@"phase: turn over");
    self.firstPlayerIndex++;
    if (self.firstPlayerIndex == self.investigators.count){
        self.firstPlayerIndex = 0;
    }
    [self advanceGamePhase];
}

#pragma mark - actions

-(void)spendClueTokenOnSkillCheck {
    
    // you may spend clue tokens on a 1 to 1 basis to get an extra die before or after a skill check
    // it does not change the check modifier, it only adds a die, so even a player who would normally auto-fail a check by having < 1 dice may attempt it
    // They may spend clue tokens before rolling any dice, after rolling some dice, or all dice
}

-(void)incrementTerror {
    self.terrorLevel++;
    // remove random ally from deck
    
    Ally *ally = (Ally*)[self.alliesDeck drawOne];
    [self.removedFromGameDeck addObject:ally];
    
    if (self.terrorLevel == 3){ // close gen store
        [(GeneralStoreLocation*)[self locationNamed:@"General Store"] setIsClosed:YES];
    }
    if (self.terrorLevel == 6){ // close unique store
        [(GeneralStoreLocation*)[self locationNamed:@"Curiositie Shoppe"] setIsClosed:YES];
        // buff maniac monsters, combat rating = -2, combat damage = 3, is Endless
    }
    if (self.terrorLevel == 9){ // close spell store
        [(GeneralStoreLocation*)[self locationNamed:@"Ye Olde Magick Shoppe"] setIsClosed:YES];
    }
    if (self.terrorLevel == 10){ // overrun!
        self.arkhamIsOverrun = YES;
        [self.monsterCup addObjectsFromArray:self.outskirts];
        [self.outskirts removeAllObjects];
        self.ancientOne.doomCounter++;
    }
}

-(void)addMonsterToOutskirts:(Monster*)monster {
    if (!self.arkhamIsOverrun){
        [self.outskirts addObject:monster];
        if (self.outskirts.count == self.maxMonstersInOutskirts){
            [self.monsterCup addObjectsFromArray:self.outskirts];
            [self.outskirts removeAllObjects];
            [self incrementTerror];
        }
    }
    else {
        // arkham is overrun, you shouldn't be adding mosnters to outskirts
    }
}

#pragma mark - Game Utils
#pragma mark - lookups

-(Item*)spellNamed:(NSString*)spellName {
    for (Item *spell in self.spellsDeck){
        if ([spell.name isEqualToString:spellName]){
            return spell;
        }
    }
    return nil;
}

-(Ally*)allyNamed:(NSString*)allyName {
    for (Ally *ally in self.alliesDeck){
        if ([ally.name isEqualToString:allyName]){
            return ally;
        }
    }
    return nil;
}

-(Skill*)skillNamed:(NSString*)skillName {
    for (Skill *skill in self.skillsDeck){
        if ([skill.name isEqualToString:skillName]){
            return skill;
        }
    }
    return nil;
}

-(Item*)uniqueItemNamed:(NSString*)itemName {
    for (Item *item in self.uniquesDeck){
        if ([item.name isEqualToString:itemName]){
            return item;
        }
    }
    return nil;
}

-(Item*)commonItemNamed:(NSString*)itemName {
    for (Item *item in self.commonsDeck){
        if ([item.name isEqualToString:itemName]){
            return item;
        }
    }
    return nil;
}

-(Monster*)monsterNamed:(NSString*)monsterName {
    for (Monster *monster in self.monsterCup){
        if ([monster.name isEqualToString:monsterName]){
            return monster;
        }
    }
    return nil;
}

-(Neighborhood*)neighborhoodNamed:(NSString*)neighborhoodName {
    for (Neighborhood *hood in self.neighborhoods){
        if ([hood.name isEqualToString:neighborhoodName]){
            return hood;
        }
    }
    return nil;
}

-(Location*)locationNamed:(NSString*)name {
    for (Neighborhood *hood in self.neighborhoods){
        if ([hood.name isEqualToString:name]){
            return hood.street;
        }
        for (Location *loc in hood.locations){
            if ([loc.name isEqualToString:name]){
                return loc;
            }
        }
    }
    return nil;
}

-(Neighborhood*)neighborhoodOfLocation:(Location*)location {
    for (Neighborhood *hood in self.neighborhoods){
        if ([hood.locations containsObject:location]){
            return hood;
        }
    }
    return nil;
}

#pragma mark - Movement

-(NSArray*)routeFrom:(Location*)a to:(Location*)b {
    return [PathFinder graph:self.pathFindingGraph routeFrom:a to:b];
}

-(void)movable:(Movable*)movable followPath:(NSArray*)path {
    for (Location *loc in path){
        movable.currentLocation = loc;
        NSLog(@"current pos %@",loc);
        // TODO enqueue animation
    }
}

#pragma mark Investigator Actions

-(void)knockOutInvestigator:(Investigator*)investigator {
    // discard floor(1/2) items, spells count
    // discard floor(1/2) clue tokens
    // discard all retainers
    // stamina = 1
    // location = Hospital
}

-(void)driveInvestigatorInsane:(Investigator*)investigator {
    // discard floor(1/2) items, spells count
    // discard floor(1/2) clue tokens
    // discard all retainers
    // sanity = 1
    // location = Asylum
    
}

-(void)investigator:(Investigator*)investigator selectCards:(NSInteger)selectCount fromCards:(NSArray*)cards {
    if (selectCount > cards.count){
        NSLog(@"You can't keep more cards than you draw! dummy");
        return;
    }
    if (selectCount == cards.count){
        // player takes all cards by default
        [investigator.commonItems addObjectsFromArray:cards];
    }
    else {
        [self.uiDelegate enqueue(selectionEvent:cards select:selectCount callback:^(NSArray *selected, NSArray *rejected) {
            [investigator.commonItems addObjectsFromArray:selected];
            for (Card *card in rejected){
                [self.commonsDeck discard:card];
            }
        })];
    }
}

-(void)investigator:(Investigator*)investigator getMoney:(NSInteger)amount {
    investigator.money += amount;
}

// if unstated, difficulty is presumed to be 1
-(void)investigator:(Investigator*)investigator rollSkillCheck:(SkillCheckType)skillType checkModifier:(NSInteger)modifier difficulty:(NSInteger)difficulty {
    NSInteger baseModifier = 0;
    switch (skillType) {
        case SkillCheckTypeSpeed: {
            baseModifier = investigator.speed;
            break;
        }
        case SkillCheckTypeSneak:
        case SkillCheckTypeEvade: {
            baseModifier = investigator.sneak;
            break;
        }
        case SkillCheckTypeFight:
        case SkillCheckTypeCombat: {
            baseModifier = investigator.fight;
            break;
        }
        case SkillCheckTypeWill:
        case SkillCheckTypeHorror: {
            baseModifier = investigator.will;
            break;
        }
        case SkillCheckTypeLore:
        case SkillCheckTypeSpell: {
            baseModifier = investigator.lore;
            break;
        }
        case SkillCheckTypeLuck: {
            baseModifier = investigator.luck;
            break;
        }
        default: {
            logError(@"Tried to roll unknown skill check type");
            break;
        }
    }
    NSInteger dieToRoll = baseModifier + modifier;
    if (dieToRoll <= 0){
        // auto fail
    }
    else {
        // roll that many die
        // if # successes >= difficulty, passed
    }
}

-(void)arrestInvestigator:(Investigator*)investigator {
    investigator.currentLocation = [self locationNamed:@"Police Station"];
    investigator.isDelayed = YES;
    investigator.money = floor(investigator.money/2);
}

-(void)giveBankLoanToInvestigator:(Investigator*)investigator {
    if (!investigator.hasBankLoan && !investigator.failedBankLoan){
        investigator.hasBankLoan = YES;
        [self investigator:investigator getMoney:10];
    }
}

-(void)investigator:(Investigator*)investigator moveFromLocation:(Location*)startLocation toLocation:(Location*)destLocation{
    if (startLocation.monstersHere.count > 0){
        // attempt evade all monsters
        for (Monster *monster in startLocation.monstersHere){
            [self investigator:investigator evadeMonster:monster];
        }
        // you must evade all of them before leaving
        // if you fail evade against a monster, take combat damage, their movement is over, enter combat with monster
    }
    else {
        // just move to new location
        [self.uiDelegate push(move:investigator from:startLocation to:destLocation callback:^{
            NSLog(@"did move!");
        })];
    }
}

-(void)investigator:(Investigator*)investigator evadeMonster:(Monster*)monster {
    [self investigator:investigator rollSkillCheck:SkillCheckTypeEvade checkModifier:monster.awareness difficulty:1];

}

#pragma mark - monster actions

-(void)attackInvestigator:(Investigator*)player withMonster:(Monster*)monster {
    
}

#pragma mark - mythos actions 

-(void)drawMythos {
    Mythos *newMythos = (Mythos*)[self.mythosDeck drawOne];
    if (newMythos.mythosType == MythosTypeStoryContinues){
        // discard this mythos, shuffle mythos deck, redraw mythos
        [self.mythosDeck discard:newMythos];
        [self.mythosDeck shuffle];
        [self drawMythos];
        return;
    }
    else if (newMythos.mythosType == MythosTypeEnvironmentMystic ||
             newMythos.mythosType == MythosTypeEnvironmentUrban ||
             newMythos.mythosType == MythosTypeEnvironmentWeather) {
        // dispose of old environment mythos and unset it's effects,
        // apply new effect
        if (self.currentMythosEnvironment != nil){
            [self.currentMythosEnvironment removeEnvironmentEffect:self];
            [self.mythosDeck discard:self.currentMythosEnvironment];
        }
        self.currentMythosEnvironment = (EnvironmentMythos*)newMythos;
        [self.currentMythosEnvironment applyEnvironmentEffect:self];
        
    }
    else if (newMythos.mythosType == MythosTypeHeadline) {
        // apply it's one-off effect
        [(HeadlineMythos*)newMythos applyHeadlineEffect:self];
        
    }
    else if (newMythos.mythosType == MythosTypeRumor) {
        if (self.currentMythosRumor == nil){
            self.currentMythosRumor = (RumorMythos*)newMythos;
            [self.currentMythosRumor applyRumorEffect:self];
            // apply the mythos, apply the ongoing effect
        }
    }
    else if (newMythos.mythosType == MythosTypeStoryContinues){
        // discard this mythos, shuffle mythos deck, redraw mythos
    }
    
    self.currentMythosWhiteDimensions = newMythos.whiteDimensions;
    self.currentMythosBlackDimensions = newMythos.blackDimensions;
    
    Location *gateLoc = [self locationNamed:newMythos.gateLocation];
    Location *clueLoc = [self locationNamed:newMythos.clueLocation];
    
    [self openGate:gateLoc];
    
    // if no gate at clueLoc, if no investigators there
    [self placeClue:clueLoc];
    // else if 1 investigator there, they immediately pick it up
    // else first player decides who gets clue
}

-(void)openGate:(Location*)gateLocation {
    
}

-(void)placeClue:(Location*)clueLocation {
    clueLocation.cluesHere++;
}

@end
