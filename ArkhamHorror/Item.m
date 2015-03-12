//
//  Item.m
//  ArkhamHorror
//
//  Created by Michael Cornell on 2/24/15.
//  Copyright (c) 2015 Sleepy. All rights reserved.
//

#import "Item.h"

NSUInteger const kItemInfiniteUses = 0;

@implementation Item


#pragma mark - instance methods

-(instancetype)init {
    self = [super init];
    if (self){
        self.name = @"Item";
        self.price = 0;
        self.hands = 0;
        self.cardType = CardTypeCommonItem;
    }
    return self;
}

-(instancetype)initWithProperties:(NSDictionary *)properties {
    self = [super init];
    if (self) {
        self.name = properties[@"name"];
        self.hands = [properties[@"hands"] integerValue];
        self.price = [properties[@"price"] integerValue];
        self.usesBeforeDiscard = [properties[@"uses_before_discard"] integerValue];
        self.itemClass = ItemClassificationNone;
        if (properties[@"item_class"]){
            NSString *class = properties[@"item_class"];
            if ([class isEqualToString:@"Physical Weapon"]){
                self.itemClass = ItemClassificationPhysicalWeapon;
            }
            else if ([class isEqualToString:@"Magical Weapon"]){
                self.itemClass = ItemClassificationMagicalWeapon;
            }
            else if ([class isEqualToString:@"Tome"]){
                self.itemClass = ItemClassificationTome;
            }
        }
    }
    return self;
}
@end

#pragma mark - subclasses

@implementation WeaponItem
@end
@implementation TomeItem
@end
@implementation HealingItem
@end
@implementation MovementItem
@end
@implementation SkillBonusItem
@end
