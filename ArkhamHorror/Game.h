//
//  Game.h
//  ArkhamHorror
//
//  Created by Michael Cornell on 3/2/15.
//  Copyright (c) 2015 Sleepy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSMutableArray+Deck.h"
#import "Investigator.h"
#import "Ally.h"
#import "ArkhamHorrorUIAPI.h"
#import "Macros.h"

#import "Mythos.h"
#import "HeadlineMythos.h"
#import "EnvironmentMythos.h"
#import "RumorMythos.h"

@class AncientOne;

@interface Game : NSObject

@property (nonatomic) GamePhase currentPhase;
@property (nonatomic) ExitCode exitCode;
@property (nonatomic) BOOL gameOver;

@property (strong, nonatomic) NSArray *neighborhoods;
@property (strong, nonatomic) AncientOne *ancientOne;

@property (strong, nonatomic) NSMutableArray *commonsDeck;
@property (strong, nonatomic) NSMutableArray *uniquesDeck;
@property (strong, nonatomic) NSMutableArray *spellsDeck;
@property (strong, nonatomic) NSMutableArray *skillsDeck;
@property (strong, nonatomic) NSMutableArray *alliesDeck;
@property (strong, nonatomic) NSMutableArray *mythosDeck;

@property (nonatomic) NSUInteger firstPlayerIndex; // index of First Player for round
@property (nonatomic) NSUInteger currentPlayerIndex; // index of player currently taking turn

@property (strong, nonatomic) NSMutableArray *investigators;
@property (strong, nonatomic) NSMutableArray *monsterCup;
@property (strong, nonatomic) NSMutableArray *outskirts;
@property (strong, nonatomic) NSMutableArray *sky;
@property (strong, nonatomic) NSMutableArray *lostInTimeAndSpace;

@property (strong, nonatomic) NSMutableArray *removedFromGameDeck; // expansion pack items may access 'removed from the game' items, so keep a ref
@property (nonatomic) BOOL ignoresWeatherMythos;

@property (nonatomic) NSInteger terrorLevel;
@property (nonatomic) NSInteger maxMonstersInArkham;
@property (nonatomic) NSInteger maxMonstersInOutskirts;

@property (nonatomic) NSInteger gateDifficultyModifier; //increases/decreases difficulty of closing/sealing gates
@property (nonatomic) NSInteger gateSealCost; // cost to seal a gate

@property (nonatomic) NSInteger maxGatesOpen;

@property (nonatomic) BOOL arkhamIsOverrun;

@property (strong,nonatomic) EnvironmentMythos *currentMythosEnvironment;
@property (strong,nonatomic) RumorMythos *currentMythosRumor;

@property (strong, nonatomic) NSArray *currentMythosWhiteDimensions;
@property (strong, nonatomic) NSArray *currentMythosBlackDimensions;

@property (weak, nonatomic) id<ArkhamHorrorUIAPI> uiDelegate;

+(instancetype)initializeWithSettings:(NSDictionary*)gameSetupDict;
+(instancetype)currentGame; // singleton for everyone to access, you must initialize with settings

-(Location*)locationNamed:(NSString*)name;
-(NSArray*)routeFrom:(Location*)a to:(Location*)b;
-(void)drawMythos;
-(void)logGameInfo;

-(void)runPhase; // execute a step in the game loop, called by uiDelegate once it's dispatched + resolved all of it's events

#pragma mark - Gmae Utils
-(Neighborhood*)neighborhoodOfLocation:(Location*)location;
// select ancient one
// setup decks
    // load decks
    // shuffle all
// setup board
// setup players
    // draw items
    // adjust skills

@end
