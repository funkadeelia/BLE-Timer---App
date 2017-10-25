//
//  TableViewController.m
//  SimpleControl
//
//  Created by Cheong on 7/11/12.
//  Copyright (c) 2012 RedBearLab. All rights reserved.
//

#import "TableViewController.h"

@interface TableViewController ()

@end

@implementation TableViewController

@synthesize ble;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    ble = [[BLE alloc] init];
    [ble controlSetup];
    ble.delegate = self;
    
    // ST - timer
    [self resetTimer];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - BLE delegate

NSTimer *rssiTimer;

- (void)bleDidDisconnect
{
    NSLog(@"->Disconnected");

    [btnConnect setTitle:@"Connect" forState:UIControlStateNormal];
    [indConnecting stopAnimating];
    
    swDigitalOut.enabled = false;
    
    // ST - timer btn
    btnStartTimer.enabled = false;
    
    
    [rssiTimer invalidate];
}

// When RSSI is changed, this will be called
-(void) bleDidUpdateRSSI:(NSNumber *) rssi
{
    
}

-(void) readRSSITimer:(NSTimer *)timer
{
    [ble readRSSI];
}

// When disconnected, this will be called
-(void) bleDidConnect
{
    NSLog(@"->Connected");

    [indConnecting stopAnimating];
    
    swDigitalOut.enabled = true;
    
    swDigitalOut.on = false;
    
    // ST - timer
    btnStartTimer.enabled = true;
    
    // send reset
    UInt8 buf[] = {0x04, 0x00, 0x00};
    NSData *data = [[NSData alloc] initWithBytes:buf length:3];
    [ble write:data];

    // Schedule to read RSSI every 1 sec.
    rssiTimer = [NSTimer scheduledTimerWithTimeInterval:(float)1.0 target:self selector:@selector(readRSSITimer:) userInfo:nil repeats:YES];
}

// ST - Analogue info
// When data is comming, this will be called
-(void) bleDidReceiveData:(unsigned char *)data length:(int)length
{
    NSLog(@"Length: %d", length);

    // parse data, all commands are in 3-byte
    for (int i = 0; i < length; i+=3)
    {
        NSLog(@"0x%02X, 0x%02X, 0x%02X", data[i], data[i+1], data[i+2]);

        if (data[i] == 0x0A)
            // 0A - this means digital input is triggered
        {
            if(data[i+1] == 0x01)
            {
                // if button is pressed (i.e. HIGH) then trigger device btn press function
                [self deviceBtnPress];
                // app read out for testing
                btnStateLabel.text = @"High";
            }
            else
            {
                // app read out for testing
                btnStateLabel.text = @"Low";
            }
        }
        else if (data[i] == 0x0B)
            // 0B - this means analogue input is triggered
        {
            
            // UInt16 Value;
            
            
        }        
    }
}

#pragma mark - Actions

// Connect button will call to this
- (IBAction)btnScanForPeripherals:(id)sender
{
    if (ble.activePeripheral)
        if(ble.activePeripheral.state == CBPeripheralStateConnected)
        {
            [[ble CM] cancelPeripheralConnection:[ble activePeripheral]];
            [btnConnect setTitle:@"Connect" forState:UIControlStateNormal];
            return;
        }
    
    if (ble.peripherals)
        ble.peripherals = nil;
    
    [btnConnect setEnabled:false];
    [ble findBLEPeripherals:2];
    
    [NSTimer scheduledTimerWithTimeInterval:(float)2.0 target:self selector:@selector(connectionTimer:) userInfo:nil repeats:NO];
    
    [indConnecting startAnimating];
}

-(void) connectionTimer:(NSTimer *)timer
{
    [btnConnect setEnabled:true];
    [btnConnect setTitle:@"Disconnect" forState:UIControlStateNormal];
    
    if (ble.peripherals.count > 0)
    {
        [ble connectPeripheral:[ble.peripherals objectAtIndex:0]];
    }
    else
    {
        [btnConnect setTitle:@"Connect" forState:UIControlStateNormal];
        [indConnecting stopAnimating];
    }
}

-(IBAction)sendDigitalOut:(id)sender
{
    UInt8 buf[3] = {0x01, 0x00, 0x00};
    
    if (swDigitalOut.on)
        buf[1] = 0x01;
    else
        buf[1] = 0x00;
    
    NSData *data = [[NSData alloc] initWithBytes:buf length:3];
    [ble write:data];
}


/* Send command to Arduino to enable analog reading */
-(IBAction)sendAnalogIn:(id)sender
{
    UInt8 buf[3] = {0xA0, 0x00, 0x00};
    
    
    
    NSData *data = [[NSData alloc] initWithBytes:buf length:3];
    [ble write:data];
}


// --------------------- ST ---------------------- //

// ST - Timer functions
- (void)resetTimer
{
    // sets initial length of timer (5 seconds)
    intseconds = 5;
    lblTime.text = [NSString stringWithFormat:@"Time: %li", (long)intseconds];
    
    // rest all timer buttons
    btnStartTimer.enabled = true;
    btnPauseTimer.enabled = false;
    btnAddTime.enabled = false;
    
    // turn off the LED
    // ST - turn off LED
    // send data to arduino
    UInt8 buf[3] = {0x01, 0x00, 0x00};
    buf[1] = 0x00;
    NSData *data = [[NSData alloc] initWithBytes:buf length:3];
    [ble write:data];
}

- (void)startTimer
{
    btnStartTimer.enabled = false;
    btnPauseTimer.enabled = true;
    btnAddTime.enabled = true;
    
    
    lblTime.text = [NSString stringWithFormat:@"Time: %li", (long)intseconds];
  
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                             target:self
                                           selector:@selector(subtractTime)
                                           userInfo:nil
                                            repeats:YES];
}

// funciton to handle device button is pressed
- (void)deviceBtnPress
{
    // if timer isn't running then start timer
    if (!timer.isValid && intseconds > 0) {
        
        [self startTimer];
        NSLog(@"Starting Timer");
        
    } else if (timerAlert == self.presentedViewController) {
        // dismiss the alert if it's showing & reset the timer
        NSLog(@"Restarting Timer & dismissing Alert");
        [timerAlert dismissViewControllerAnimated:YES completion: nil];
        [self resetTimer];
    }
}

- (void)subtractTime
{
    intseconds--;
    lblTime.text = [NSString stringWithFormat:@"Time: %li",(long)intseconds];
    if (intseconds == 0)
    {
        // stop timer
        [timer invalidate];
        
        [self showAlert];
        
        
        // ST - turn on LED
        // send data to arduino
        UInt8 buf[3] = {0x01, 0x00, 0x00};
        buf[1] = 0x01;
        NSData *data = [[NSData alloc] initWithBytes:buf length:3];
        [ble write:data];
        
    }
}

// timer end alert
- (void)showAlert
{
    // trigger alert
    timerAlert = [UIAlertController alertControllerWithTitle:@"Time is up" message:@"Your timer has finished." preferredStyle:UIAlertControllerStyleAlert];
    
    // craete action to handle alert in UI
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                               {
                                   // actions
                                   [self resetTimer];
                                   NSLog(@"OK");
                               }];
    
    // attache action to alert
    [timerAlert addAction:okAction];
    
    // display alert
    [self presentViewController:timerAlert animated: YES completion: nil];
}

// ST - start timer
- (IBAction)btnStartTimer:(UIButton *)sender {
    
    [self startTimer];
    
}


- (IBAction)btnPauseTimer:(UIButton *)sender {
    
    btnStartTimer.enabled = true;
    btnPauseTimer.enabled = false;
    btnAddTime.enabled = false;
    
    
    [timer invalidate];
    
}

- (IBAction)btnAddTime:(UIButton *)sender {
    
    [timer invalidate];
    
    // add amount of time to timer
    intseconds = intseconds + 2;
    
    [self startTimer];
    
}

// --------------- Questions / Thoughts ------------- //
/*
 
 Where do I handle flashing the LED / signaling on the device? Is it managed in the app code or the arduino code? eg. In the app do I say "Led on... Led off" or do I send a command to he arduino saying "Time up" and then handle the flashing in the arduino?
 
 How do I get button presses in from the arduino to the app? Eg the "Start" trigger (and potentially pause) will need to be triggered from the arduino.
 
 Should I get all this code (xcode & arduino code) up into github to take advantage of version control etc?
 
 */

@end
