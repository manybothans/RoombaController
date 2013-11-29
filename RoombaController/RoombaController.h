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

//Public Constants
#define ROOMB_VELOCITY_MAX 500
#define ROOMB_VELOCITY_STOPPED 0
#define ROOMB_VELOCITY_MOVE 150
#define ROOMB_RADIUS_MAX 2000
#define ROOMB_RADIUS_STRAIGT 0x8000
#define ROOMB_RADIUS_SPIN 1
#define ROOMB_WHEELBASE 258


@protocol RoombaControllerDelegate <NSObject>
@required
-(void)roombaControllerDidStart;
-(void)roombaControllerCantStart;
-(void)roombaControllerDidStop;
@optional
-(void)handleRoombaBumbEvent;
-(void)handleRoombaMovementDistance:(NSNumber *)distance angle:(NSNumber *)angle;
@end

@interface RoombaController : NSObject <WiFiDongleControllerDelegate>
{
	id <RoombaControllerDelegate> delegate;
    
    NSNumber *ControllerIsRunning;
    NSNumber *VacuumIsRunning;
    NSNumber *currentVelocity;
    NSNumber *currentRadius;
}

@property (retain) id delegate;
@property (strong) NSNumber *ControllerIsRunning;
@property (strong) NSNumber *VacuumIsRunning;
@property (strong) NSNumber *currentVelocity;
@property (strong) NSNumber *currentRadius;

//Public Methods

//Starting/Stopping
-(void)startRoombaController;
-(void)stopRoombaController;

//Roomba Control
-(BOOL)sendVacuumOnCommand;
-(BOOL)sendVacuumOffCommand;
-(BOOL)sendDriveCommandwithVelocity:(NSInteger)velocity radius:(NSInteger)radius;
-(BOOL)driveStraightDistance:(NSNumber *)distanceMM;
-(BOOL)driveTurnAngle:(NSNumber *)anngleRadians;
-(BOOL)driveStop;

@end
