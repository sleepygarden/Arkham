//
//  ArkhamHorrorCLI.m
//  ArkhamHorror
//
//  Created by Michael Cornell on 3/10/15.
//  Copyright (c) 2015 Sleepy. All rights reserved.
//

#import "ArkhamHorrorCLI.h"
#import "ArkhamHorrorUIAPI.h"
#import "Game.h"
#import "Die.h"
#import "SettingsManager.h"
#import "Neighborhood.h"
#import "Location.h"
#import "Monster.h"
#import "Item.h"
#import "Macros.h"

char const kEscapeChar = '\033';

typedef NS_ENUM(NSUInteger, ColorPrintingMode){
    CodeReset = 0,
    CodeBold =1,
    CodeDim =2,
    CodeUnderline = 3,
    CodeReverseColors = 7,
    
};

typedef NS_ENUM(NSUInteger, ColorPrintingForeground){
    
    CodeFGBlack = 30,
    CodeFGRed = 31,
    CodeFGGreen = 32,
    CodeFGYellow = 33,
    CodeFGBlue = 34,
    CodeFGMagenta  = 35,
    CodeFGCyan  = 36,
    CodeFGWhite =  37,
    
    CodeFGLightBlack = 90,
    CodeFGLightRed = 91,
    CodeFGLightGreen = 92,
    CodeFGLightYellow =  93,
    CodeFGLightBlue = 94,
    CodeFGLightMagenta = 95,
    CodeFGLightCyan = 96,
    CodeFGLightWhite = 97,
    
};

typedef NS_ENUM(NSUInteger, ColorPrintingBackground){
    CodeBGBlack = 40,
    CodeBGRed = 41,
    CodeBGGreen =  42,
    CodeBGYellow = 43,
    CodeBGBlue = 44,
    CodeBGMagenta = 45,
    CodeBGCyan = 46,
    CodeBGWhite = 47,
    
    CodeBGLightBlack = 100,
    CodeBGLightRed = 101,
    CodeBGLightGreen = 102,
    CodeBGLightYellow = 103,
    CodeBGLightBlue = 104,
    CodeBGLightMagenta = 105,
    CodeBGLightCyan = 106,
    CodeBGLightWhite = 107
};

@interface ArkhamHorrorCLI () <ArkhamHorrorUIAPI>
@property (weak, nonatomic) Game *currentGame;

@property (nonatomic) ColorPrintingForeground foreground;
@property (nonatomic) ColorPrintingBackground background;
@property (nonatomic) ColorPrintingMode printMode;
@property (nonatomic) BOOL printsColors;

@end

@implementation ArkhamHorrorCLI
@synthesize eventsQueue;

+(int)run {
    logDebug(@"Hello %@",self);
    ArkhamHorrorCLI *cli = [[ArkhamHorrorCLI alloc] init];
    cli.eventsQueue = [NSMutableArray new];
    Game *game = [Game initializeWithSettings:[SettingsManager arkhamHorrorDefaults]]; // init singleton
    game.uiDelegate = cli;
    cli.currentGame = game;
    cli.printMode = CodeReset;
    cli.foreground = CodeFGWhite;
    cli.background = CodeBGBlack;
    cli.printsColors = NO;
    
#ifndef DEBUG // xcode terminal doesn't print colors
    cli.printsColors = YES;
#endif
    
    while (!game.gameOver) {
        [game runPhase]; // game sends out event requests
        [cli processEventsQueue]; // game dispatches and resolves events
    }
    return game.exitCode;
}

#pragma mark - Console input

-(BOOL)getBool:(NSString*)prompt {
    NSString *rawBool = [[self getString:prompt] lowercaseString];
    return ([rawBool isEqualToString:@"yes"] || [rawBool isEqualToString:@"y"]);
}

-(int)getInt:(NSString*)prompt {
    NSString *rawInt = [self getString:prompt];
    return [rawInt intValue];
}

-(NSString*)getString:(NSString*)prompt {
    [self print:prompt];
    NSFileHandle *input = [NSFileHandle fileHandleWithStandardInput];
    NSData *inputData = [input availableData];
    NSString *inputString = [[NSString alloc] initWithData:inputData encoding:NSUTF8StringEncoding];
    inputString = [inputString stringByTrimmingCharactersInSet: [NSCharacterSet newlineCharacterSet]];
    return inputString;
}

#pragma mark - printing

-(void)printMap {
    NSString *mapString =
    @"o------------------------------------------------------------------------------------o\n"
    @"| ARKHAM                                              Terror: 1~2~3~4~5~6~6~7~8~9~10 |\n"
    @"o------------------------------------------------------------------------------------o\n"
    @"|                                                                                    |\n"
    @"|                    (Train Station)            (Bank)                               |\n"
    @"|                           |                     |                                  |\n"
    @"|             (Newspaper)   |                     |   (Asylum)                       |\n"
    @"|                        \\  |                     |  /                               |\n"
    @"|     (Curio Shop)-----(NORTHSIDE)---->>>>----(DOWNTOWN)-----(*Independence Square)  |\n"
    @"|                           |                  /  |                                  |\n"
    @"|                           |                 /   |                                  |\n"
    @"|                           ^     ___________/    V                                  |\n"
    @"|                           ^    /                V                                  |\n"
    @"|                 (*Isle)   |   /                 |   (*Roadhouse)                   |\n"
    @"|                        \\  |  /                  |  /                               |\n"
    @"|        (Docks)-----(MERCHANT DIST.)         (EASTTOWN)-----(Diner)                 |\n"
    @"|                        /  |  \\                  |  \\                               |\n"
    @"|            (*Unnamable)   |   \\                 |   (Police Station)               |\n"
    @"|                           |    \\___________     V                                  |\n"
    @"|                           |                \\    V                                  |\n"
    @"|                           |                 \\   |   (*Graveyard)                   |\n"
    @"|                           ^                  \\  |  /                               |\n"
    @"|                           ^               (RIVERTOWN)-----(*Black Cave)            |\n"
    @"|                           ^                     |  \\                               |\n"
    @"|                           |                     |   (General Store)                |\n"
    @"|                           |                     V                                  |\n"
    @"|                           |                     V                                  |\n"
    @"|  (*Sci. Building)         |                     |   (*Witch House)                 |\n"
    @"|                  \\        |                     |  /                               |\n"
    @"|   (Administration)--(MISKATONIC U.)-----------(FRENCH HILL)                        |\n"
    @"|                  /        |                     |  \\                               |\n"
    @"|         (Library)         |                     |   (*Lodge)                       |\n"
    @"|                           ^                     V                                  |\n"
    @"|                           ^                     V                                  |\n"
    @"|                           |                     |                                  |\n"
    @"|                           |                     |                                  |\n"
    @"|        (Hospital)-----(UPTOWN)-----<<<-----(SOUTHSIDE)-----(Boarding House)        |\n"
    @"|                        /  |                     |  \\                               |\n"
    @"|            (Magic Shop)   |                     |   (Church)                       |\n"
    @"|                           |                     |                                  |\n"
    @"|                       (*Woods)          (*Hist. Society)                           |\n"
    @"|                                                                                    |\n"
    @"o------------------------------------------------------------------------------------o\n";
    
    [self println:mapString];
}

-(void)printInvestigator:(Investigator*)investigator {
    [self printHBar:27];
    
    [self println:[self stringf:@"%@, %@",investigator.name, investigator.occupation] minWidth:27];
    [self println:[self stringf:@" SAN: %li/%li",investigator.sanity, investigator.maxSanity] minWidth:27];
    [self println:[self stringf:@" STA: %li/%li",investigator.stamina, investigator.maxStamina] minWidth:27];
    [self println:[self stringf:@" Cash: $%li",investigator.money] minWidth:27];
    [self println:[self stringf:@" Clues: %li",investigator.clues] minWidth:27];
    [self println:[self stringf:@" Gate Trophies: %li",investigator.gateTrophies] minWidth:27];
    [self println:@"" minWidth:27];
    
    
    [self println:[self stringf:@" Speed: %li",investigator.speed] minWidth:27];
    [self println:[self stringf:@"        %li :Sneak",investigator.sneak] minWidth:27];
    [self println:@"" minWidth:27];
    
    [self println:[self stringf:@" Fight: %li",investigator.fight] minWidth:27];
    [self println:[self stringf:@"        %li :Will",investigator.will] minWidth:27];
    [self println:@"" minWidth:27];
    
    [self println:[self stringf:@"  Lore: %li",investigator.lore] minWidth:27];
    [self println:[self stringf:@"        %li :Luck",investigator.luck] minWidth:27];
    [self println:@"" minWidth:27];
    
    
    if (investigator.monsterTrophies.count > 0){
        [self println:@"Monster Trophies:" minWidth:27];
        for (Monster *monster in investigator.monsterTrophies){
            [self println:[self stringf:@"%@, %li",monster.name,monster.toughness] minWidth:27];
        }
        [self println:@"" minWidth:27];
    }
    else {
        [self println:@"No Monster Trophies" minWidth:27];
    }
    
    if (investigator.commonItems.count > 0 || investigator.uniqueItems.count > 0){
        [self println:@"Inventory:" minWidth:27];
        for (Item *item in investigator.commonItems){
            [self println:item.name minWidth:27];
        }
        for (Item *item in investigator.uniqueItems){
            [self println:item.name minWidth:27];
        }
        [self println:@"" minWidth:27];
    }
    else {
        [self println:@"No Items" minWidth:27];
    }
    
    if (investigator.spells.count > 0){
        [self println:@"Spells:" minWidth:27];
        for (Item *spell in investigator.spells){
            [self println:spell.name minWidth:27];
        }
        [self println:@"" minWidth:27];
    }
    else {
        [self println:@"No Spells" minWidth:27];
    }
    
    if (investigator.skills.count > 0){
        [self println:@"Skills:" minWidth:27];
        for (Item *skill in investigator.skills){
            [self println:skill.name minWidth:27];
        }
        [self println:@"" minWidth:27];
    }
    else {
        [self println:@"No Skills" minWidth:27];
    }
    
    if (investigator.allies.count > 0){
        [self println:@"Allies:" minWidth:27];
        for (Ally *ally in investigator.allies){
            [self println:ally.name minWidth:27];
        }
        [self println:@"" minWidth:27];
    }
    else {
        [self println:@"No Allies" minWidth:27];
    }
    
    [self printHBar:27];
}

-(NSString*)stringf:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString *ret = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    return ret;
}

-(NSString*)coloredString:(NSString*)text {
    NSString *colorFormatString = [self stringf:@"%c[%d;%d;%dm",kEscapeChar,self.printMode,self.foreground,self.background];
    text = [self stringf:@"%@%@%lu",colorFormatString,text,kEscapeChar];
    return text;
}

-(void)print:(NSString*)string {
    if (self.printsColors){
        string = [self coloredString:string];
    }
    printf("%s",[string UTF8String]);
}

-(void)println:(NSString*)string {
    if (self.printsColors){
        string = [self coloredString:string];
    }
    printf("%s\n",[string UTF8String]);
}

-(void)printHBar:(int)width {
    [self print:@"o"];
    for (int idx = 0; idx < width-2; idx++){
        [self print:@"-"];
    }
    [self println:@"o"];
}

-(void)println:(NSString*)text minWidth:(int)minWidth {
    int spaces = minWidth - (int)text.length - 2;
    [self print:@"|"];
    [self print:text];
    for (int idx = 0; idx < spaces; idx++){
        [self print:@" "];
    }
    [self print:@"|\n"];
}


#pragma mark - ArkhamHorror UI API

-(void)processEventsQueue {
    [self processNextEvent]; // recursively resolves each event in order
    [self getString:@"All events processed. Hit Enter to continue..."]; // just a halt to debugging
    [self println:@""];
}

-(void)processNextEvent {
    if (!self.currentGame.gameOver){
        if (self.eventsQueue.count > 0){
            void (^enqueuedBlock)(void) = [self.eventsQueue firstObject];
            [self.eventsQueue removeObject:enqueuedBlock];
            enqueuedBlock();
        }
    }
    else {
        [self println:@"Game Over."];
    }
}

-(void)enqueueAncientOneSetup:(AHAncientOneSelectEvent)callback {
    void (^ancientOneSetupBlock)(void) = ^{
        // TODO may be random or selected
        [self println:@"AncientOne setup requested, returning Azathoth"];
        callback(@"Azathoth");
    };
    [self.eventsQueue addObject:ancientOneSetupBlock];
}
-(void)enqueuePlayerSetup:(AHPlayerSelectEvent)callback {
    void (^playerSetupBlock)(void) = ^{
        [self println:@"Player setup requested, returning Mike"];
        BOOL donePicking = [self getBool:@"Done adding players? "];
        callback(@"Mike",donePicking);
    };
    [self.eventsQueue addObject:playerSetupBlock];
}

-(void)enqueueQuitEvent:(AHQuitEvent)callback push:(BOOL)pushToFront {
    void (^quitBlock)(void) = ^{
        [self println:@"Quiting"];
    };
    if (pushToFront){
        [self.eventsQueue insertObject:quitBlock atIndex:0];
    }
    else {
        [self.eventsQueue addObject:quitBlock];
    }
}

-(void)enqueueDieRollEvent:(AHRollEvent)callback push:(BOOL)pushToFront{
    void (^dieRollBlock)(void) = ^{
        NSUInteger roll = [Die d6];
        callback(roll);
        [self processNextEvent];
    };
    if (pushToFront){
        [self.eventsQueue insertObject:dieRollBlock atIndex:0];
    }
    else {
        [self.eventsQueue addObject:dieRollBlock];
    }
}

-(void)enqueueSkillCheckEvent:(NSInteger)dieToRoll difficulty:(NSInteger)difficulty callback:(AHSkillCheckEvent)callback push:(BOOL)pushToFront {
    void (^skillCheckBlock)(void) = ^{
        NSMutableArray *rolls = [NSMutableArray new];
        for (int idx = 0; idx < dieToRoll; idx++){
            [rolls addObject:@([Die d6])];
        }
        callback(rolls);
        [self processNextEvent];
    };
    if (pushToFront){
        [self.eventsQueue insertObject:skillCheckBlock atIndex:0];
    }
    else {
        [self.eventsQueue addObject:skillCheckBlock];
    }
}

-(void)enqueueSelectionEvent:(NSArray *)selections select:(NSUInteger)select callback:(AHSelectEvent)callback push:(BOOL)pushToFront{
    // select <select> amount of items from <selections>, return that subset to <callback>
}

@end
