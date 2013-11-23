//
//  RoombaController.h
//  RoombaController
//
//  Created by Jess Latimer on 11/19/2013.
//  Copyright (c) 2013 Robot Friendship Society. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "WiFiDongleController.h"


#define ROOMB_VELOCITY_MAX 500
#define ROOMB_VELOCITY_STOPPED 0
#define ROOMB_RADIUS_MAX 2000
#define ROOMB_RADIUS_STRAIGT 0x8000
#define ROOMB_RADIUS_SPIN 1


@protocol RoombaControllerDelegate <NSObject>
@required
-(void)roombaControllerDidStart;
-(void)roombaControllerCantStart;
-(void)roombaControllerDidStop;
@end

@interface RoombaController : NSObject <WiFiDongleControllerDelegate>
{
	id <RoombaControllerDelegate> delegate;
}

@property (retain) id delegate;

-(void)startRoombaController;
-(void)stopRoombaController;
-(BOOL)RoombaIsConnected;

-(BOOL)VacuumIsOn;
-(BOOL)sendVacuumOnCommand;
-(BOOL)sendVacuumOffCommand;
-(BOOL)sendDriveCommandwithVelocity:(CGFloat)velocityFloat radius:(CGFloat)radiusFloat;

@end
