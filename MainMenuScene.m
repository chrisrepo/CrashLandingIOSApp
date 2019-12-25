//
//  MainMenuScene.m
//  CrashLandingV1.0
//
//  Created by Chris on 4/29/14.
//  Copyright (c) 2014 Chris Repanich. All rights reserved.
//

#import "MainMenuScene.h"
#import "MyScene.h"
@implementation MainMenuScene
-(id)initWithSize:(CGSize)size
{
    if (self = [super initWithSize:size])
    {
        SKSpriteNode *bg;
        bg = [SKSpriteNode spriteNodeWithImageNamed:@"MainMenu.png"];
        bg.position = CGPointMake(self.size.width/2, self.size.height/2);
        [self addChild:bg];
        
        
        
    }
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *myTouch = [[touches allObjects] objectAtIndex: 0];
    CGPoint currentPos = [myTouch locationInNode:self];

    if (currentPos.x >= 80 && currentPos.x <=240 && currentPos.y <= 125 && currentPos.y >=65)
    {
        SKScene *myScene = [[MyScene alloc]initWithSize:self.size];
        SKTransition *reveal = [SKTransition doorwayWithDuration:0.5];
        reveal.pausesIncomingScene = NO;
        [self.view presentScene:myScene transition:reveal];
    }
}
@end
