//
//  MyScene.m
//  CrashLandingV1.0
//
//  Created by Chris on 4/27/14.
//  Copyright (c) 2014 Chris Repanich. All rights reserved.
//

#import "MyScene.h"

@implementation MyScene
{
    SKNode *_bgLayer;
    SKNode *_gameLayer;
    SKNode *_HUDLayer;
    SKSpriteNode *_playerPlane;
    SKSpriteNode *_gameOverMenu;
    SKSpriteNode *_finalScoreSprite;
    CGFloat _yVelocity;
    CGPoint _lastTouchLocation;
    NSTimeInterval _lastUpdateTime;
    NSTimeInterval _dt;
    BOOL facingDown;
    BOOL isGameOver;
    SKAction *_helicopterAnimation;
    SKLabelNode *_scoreLabel;
    SKLabelNode *_scoreCount;
    int _difficultyLevel;
    SKTexture* _pipeTexture1;
    SKTexture* _pipeTexture2;
    SKAction* _movePipes;
}

static int _gameScore;

static const uint32_t planeCategory = 1 << 0;
static const uint32_t worldCategory = 1 << 1;
static const uint32_t pipeCategory = 1 << 2;
static const uint32_t scoreCategory = 1 << 3;
static const uint32_t skyCategory = 1 << 4;
static const int POLE_POINTS_PER_SEC = 150;
-(id)initWithSize:(CGSize)size {

    if (self = [super initWithSize:size]) {
        [self runAction:[SKAction waitForDuration:2]];
        self.physicsWorld.gravity = CGVectorMake( 0.0, -5.0 );
        self.physicsWorld.contactDelegate = self;
        /* Setup your scene here */
        _gameScore = 0;
        _difficultyLevel = 0;
        
        _bgLayer = [SKNode node];
        [self addChild:_bgLayer];
        _gameLayer = [SKNode node];
        [self addChild:_gameLayer];
        _HUDLayer = [SKNode node];
        [self addChild:_HUDLayer];
        
        self.backgroundColor = [SKColor whiteColor];
        
        
        _gameOverMenu = [SKSpriteNode spriteNodeWithImageNamed:@"GameOverImage"];
        _gameOverMenu.hidden = YES;
        _gameOverMenu.position = CGPointMake(self.size.width/2, self.size.height/2);
        
        isGameOver = NO;
        
        [_HUDLayer addChild:_gameOverMenu];
        
        _finalScoreSprite = [SKSpriteNode node];
        NSString *digit = [NSString stringWithFormat:@"%i",_gameScore];
        [self setScoreSprite:(int)digit.length];
        _finalScoreSprite.zPosition = 201;
        [_HUDLayer addChild:_finalScoreSprite];
        
        _playerPlane = [SKSpriteNode spriteNodeWithImageNamed:@"pixelPlane"];
        _playerPlane.position = CGPointMake(60, 400);
        _playerPlane.zPosition = 50;
        _playerPlane.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(46, 18)];
        _playerPlane.physicsBody.dynamic = YES;
        _playerPlane.physicsBody.allowsRotation = NO;
        _playerPlane.physicsBody.categoryBitMask = planeCategory;
        _playerPlane.physicsBody.collisionBitMask = worldCategory | pipeCategory | skyCategory;
        _playerPlane.physicsBody.contactTestBitMask = worldCategory | pipeCategory | skyCategory;
        [_gameLayer addChild:_playerPlane];
        
        
        // Create ground
        
        SKTexture* groundTexture = [SKTexture textureWithImageNamed:@"Ground"];
        groundTexture.filteringMode = SKTextureFilteringNearest;
        SKAction* moveGroundSprite = [SKAction moveByX:-groundTexture.size.width*2 y:0 duration:0.02 * groundTexture.size.width*2];
        SKAction* resetGroundSprite = [SKAction moveByX:groundTexture.size.width*2 y:0 duration:0];
        SKAction* moveGroundSpritesForever = [SKAction repeatActionForever:[SKAction sequence:@[moveGroundSprite, resetGroundSprite]]];
        
        for( int i = 0; i < 2 + self.frame.size.width / ( groundTexture.size.width * 2 ); ++i ) {
            // Create the sprite
            SKSpriteNode* sprite = [SKSpriteNode spriteNodeWithTexture:groundTexture];
            [sprite setScale:1.0];
            sprite.zPosition = 10;
            sprite.anchorPoint = CGPointZero;
            sprite.position = CGPointMake(i * sprite.size.width, 0);
            [sprite runAction:moveGroundSpritesForever];
            [_gameLayer addChild:sprite];
        }
        
        //groundPhysics
        
        SKNode* dummy = [SKNode node];
        dummy.position = CGPointMake(0, -1);
        dummy.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(self.frame.size.width, groundTexture.size.height * 2)];
        dummy.physicsBody.dynamic = NO;
        dummy.physicsBody.categoryBitMask = worldCategory;
        [_gameLayer addChild:dummy];
        
        SKNode* dummyCeiling = [SKNode node];
        dummyCeiling.position = CGPointMake(0, self.size.height);
        dummyCeiling.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(self.size.width, 1)];
        dummyCeiling.physicsBody.dynamic = NO;
        dummyCeiling.physicsBody.categoryBitMask = skyCategory;
        [_gameLayer addChild:dummyCeiling];
        
        // Create skyline
        
        SKTexture* skylineTexture = [SKTexture textureWithImageNamed:@"backgroundI4"];
        skylineTexture.filteringMode = SKTextureFilteringNearest;
        
        SKAction* moveSkylineSprite = [SKAction moveByX:-skylineTexture.size.width*2 y:0 duration:0.1 * skylineTexture.size.width*2];
        SKAction* resetSkylineSprite = [SKAction moveByX:skylineTexture.size.width*2 y:0 duration:0];
        SKAction* moveSkylineSpritesForever = [SKAction repeatActionForever:[SKAction sequence:@[moveSkylineSprite, resetSkylineSprite]]];
        
        for( int i = 0; i < 2 + self.frame.size.width / ( skylineTexture.size.width * 2 ); ++i ) {
            SKSpriteNode* sprite = [SKSpriteNode spriteNodeWithTexture:skylineTexture];
            [sprite setScale:1.0];
            sprite.zPosition = -20;
            sprite.anchorPoint = CGPointZero;
            sprite.position = CGPointMake(i * sprite.size.width, 0);
            [sprite runAction:moveSkylineSpritesForever];
            [_bgLayer addChild:sprite];
        }
        
    
        //spawner
        
        SKAction* spawn = [SKAction performSelector:@selector(spawnLoops) onTarget:self];
        SKAction* delay = [SKAction waitForDuration:2.0];
        SKAction* spawnThenDelay = [SKAction sequence:@[spawn, delay]];
        SKAction* spawnThenDelayForever = [SKAction repeatActionForever:spawnThenDelay];
        [self runAction:spawnThenDelayForever];
        
        SKAction* raiseDifficulty = [SKAction performSelector:@selector(raiseDifficultyLevel) onTarget:self];
        SKAction* difficultyRaiseDelay = [SKAction waitForDuration:10];
        SKAction* waitThenRaiseForever = [SKAction repeatActionForever:[SKAction sequence:@[difficultyRaiseDelay, raiseDifficulty]]];
        [self runAction:waitThenRaiseForever];
    }
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    UITouch *myTouch = [[touches allObjects] objectAtIndex: 0];
    CGPoint currentPos = [myTouch locationInNode:self];
    if (_gameLayer.speed > 0)//only works when game over is not true
    {
        _playerPlane.physicsBody.velocity = CGVectorMake(0, 0);
        [_playerPlane.physicsBody applyImpulse:CGVectorMake(0, 14)];
        //NSLog(@"Current Pos: %f",currentPos.y);
    }
    if (isGameOver)
    {
        
        if (currentPos.x >= (self.size.width/2)- 90 && currentPos.x <= (self.size.width/2)+ 90 && currentPos.y >= self.size.height/2 - 82 && currentPos.y <= self.size.height/2 - 41)
        {
            SKScene *myScene = [[MyScene alloc]initWithSize:self.size];
            SKTransition *reveal = [SKTransition doorwayWithDuration:0.5];
            reveal.pausesIncomingScene = NO;
            [self.view presentScene:myScene transition:reveal];
        }
    }
}

- (void)boundsCheckPlayer
{
    CGPoint newPosition = _playerPlane.position;

    CGPoint bottomLeft = [_gameLayer convertPoint:CGPointMake(0, 0) fromNode:self];
    CGPoint topRight =
    [_bgLayer convertPoint:CGPointMake(self.size.width,
                                       self.size.height)
                  fromNode:self];

    if (newPosition.y >= topRight.y - 10) {
        newPosition.y = topRight.y - 10;
    }
    if (newPosition.y <= bottomLeft.y + 100)
    {
        newPosition.y = bottomLeft.y + 100;
    }

    _playerPlane.position = newPosition;
}

-(void)update:(CFTimeInterval)currentTime {
    if (_lastUpdateTime) {
        _dt = currentTime - _lastUpdateTime;
    } else {
        _dt = 0;
    }

    _playerPlane.zRotation = clamp( -.5, 0.5, _playerPlane.physicsBody.velocity.dy * ( _playerPlane.physicsBody.velocity.dy < 0 ? 0.001 : 0.001 ) );

    _scoreCount.text = [NSString stringWithFormat:@"%i",_gameScore];
    _lastUpdateTime = currentTime;
    if (isGameOver == NO)
    {
         [self movePipes];
    }
   
}

CGFloat clamp(CGFloat min, CGFloat max, CGFloat value) {
    if( value > max ) {
        return max;
    } else if( value < min ) {
        return min;
    } else {
        return value;
    }
}



-(void)spawnLoops
{
    SKSpriteNode *behindLoop = [SKSpriteNode spriteNodeWithImageNamed:@"PipeBehindHalf"];
    behindLoop.zPosition = 20;
    [behindLoop setScale:1.3];
    SKSpriteNode *frontLoop = [SKSpriteNode spriteNodeWithImageNamed:@"PipeInFront"];
    frontLoop.zPosition = 100;
    [frontLoop setScale:1.3];
    
    _pipeTexture1 = [SKTexture textureWithImageNamed:@"PipeLength"];
    _pipeTexture1.filteringMode = SKTextureFilteringNearest;
    _pipeTexture2 = [SKTexture textureWithImageNamed:@"PipeLength"];
    _pipeTexture2.filteringMode = SKTextureFilteringNearest;
    
    SKSpriteNode *poleLoop = [SKSpriteNode spriteNodeWithTexture:_pipeTexture1];
    poleLoop.zPosition = 9;
    poleLoop.hidden = NO;
    poleLoop.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:poleLoop.size];
    poleLoop.physicsBody.dynamic = NO;
    
    SKSpriteNode *poleLoopTop = [SKSpriteNode spriteNodeWithTexture:_pipeTexture2];
    poleLoopTop.hidden = YES;
    poleLoopTop.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:poleLoopTop.size];
    poleLoopTop.physicsBody.dynamic = NO;
    
    //make loops move
    float changeFactor = self.frame.size.height - 250;
    CGFloat y = arc4random() % (NSInteger)(changeFactor);
    poleLoop.position = CGPointMake(self.size.width + 100, y-50);
    poleLoopTop.position = CGPointMake(self.size.width + 100, y-50 + poleLoop.size.height + 128);
    behindLoop.position = CGPointMake(self.size.width + 70, y-50 + poleLoop.size.height - 106);
    frontLoop.position = CGPointMake(self.size.width + 130, y-50+ poleLoop.size.height - 106);
    
    frontLoop.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:frontLoop.size];
    frontLoop.physicsBody.dynamic = NO;
    frontLoop.physicsBody.categoryBitMask = scoreCategory;
    frontLoop.physicsBody.contactTestBitMask = planeCategory;
    
    poleLoop.physicsBody.categoryBitMask = pipeCategory;
    poleLoop.physicsBody.contactTestBitMask = planeCategory;
    
    poleLoopTop.physicsBody.categoryBitMask = pipeCategory;
    poleLoopTop.physicsBody.contactTestBitMask = planeCategory;
    
    poleLoop.name = @"pole";
    poleLoopTop.name = @"pole";
    frontLoop.name = @"pole";
    behindLoop.name = @"pole";
    
    //[poleLoop runAction:_moveAndRemovePipes];
    //[poleLoopTop runAction:_moveAndRemovePipes];
    //[behindLoop runAction:_moveAndRemovePipes];
   // [frontLoop runAction:_moveAndRemovePipes];
    [_gameLayer addChild:poleLoop];
    [_gameLayer addChild:poleLoopTop];
    [_gameLayer addChild:behindLoop];
    [_gameLayer addChild:frontLoop];
}

- (void)didBeginContact:(SKPhysicsContact *)contact
{
    if( _gameLayer.speed > 0 )
    {
        if( ( contact.bodyA.categoryBitMask & scoreCategory ) == scoreCategory || ( contact.bodyB.categoryBitMask & scoreCategory ) == scoreCategory ) {
            // Plane has contact with score entity
            _gameScore++;
            NSMutableString *scoreString = [NSMutableString stringWithFormat:@"%i", _gameScore];
            int length = (int) scoreString.length;
            [self setScoreSprite:length];
        }
        else if ((contact.bodyA.categoryBitMask & skyCategory ) == skyCategory || ( contact.bodyB.categoryBitMask & skyCategory ) == skyCategory)
        {
            //do nothing, let the plane just collide with ceiling and not be able to go higher
        }
        else
        {
            _gameLayer.speed = 0;
            _bgLayer.speed = 0;
            [self removeAllActions];
            _playerPlane.physicsBody.collisionBitMask = worldCategory;
        
            [_playerPlane runAction:[SKAction rotateByAngle:M_PI * _playerPlane.position.y * 0.01 duration:_playerPlane.position.y * 0.003] completion:^{
            _playerPlane.speed = 0;
            }];
            
            _gameOverMenu.hidden = NO;
            _gameOverMenu.zPosition = 200;
            
            NSMutableString *scoreString = [NSMutableString stringWithFormat:@"%i", _gameScore];
            
            int length = (int) scoreString.length;
            
            
            _finalScoreSprite.zPosition = 201;
            //_scoreCount.position = CGPointMake(self.size.width/2 - 15, self.size.height/2 - 10);
            _scoreCount.fontSize = 30;
            _scoreCount.zPosition = 201;
            _scoreLabel.hidden = YES;
            isGameOver = YES;
            [self setScoreSprite:length];

            
        }
    }
}

-(void)setScoreSprite:(int)numberOfDigitsInScore
{
    //do final score stuff here , not in physics contact;
    NSMutableString *scoreString = [NSMutableString stringWithFormat:@"%i", _gameScore];
    if (isGameOver == YES)
    {
       [_finalScoreSprite removeAllChildren];
        double val1;
        int sides;
        switch (numberOfDigitsInScore)
        {
            case 1:
            {
                NSString *digit = [scoreString substringFromIndex:0];
                SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:[NSString stringWithFormat:@"Number%@",digit]];
                sprite.position = CGPointMake(self.size.width/2, self.size.height/2 - 10);
                [_finalScoreSprite addChild:sprite];
                break;
            }
            case 2:
            {
                for (int i = 0; i < scoreString.length; i++)
                {
                    sides =(i!=0)? 1 :-1;
                    NSString *digit = [scoreString substringWithRange:NSMakeRange(i, 1)];
                    SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:[NSString stringWithFormat:@"Number%i",digit.intValue]];
                    if (digit.intValue == 1)
                    {
                        val1 = 5;
                    } else{
                        val1 = 0;
                    }
                    sprite.position = CGPointMake(self.size.width/2 + (15 -val1)*sides, self.size.height/2 - 10);
                    [_finalScoreSprite addChild:sprite];
                }
                break;
            }
            case 3:
            {
                for (int i = 0; i < scoreString.length; i++)
                {
                    NSString *digit = [scoreString substringWithRange:NSMakeRange(i, 1)];
                    SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:[NSString stringWithFormat:@"Number%@",digit]];
                    if (i == 0)
                    {
                        sides = -1;
                    } else if (i == 2)
                    {
                        sides = 1;
                    } else
                    {
                        sides = 0;
                    }
                    
                    if (digit.intValue == 1)
                    {
                        val1 = 6;
                    } else{
                        val1 = 0;
                    }
                    sprite.position = CGPointMake(self.size.width/2 + (30-val1)*sides, self.size.height/2 - 10);
                    [_finalScoreSprite addChild:sprite];
                }
                break;
            }
            case 4:
            {
                for (int i = 0; i < scoreString.length; i++)
                {
                    NSString *digit = [scoreString substringWithRange:NSMakeRange(i, 1)];
                    SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:[NSString stringWithFormat:@"Number%@",digit]];
                    sprite.position = CGPointMake(self.size.width/2 - 40 + (25*i), self.size.height/2 - 10);
                    [_finalScoreSprite addChild:sprite];
                }
                break;
            }
            case 5:
            {
                for (int i = 0; i < scoreString.length; i++)
                {
                    NSString *digit = [scoreString substringWithRange:NSMakeRange(i, 1)];
                    SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:[NSString stringWithFormat:@"Number%@",digit]];
                    sprite.position = CGPointMake(self.size.width/2 - 60 + (25*i), self.size.height/2 - 10);
                    [_finalScoreSprite addChild:sprite];
                }
                break;
            }//end final case
                
        }//end switch

    }//end if
    else if (isGameOver == NO)
    {
        [_finalScoreSprite removeAllChildren];
        switch (numberOfDigitsInScore)
        {
                double val1;
                int sides;
            case 1:
            {
                NSString *digit = [scoreString substringFromIndex:0];
                SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:[NSString stringWithFormat:@"Number%@",digit]];
                sprite.position = CGPointMake(self.size.width/2, self.size.height - 25);
                [_finalScoreSprite addChild:sprite];
                break;
            }
            case 2:
            {
                for (int i = 0; i < scoreString.length; i++)
                {
                    sides =(i!=0)? 1 :-1;
                    NSString *digit = [scoreString substringWithRange:NSMakeRange(i, 1)];
                    SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:[NSString stringWithFormat:@"Number%@",digit]];
                    if (digit.intValue == 1)
                    {
                        val1 = 5;
                    } else{
                        val1 = 0;
                    }
                    sprite.position = CGPointMake(self.size.width/2 + (15 -val1)*sides ,self.size.height-25);
                    [_finalScoreSprite addChild:sprite];
                }
                break;
            }
            case 3:
            {
                for (int i = 0; i < scoreString.length; i++)
                {
                    
                    NSString *digit = [scoreString substringWithRange:NSMakeRange(i, 1)];
                    SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:[NSString stringWithFormat:@"Number%@",digit]];
                    if (i == 0)
                    {
                        sides = -1;
                    } else if (i == 2)
                    {
                        sides = 1;
                    } else
                    {
                        sides = 0;
                    }
                    
                    if (digit.intValue == 1)
                    {
                        val1 = 6;
                    } else{
                        val1 = 0;
                    }
                    sprite.position = CGPointMake(self.size.width/2 + (30-val1)*sides ,self.size.height-25);
                    [_finalScoreSprite addChild:sprite];
                }
                break;
            }
            case 4:
            {
                for (int i = 0; i < scoreString.length; i++)
                {
                    NSString *digit = [scoreString substringWithRange:NSMakeRange(i, 1)];
                    SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:[NSString stringWithFormat:@"Number%@",digit]];
                    sprite.position = CGPointMake(_scoreLabel.position.x + 25 + 25*i,_scoreLabel.position.y);
                    [_finalScoreSprite addChild:sprite];
                }
                break;
            }
            case 5:
            {
                for (int i = 0; i < scoreString.length; i++)
                {
                    NSString *digit = [scoreString substringWithRange:NSMakeRange(i, 1)];
                    SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:[NSString stringWithFormat:@"Number%@",digit]];
                    sprite.position = CGPointMake(_scoreLabel.position.x + 25 + 25*i,_scoreLabel.position.y);
                    [_finalScoreSprite addChild:sprite];
                }
                break;
            }//end final case
                
        }//end switch
    }
}//end method scorefinal

-(void)raiseDifficultyLevel
{
    _difficultyLevel++;
}

-(void)movePipes
{
    [_gameLayer enumerateChildNodesWithName:@"pole" usingBlock:^(SKNode *node, BOOL *stop) {
        SKSpriteNode *poleSprite = (SKSpriteNode *) node;
        if (poleSprite.position.x < -50)
        {
            [poleSprite removeFromParent];
        }
        else
        {
            CGPoint distanceToMove = CGPointMake(-POLE_POINTS_PER_SEC,0);
            CGPoint amtToMove = CGPointMultiplyScalar(distanceToMove, _dt);
            poleSprite.position = CGPointAdd(amtToMove, poleSprite.position);
            //SKAction* movePipes = [SKAction moveByX:-distanceToMove*_dt y:0 duration: _dt];
           // [poleSprite runAction:movePipes];
           // _movePipes = movePipes;
        }
        
    }];
}

+ (int)grabGameScore {
    return _gameScore;
}

@end


/*
 THINGS TO DO
 -create physics body that connects at the very end of plane(on inside), this is what increments score, not head of plane. This will make it so players cant get points and lose at the same time when they hit the loop
 
 -change loops/poles to be one sprite(for move functions)
 -Maybe make the loops all part of one main Loop Class.
 
 -make pipes have ability to spawn lower(only spawn from around 150 - 400 pixels)
 
 -Make loops move up/down when difficulty goes up (use switch statement in movePipes method)
 
*/