//
//  RoombaController.m
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


#import "RoombaController.h"

#define IS_NEGATIVE(x) (x<0)
#define STOP_TIMER(t) if(t!=nil){[t invalidate];t = nil;}

//Private Constants
#define ROOMBCMD_START 0x80
#define ROOMBCMD_BAUD 0x81
#define ROOMBCMD_CONTROL 0x82
#define ROOMBCMD_SAFE 0x83
#define ROOMBCMD_FULL 0x84
#define ROOMBCMD_POWER 0x85
#define ROOMBCMD_SENSOR 0x8E
#define ROOMBCMD_MOTORS 0x8A
#define ROOMBCMD_DRIVE 0x89
#define ROOMBCMD_SPOT 0x86
#define ROOMBCMD_CLEAN 0x87
#define ROOMBCMD_MAX 0x88
#define ROOMBCMD_DOCK 0x8F


@interface RoombaController ()
{
    WiFiDongleController *wifiDongle;
    NSTimer *sensorPollingTimer;
    NSTimer *driveTimer;
}

@property (nonatomic, retain) WiFiDongleController *wifiDongle;
@property (nonatomic, retain) NSTimer *sensorPollingTimer;
@property (nonatomic, retain) NSTimer *driveTimer;

//Private Methods

-(void)notConnectedToWiFiDongleNetwork;
-(void)lostConnectionToWiFiDongleNetwork;
-(void)cantInitializeWiFiDongleSocket;
-(void)didConnectToWiFiDongle;
-(void)beginControllingRoomba;
-(void)startQueryingSensors;
-(void)SensorPacketReceiver:(WiFiDongleController *)connectedDongle;
-(void)processReceviedSensorPacket:(NSData *)sensorPacket;
-(void)sendRoombaStartCommands;
-(void)wakeUpRoombaWithDeviceDetect;
-(BOOL)sendStartCommand;
-(BOOL)sendBaudCommand:(NSUInteger)baudRate;
-(BOOL)sendControlCommand;
-(BOOL)sendSafeCommand;
-(BOOL)sendFullCommand;
-(BOOL)sendPowerCommand;
-(BOOL)sendSpotCommand;
-(BOOL)sendCleanCommand;
-(BOOL)sendMaxCommand;
-(BOOL)sendDockCommand;
-(BOOL)sendRoombaCommandBytes:(void*)commandBytes length:(int)length;
@end


@implementation RoombaController

@synthesize delegate;
@synthesize wifiDongle;
@synthesize sensorPollingTimer;
@synthesize driveTimer;
@synthesize ControllerIsRunning;
@synthesize VacuumIsRunning;
@synthesize currentVelocity;
@synthesize currentRadius;


#pragma mark - Initialization

- init;
{
	DLog(@"RoombaController init");
    
    self.ControllerIsRunning = [NSNumber numberWithBool:NO];
    self.VacuumIsRunning = [NSNumber numberWithBool:NO];
    
	//[super init];
    
	return self;
}


#pragma mark - Start/Stop RoombaController

-(void)startRoombaController
{
	DLog(@"RoombaController startRoombaController");
    
    self.ControllerIsRunning = [NSNumber numberWithBool:NO];
    self.VacuumIsRunning = [NSNumber numberWithBool:NO];
    
    if(wifiDongle == nil)
    {
        wifiDongle = [[WiFiDongleController alloc] init];
        [wifiDongle setDelegate:self];
    }
    [wifiDongle connectToWiFiDongle];
}

-(void)stopRoombaController
{
	DLog(@"RoombaController stopRoombaController");
    
    //start the process of stopping, but we can't actually kill
    //here because we could cause probslems in other threads
    
    [self sendPowerCommand];
    
    self.ControllerIsRunning = [NSNumber numberWithBool:NO];
    self.VacuumIsRunning = [NSNumber numberWithBool:NO];
    
    STOP_TIMER(self.sensorPollingTimer);
    
    [wifiDongle disconnectFromWiFiDongle];
    [[self delegate] roombaControllerDidStop];
}


#pragma mark - WiFiDongleController Delegate Methods

-(void)notConnectedToWiFiDongleNetwork
{
	DLog(@"RoombaController notConnectedToWiFiDongleNetwork");
    
    [[self delegate] roombaControllerCantStart];
}

-(void)lostConnectionToWiFiDongleNetwork
{
	DLog(@"RoombaController lostConnectionToWiFiDongleNetwork");
    
    [self stopRoombaController];
}

-(void)cantInitializeWiFiDongleSocket
{
	DLog(@"RoombaController cantInitializeWiFiDongleSocket");
    
    [[self delegate] roombaControllerCantStart];
}

-(void)didConnectToWiFiDongle
{
	DLog(@"RoombaController didConnectToWiFiDongle");
    
    self.ControllerIsRunning = [NSNumber numberWithBool:YES];
    
    [self wakeUpRoombaWithDeviceDetect];
}

-(void)wakeUpRoombaWithDeviceDetect
{
	DLog(@"RoombaController wakeUpRoombaWithDeviceDetect");
    
    if([wifiDongle setRTSLow])
    {
        [wifiDongle performSelector:@selector(setRTSHigh) withObject:nil afterDelay:0.5];
        [self performSelector:@selector(beginControllingRoomba) withObject:nil afterDelay:2.5];
    }
}

-(void)beginControllingRoomba
{
    [self sendRoombaStartCommands];
    
    [[self delegate] roombaControllerDidStart];
}

-(void)startQueryingSensors
{
    //start new thread to receiver sensor packets
    [NSThread detachNewThreadSelector:@selector(SensorPacketReceiver:) toTarget:self withObject:wifiDongle];
    self.sensorPollingTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(sendSensorRequest) userInfo:nil repeats:YES];
}


#pragma mark - Control

-(void)SensorPacketReceiver:(WiFiDongleController *)connectedDongle
{
    NSMutableData *receivedData = [[NSMutableData alloc] init];
    
    int byteCount = 0;
    
    while ([ControllerIsRunning boolValue])
    {
        char* buffer = malloc(1);
        buffer = [connectedDongle readByteNonBlocking];
        if(buffer != NULL)
        {
            [receivedData appendBytes:buffer length:1];
            byteCount++;
            
            if(byteCount >= 26)
            {
                [self performSelectorOnMainThread:@selector(processReceviedSensorPacket:) withObject:[NSData dataWithData:receivedData] waitUntilDone:YES];
                
                //clear data structure for this next pass
                [receivedData replaceBytesInRange:NSMakeRange(0, [receivedData length]) withBytes:NULL length:0];
                
                byteCount = 0;
            }
        }
        free(buffer);
    }
    
	DLog(@"RoombaController RECEIVER KILLED");
}

-(void)processReceviedSensorPacket:(NSData *)sensorPacket
{
	//DLog(@"RoombaController processReceviedSensorPacket");
    
    unsigned long length = [sensorPacket length];
    
    char *buffer;
    buffer = malloc(length);
    [sensorPacket getBytes:buffer];
    
    //bumps, wheel drops, walls, etc
    if(buffer[0] != 0x00)
    {
        if([[self delegate] respondsToSelector:@selector(handleRoombaBumbEvent)])
            [[self delegate] handleRoombaBumbEvent];
    }
    
    //movement since last sensor query
    int distanceMM = ((int)buffer[12] << 8) + ((int)buffer[13]);
    int distanceDifference = ((int)buffer[14] << 8) + ((int)buffer[15]);
    float angleRadians = (2 * (float)distanceDifference) / ROOMB_WHEELBASE;
    if(IS_NEGATIVE(distanceDifference))
        angleRadians = angleRadians + 2;
    
    if([[self delegate] respondsToSelector:@selector(handleRoombaMovementDistance:angle:)])
        [[self delegate] handleRoombaMovementDistance:[NSNumber numberWithInt:distanceMM] angle:[NSNumber numberWithFloat:angleRadians]];
    
    if([[self delegate] respondsToSelector:@selector(handleRoombaSensorPacket:)])
        [[self delegate] handleRoombaSensorPacket:sensorPacket];
    
    free(buffer);
}

-(void)sendRoombaStartCommands
{
	DLog(@"RoombaController sendRoombaStartCommands");
    
    //need to wait between changing roomba control states
    [self performSelector:@selector(sendStartCommand) withObject:nil afterDelay:0.1];
    [self performSelector:@selector(sendControlCommand) withObject:nil afterDelay:0.2];
    [self performSelector:@selector(sendFullCommand) withObject:nil afterDelay:0.3];
    [self performSelector:@selector(startQueryingSensors) withObject:nil afterDelay:0.4];
}

-(BOOL)sendStartCommand
{
	DLog(@"RoombaController sendStartCommand");
    
    //enables roomba serial command interface (SCI)
    
    int8_t commandByte = ROOMBCMD_START;
    return [self sendRoombaCommandBytes:&commandByte length:sizeof(commandByte)];
}

-(BOOL)sendBaudCommand:(NSUInteger)baudRate
{
	DLog(@"RoombaController sendBaudCommand");
    
    //changes roomba SCI baud rate
    //must wait 100ms after sending this
    
    int8_t baudCode;
    
    //supported baud rates and associated baud command codes
    switch(baudRate)
    {
        case 300:
            baudCode = 0;
            break;
        case 600:
            baudCode = 1;
            break;
        case 1200:
            baudCode = 2;
            break;
        case 2400:
            baudCode = 3;
            break;
        case 4800:
            baudCode = 4;
            break;
        case 9600:
            baudCode = 5;
            break;
        case 14400:
            baudCode = 6;
            break;
        case 19200:
            baudCode = 7;
            break;
        case 28800:
            baudCode = 8;
            break;
        case 38400:
            baudCode = 9;
            break;
        case 57600:
            baudCode = 10;
            break;
        case 115200:
            baudCode = 11;
            break;
        default:
            return FALSE; //unsopprted baud rate
    }
    
    int8_t commandByteArray[] = {ROOMBCMD_BAUD, baudCode};
    return [self sendRoombaCommandBytes:&commandByteArray length:sizeof(commandByteArray)];
}

-(BOOL)sendControlCommand
{
	DLog(@"RoombaController sendControlCommand");
    
    //changes roomba mode from passive to safe
    
    int8_t commandByte = ROOMBCMD_CONTROL;
    return [self sendRoombaCommandBytes:&commandByte length:sizeof(commandByte)];
}

-(BOOL)sendSafeCommand
{
	DLog(@"RoombaController sendSafeCommand");
    
    //changes roomba mode from full to safe
    
    int8_t commandByte = ROOMBCMD_SAFE;
    return [self sendRoombaCommandBytes:&commandByte length:sizeof(commandByte)];
}

-(BOOL)sendFullCommand
{
	DLog(@"RoombaController sendFullCommand");
    
    //changes roomba mode from safe to full
    
    int8_t commandByte = ROOMBCMD_FULL;
    return [self sendRoombaCommandBytes:&commandByte length:sizeof(commandByte)];
}

-(BOOL)sendPowerCommand
{
	DLog(@"RoombaController sendPowerCommand");
    
    //puts the roomba to sleep
    
    int8_t commandByte = ROOMBCMD_POWER;
    return [self sendRoombaCommandBytes:&commandByte length:sizeof(commandByte)];
}

-(BOOL)sendSpotCommand
{
	DLog(@"RoombaController sendSpotCommand");
    
    //starts spot cleaning cycle
    
    int8_t commandByte = ROOMBCMD_SPOT;
    return [self sendRoombaCommandBytes:&commandByte length:sizeof(commandByte)];
}

-(BOOL)sendCleanCommand
{
	DLog(@"RoombaController sendCleanCommand");
    
    //starts regular cleaning cycle
    
    int8_t commandByte = ROOMBCMD_CLEAN;
    return [self sendRoombaCommandBytes:&commandByte length:sizeof(commandByte)];
}

-(BOOL)sendMaxCommand
{
	DLog(@"RoombaController sendMaxCommand");
    
    //starts max cleaning cycle
    
    int8_t commandByte = ROOMBCMD_MAX;
    return [self sendRoombaCommandBytes:&commandByte length:sizeof(commandByte)];
}

-(BOOL)sendDockCommand
{
	DLog(@"RoombaController sendDockCommand");
    
    //makes the roomba start looking for docking bay
    
    int8_t commandByte = ROOMBCMD_DOCK;
    return [self sendRoombaCommandBytes:&commandByte length:sizeof(commandByte)];
}

-(BOOL)sendSensorRequest
{
	DLog(@"RoombaController sendSensorRequest");
    
    //sends request for full sensor packet
    
    int8_t commandByteArray[] = {ROOMBCMD_SENSOR, 0x00};
    return [self sendRoombaCommandBytes:&commandByteArray length:sizeof(commandByteArray)];
}

-(BOOL)sendVacuumOnCommand
{
	DLog(@"RoombaController sendVacuumOnCommand");
    
    self.VacuumIsRunning = [NSNumber numberWithBool:YES];
    
    //turn on vacuum, main brush, side brush
    int8_t commandByteArray[] = {ROOMBCMD_MOTORS, 0x07};
    return [self sendRoombaCommandBytes:&commandByteArray length:sizeof(commandByteArray)];
}

-(BOOL)sendVacuumOffCommand
{
	DLog(@"RoombaController sendVacuumOffCommand");
    
    self.VacuumIsRunning = [NSNumber numberWithBool:NO];
    
    //turn off vacuum, main brush, side brush (ie all motors)
    int8_t commandByteArray[] = {ROOMBCMD_MOTORS, 0x00};
    return [self sendRoombaCommandBytes:&commandByteArray length:sizeof(commandByteArray)];
}

-(BOOL)sendDriveCommandwithVelocity:(NSInteger)velocity radius:(NSInteger)radius
{
	//DLog(@"RoombaController sendDriveCommandwithVelocity");

    self.currentVelocity = [NSNumber numberWithInteger:velocity];
    self.currentRadius = [NSNumber numberWithInteger:radius];
    
    int8_t commandByteArray[] = {   ROOMBCMD_DRIVE,
                                    (int8_t)(velocity >> 8),
                                    (int8_t)velocity,
                                    (int8_t)(radius >> 8),
                                    (int8_t)radius};
    
    return [self sendRoombaCommandBytes:&commandByteArray length:sizeof(commandByteArray)];
}

-(BOOL)driveStraightDistance:(NSNumber *)distanceMM
{
	DLog(@"RoombaController driveStraightDistance");
    
    CGFloat time = [distanceMM floatValue] / ROOMB_VELOCITY_MOVE;
    
    self.driveTimer = [NSTimer scheduledTimerWithTimeInterval:time target:self selector:@selector(driveStop) userInfo:nil repeats:NO];
    return [self sendDriveCommandwithVelocity:ROOMB_VELOCITY_MOVE radius:ROOMB_RADIUS_STRAIGT];
}

-(BOOL)driveTurnAngle:(NSNumber *)anngleRadians
{
	DLog(@"RoombaController driveTurnAngle");
    
    CGFloat time = ([anngleRadians floatValue] * (ROOMB_WHEELBASE/2)) / ROOMB_VELOCITY_MOVE;
    DLog(@"%f",time);
    
    self.driveTimer = [NSTimer scheduledTimerWithTimeInterval:time target:self selector:@selector(driveStop) userInfo:nil repeats:NO];
    return [self sendDriveCommandwithVelocity:ROOMB_VELOCITY_MOVE radius:ROOMB_RADIUS_SPIN];
}

-(BOOL)driveStop
{
	DLog(@"RoombaController driveStop");

    return [self sendDriveCommandwithVelocity:ROOMB_VELOCITY_STOPPED radius:ROOMB_RADIUS_STRAIGT];
}

-(void)forceDockSeeking
{
	DLog(@"RoombaController forceDockSeeking");
    
    //need to wait between changing roomba control states
    [self performSelector:@selector(sendSpotCommand) withObject:nil afterDelay:0.1];
    [self performSelector:@selector(sendDockCommand) withObject:nil afterDelay:0.2];
}

-(BOOL)sendRoombaCommandBytes:(void*)commandBytes length:(int)length
{
	//DLog(@"RoombaController sendRoombaCommandBytes");
    
    if(![ControllerIsRunning boolValue])
        return NO;
    
    NSMutableData *dataToSend = [[NSMutableData alloc] init];
    [dataToSend appendBytes:commandBytes length:length];
    return [wifiDongle sendData:dataToSend];
}

@end
