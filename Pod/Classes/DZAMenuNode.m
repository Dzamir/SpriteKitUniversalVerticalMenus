//
//  DZAMenuNode.m
//  Pods
//
//  Created by Davide Di Stefano on 06/01/16.
//
//

#import "DZAMenuNode.h"

@interface DZAMenuNode()
{
#if TARGET_OS_TV
    UITouch * currentTouch;
    CGPoint initialTranslation;
#endif
}
@end

@implementation DZAMenuNode

-(void) reloadMenu;
{
    _currentMenuVoice = nil;
    for (SKNode * node in self.children)
    {
        if ([node isKindOfClass:[DZAMenuVoiceNode class]])
        {
            DZAMenuVoiceNode * menuVoiceNode = (DZAMenuVoiceNode *) node;
            menuVoiceNode.allowedAxis = _allowedAxis;
            menuVoiceNode.delegate = self;
        }
    }
    // take the first node as current
    self.currentMenuVoice = [self nextMenuVoice];
}

-(void) setCurrentMenuVoice:(DZAMenuVoiceNode *)currentMenuVoice
{
    if (currentMenuVoice != _currentMenuVoice)
    {
#if TARGET_OS_TV
        [self defocusMenuVoice:_currentMenuVoice];
#endif
        _currentMenuVoice = currentMenuVoice;
#if TARGET_OS_TV
        [self focusMenuVoice:_currentMenuVoice];
#endif
    }
}

-(void) setAllowedAxis:(DZAMenuAxis)allowedAxis
{
    _allowedAxis = allowedAxis;
}

-(NSArray *) menuVoices
{
    NSMutableArray * menuVoices = [NSMutableArray arrayWithCapacity:10];
    for (SKNode * node in self.children)
    {
        if ([node isKindOfClass:[DZAMenuVoiceNode class]])
        {
            [menuVoices addObject:node];
        }
    }
    return menuVoices;
}

-(DZAMenuVoiceNode *) nextMenuVoice
{
    DZAMenuVoiceNode * nextMenuVoice = nil;
    NSArray * menuVoices = [self menuVoices];
    for (DZAMenuVoiceNode * menuNode in menuVoices)
    {
        if (menuNode.tag > _currentMenuVoice.tag)
        {
            if (nextMenuVoice == nil)
            {
                nextMenuVoice = menuNode;
            } else if (menuNode.tag < nextMenuVoice.tag)
            {
                nextMenuVoice = menuNode;
            }
        }
    }
    return nextMenuVoice;
}

-(DZAMenuVoiceNode *) previousMenuVoice
{
    DZAMenuVoiceNode * previousMenuVoice = nil;
    NSArray * menuVoices = [self menuVoices];
    for (DZAMenuVoiceNode * menuNode in menuVoices)
    {
        if (menuNode.tag < _currentMenuVoice.tag)
        {
            if (previousMenuVoice == nil)
            {
                previousMenuVoice = menuNode;
            } else if (menuNode.tag > previousMenuVoice.tag)
            {
                previousMenuVoice = menuNode;
            }
        }
    }
    return previousMenuVoice;

}

-(DZAMenuVoiceNode *) moveSelection:(DZAMenuDirection) direction;
{
    if (_allowedAxis == DZAMenuAxisHorizontal)
    {
        if (direction == DZAMenuDirectionLeft)
        {
            self.currentMenuVoice = [self previousMenuVoice];
        } else if (direction == DZAMenuDirectionRight)
        {
            self.currentMenuVoice = [self nextMenuVoice];
        }
    } else
    {
        if (direction == DZAMenuDirectionDown)
        {
            self.currentMenuVoice = [self previousMenuVoice];
        } else if (direction == DZAMenuDirectionUp)
        {
            self.currentMenuVoice = [self nextMenuVoice];
        }
    }
    [self focusMenuVoice:self.currentMenuVoice];
    return self.currentMenuVoice;
}

#pragma mark tvOS touch handling

#if TARGET_OS_TV

-(void) focusMenuVoice:(DZAMenuVoiceNode *) menuVoiceNode
{
    SKAction * scaleAction = [SKAction scaleTo:1.2 duration:0.3];
    [menuVoiceNode runAction:scaleAction];
    NSLog(@"Focus %i", menuVoiceNode.tag);
}

-(void) defocusMenuVoice:(DZAMenuVoiceNode *) menuVoiceNode
{
    SKAction * scaleAction = [SKAction scaleTo:1.0 duration:0.3];
    [menuVoiceNode runAction:scaleAction];
    NSLog(@"Defocus %i", menuVoiceNode.tag);
}

-(CGFloat) horizontalThreeshold
{
    if (_allowedAxis == DZAMenuAxisHorizontal)
    {
        return THREESHOLD;
    } else
    {
        return THREESHOLD / 4;
    }
}

-(CGFloat) verticalThreeshold
{
    if (_allowedAxis == DZAMenuAxisVertical)
    {
        return THREESHOLD;
    } else
    {
        return THREESHOLD / 4;
    }
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (currentTouch == nil)
    {
        initialTranslation = CGPointMake(0, 0);
        currentTouch = [touches anyObject];
        CGPoint point = [currentTouch locationInNode:self];
        NSLog(@"position %@", NSStringFromCGPoint(point));
        [self focusMenuVoice:_currentMenuVoice];
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    currentTouch = [touches anyObject];
    CGPoint point = [currentTouch locationInNode:self];
    CGPoint translationPoint = CGPointMake( (point.x - initialTranslation.x) / 30.0f, (point.y - initialTranslation.y) / 30.0f);
    CGFloat horizontalThreeshold = [self horizontalThreeshold];
    CGFloat verticalThreeshold = [self verticalThreeshold];
    if (translationPoint.x > horizontalThreeshold)
    {
        translationPoint.x = horizontalThreeshold;
        if (_allowedAxis == DZAMenuAxisHorizontal)
        {
            initialTranslation = point;
            [self cancelTouch];
            [self moveSelection:DZAMenuDirectionRight];
        }
    } else if (translationPoint.x < -horizontalThreeshold)
    {
        translationPoint.x = -horizontalThreeshold;
        if (_allowedAxis == DZAMenuAxisHorizontal)
        {
            initialTranslation = point;
            [self cancelTouch];
            [self moveSelection:DZAMenuDirectionLeft];
        }
    }
    if (translationPoint.y > verticalThreeshold)
    {
        translationPoint.y = verticalThreeshold;
        if (_allowedAxis == DZAMenuAxisVertical)
        {
            initialTranslation = point;
            [self cancelTouch];
            [self moveSelection:DZAMenuDirectionDown];
        }
    } else if (translationPoint.y < -verticalThreeshold)
    {
        translationPoint.y = -verticalThreeshold;
        if (_allowedAxis == DZAMenuAxisVertical)
        {
            initialTranslation = point;
            [self cancelTouch];
            [self moveSelection:DZAMenuDirectionUp];
        }
    }
    NSLog(@"position %@", NSStringFromCGPoint(point));
    SKAction * moveAction = [SKAction moveTo:CGPointMake(_currentMenuVoice.originalPosition.x + translationPoint.x, _currentMenuVoice.originalPosition.y + translationPoint.y) duration:0.1];
    [_currentMenuVoice runAction:moveAction];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    initialTranslation = CGPointMake(0, 0);
    [self cancelTouch];
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    initialTranslation = CGPointMake(0, 0);
    [self cancelTouch];
}

-(void) cancelTouch
{
    SKAction * moveAction = [SKAction moveTo:_currentMenuVoice.originalPosition duration:0.5];
    [_currentMenuVoice runAction:moveAction];
    currentTouch = nil;
}

#endif

#pragma mark AGSpriteButtonDelegate

-(void) spriteButton:(AGSpriteButton *) spriteButton didMoveToDirection:(DZAMenuDirection) direction;
{
    [self moveSelection:direction];
}

@end
