//
//  RoombaController.h
//  RoombaController
//
//  Copyright (c) 2013 Jess Latimer
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  Except as contained in this notice, the name(s) of the above copyright holders
//  shall not be used in advertising or otherwise to promote the sale, use or
//  other dealings in this Software without prior written authorization.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "WiFiDongleController.h"


@protocol RoombaControllerDelegate <NSObject>
@required
-(void)roombaControllerDidStart;
-(void)roombaControllerCantStart;
-(void)roombaControllerDidStop;
@optional
-(void)handleRoombaBumbEvent;
-(void)handleRoombaSensorPacket:(NSData *)sensorPacket;
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
-(void)forceDockSeeking;

//Public Constants
typedef enum
{
    kMaxVelocity = 500,
    kStopVelocity = 0,
    kDriveVelocity = 150,
    kSpinVelocity = 200,
    kMaxRadius = 2000,
    kStraightRadius = 0x8000,
    kSpinRadius = 1,
    kWheelbase = 258

} RoombaValues;

@end
