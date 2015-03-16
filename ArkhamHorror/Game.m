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
#import "ItemSetup.h"
#import "Monster.h"

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
        NSLog(@"Game is un-initialized!");
    }
    return nil;
}

#pragma mark - UI API comm

-(void)runPhase {
    [self.uiDelegate enqueueDieRollEvent:^(NSUInteger roll) {
        NSLog(@"op 1 callback");
    }];
    [self.uiDelegate enqueueDieRollEvent:^(NSUInteger roll) {
        NSLog(@"op 2 callback");
    }];
}

#pragma mark - init

-(instancetype)initWithSettings:(NSDictionary*)settings {
    self = [super init];
    if (self){
        
        [self setupDecks];
        [self setupMonsterCup];
        self.outskirts = [NSMutableArray new];
        
        self.gateSealCost = 5;
        self.gateDifficultyModifier = 0;
        
        self.investigators = [NSMutableArray new];
        
        NSArray *investigators = settings[@"Investigators"];
        if (investigators){ // load from plist
            Investigator *player = [[Investigator alloc] initWithProperties:investigators[0]];
            [self setupPlayer:player];
        }
        else {
            [self setupPlayer:[Investigator testingInvestigator]];
        }
        
        self.maxMonstersInOutskirts = 8 - self.investigators.count;
        self.maxMonstersInArkham = self.investigators.count + 3;
        
        if (self.investigators.count < 3) { self.maxGatesOpen = 8; } // if this many gates open at the same time, ancient one awakens
        else if (self.investigators.count < 5) { self.maxGatesOpen = 7; }
        else if (self.investigators.count < 7) { self.maxGatesOpen = 6; }
        else  {self.maxGatesOpen = 5;}
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

-(void)setupDecks {
    self.commonsDeck = [ItemSetup arkhamHorrorCommons];
    self.uniquesDeck = [NSMutableArray new];
    self.spellsDeck = [NSMutableArray new];
    self.skillsDeck = [NSMutableArray new];
    self.alliesDeck = [NSMutableArray new];
    self.mythosDeck = [NSMutableArray new];
}

-(void)setupBoard {
    self.neighborhoods = [Neighborhood arkhamBoard];
    // wire up neighborhoods
    for (Neighborhood *hoodA in self.neighborhoods){
        for (Neighborhood *hoodB in self.neighborhoods){
            if (hoodA != hoodB){
                if ([hoodA.whiteStreetConnectionName isEqualToString:hoodB.name]){
                    hoodA.whiteStreetConnection = hoodB;
                }
                if ([hoodA.colorlessStreetConnectionName isEqualToString:hoodB.name]){
                    hoodA.colorlessStreetConnection = hoodB;
                }
            }
        }
    }
    self.pathFindingGraph = [PathFinder setupBoardGraph:self.neighborhoods];

}

-(void)setupMonsterCup {
    self.monsterCup = [NSMutableArray new];
    // TODO load cup with monsters
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
    
    [self draw:randomCommons player:investigator keep:randomCommons deck:self.commonsDeck];
    [self draw:randomUniques player:investigator keep:randomUniques deck:self.uniquesDeck];
    [self draw:randomSpells player:investigator keep:randomSpells deck:self.spellsDeck];
    [self draw:randomSkills player:investigator keep:randomSkills deck:self.skillsDeck];
    
    [self.investigators addObject:investigator];
}

#pragma mark - actions

-(void)arrestInvestigator:(Investigator*)investigator {
    investigator.currentLocation = [self locationNamed:@"Police Station"];
    investigator.isDelayed = YES;
    investigator.money = floor(investigator.money/2);
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

-(NSArray*)routeFrom:(Location*)a to:(Location*)b {
    return [PathFinder graph:self.pathFindingGraph routeFrom:a to:b];
}

-(Location*)locationNamed:(NSString*)name {
    for (Neighborhood *hood in self.neighborhoods){
        if ([hood.street.name isEqualToString:name]){
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

-(void)movable:(Movable*)movable followPath:(NSArray*)path {
    for (Location *loc in path){
        movable.currentLocation = loc;
        NSLog(@"current pos %@",loc);
        // TODO enqueue animation
    }
}

-(void)adjustSkills:(Investigator*)player unlimited:(BOOL)unlimited{
    int adjustsLeft = (int)player.focus;
    adjustsLeft = 0;
    
}


-(void)draw:(NSInteger)drawCount player:(Investigator*)player keep:(NSInteger)keepCount deck:(NSMutableArray*)deck{
    if (keepCount > drawCount){
        NSLog(@"You can't keep more cards than you draw! dummy");
        return;
    }
    
    NSMutableArray *drawnCards = [NSMutableArray new];
    for (int idx = 0; idx < drawCount; idx++){
        [drawnCards addObject:[deck drawOne]];
    }
    
    if (drawnCards.count > keepCount){ // you can only keep some of them
        [self.uiDelegate enqueueSelectionEvent:drawnCards select:keepCount callback:^(NSArray *selected, NSArray *rejected) {
            [player.commonItems addObjectsFromArray:selected];
            for (Card *card in rejected){
                [self.commonsDeck discard:card];
            }
        }];
    }
    else {
        [player.commonItems addObjectsFromArray:drawnCards];
    }    
}

@end
