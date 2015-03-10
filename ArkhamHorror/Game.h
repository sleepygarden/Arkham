//
//  Game.h
//  ArkhamHorror
//
//  Created by Michael Cornell on 3/2/15.
//  Copyright (c) 2015 Sleepy. All rights reserved.
//

@class Game;

#import <Foundation/Foundation.h>
#import "NSMutableArray+Deck.h"
#import "Investigator.h"
#import "AncientOne.h"
#import "Ally.h"
#import "Mythos.h"

@interface Game : NSObject
@property (strong, nonatomic) NSArray *neighborhoods;
@property (strong, nonatomic) AncientOne *ancientOne;

@property (strong, nonatomic) NSMutableArray *commonsDeck;
@property (strong, nonatomic) NSMutableArray *uniquesDeck;
@property (strong, nonatomic) NSMutableArray *spellsDeck;
@property (strong, nonatomic) NSMutableArray *skillsDeck;
@property (strong, nonatomic) NSMutableArray *alliesDeck;
@property (strong, nonatomic) NSMutableArray *mythosDeck;

@property (strong, nonatomic) NSMutableArray *investigators;
@property (strong, nonatomic) NSMutableArray *monsterCup;
@property (strong, nonatomic) NSMutableArray *outskirts;
@property (strong, nonatomic) NSMutableArray *sky;
@property (strong, nonatomic) NSMutableArray *lostInTimeAndSpace;

@property (strong, nonatomic) NSMutableArray *removedFromGameDeck;

@property (nonatomic) BOOL ignoresWeatherMythos;

@property (nonatomic) NSInteger terrorLevel;
@property (nonatomic) NSInteger maxMonstersInArkham;
@property (nonatomic) NSInteger maxMonstersInOutskirts;

@property (nonatomic) NSInteger gateDifficultyModifier; //increases/decreases difficulty of closing/sealing gates
@property (nonatomic) NSInteger gateSealCost; // cost to seal a gate

@property (nonatomic) NSInteger maxGatesOpen;

@property (nonatomic) BOOL arkhamIsOverrun;

@property (strong,nonatomic) Mythos *currentMythosEnvironment;
@property (strong,nonatomic) Mythos *currentMythosRumor;
@property (strong,nonatomic) Mythos *currentMythosHeadline;

@property (strong, nonatomic) NSArray *currentMythosWhiteDimensions;
@property (strong, nonatomic) NSArray *currentMythosBlackDimensions;

+(instancetype)currentGame; // singleton for everyone to access
-(instancetype)initArkhamHorror;
-(Location*)locationNamed:(NSString*)name;
-(NSArray*)routeFrom:(Location*)a to:(Location*)b;

// select ancient one
// setup decks
    // load decks
    // shuffle all
// setup board
// setup players
    // draw items
    // adjust skills

@end
