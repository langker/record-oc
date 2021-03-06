//
//  ViewController.m
//  record-oc
//
//  Created by langker on 16/5/21.
//  Copyright © 2016年 langker. All rights reserved.
//

#import "ViewController.h"
#import "RecorderManager.h"
#import "PlayerManager.h"
#import "SCSiriWaveformView.h"

@interface ViewController () <RecordingDelegate, PlayingDelegate>
@property (nonatomic, copy) NSString *filename;
@property (nonatomic, assign) BOOL isRecording;
@property (nonatomic, assign) BOOL isPlaying;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UILabel *timerOfPlaying;

@end

SCSiriWaveformView *waveformView;
NSTimeInterval fileTime;
NSInteger currentPlaySecond;
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initWaveFormView];
    self.isRecording = NO;
    self.isPlaying = NO;
    [RecorderManager sharedManager].delegate = self;
    [PlayerManager sharedManager].delegate = self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTimeLabel:) name:@"updateCurrentTime" object:nil];
    
    currentPlaySecond = 0;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
- (IBAction)record:(id)sender {
    if (self.isRecording) {
        [[RecorderManager sharedManager] stopRecording];
        [self.recordButton setTitle:@"record" forState:UIControlStateNormal];
        [self.playButton setEnabled:true];
    } else {
        [[RecorderManager sharedManager] startRecording];
        [self.recordButton setTitle:@"stop" forState:UIControlStateNormal];
        [self.playButton setEnabled:false];
    }
    self.isRecording = !self.isRecording;
}
- (IBAction)stop:(id)sender {
    [[PlayerManager sharedManager] stopPlaying];
    [self.recordButton setEnabled:true];
    [self.playButton setTitle:@"play" forState:UIControlStateNormal];
}
- (IBAction)play:(id)sender {
    if (self.isPlaying) {
        [[PlayerManager sharedManager] pausePlaying];
        [self.playButton setTitle:@"play" forState:UIControlStateNormal];
        [self.recordButton setEnabled:true];
        self.timerOfPlaying.text = @"";
    } else {
        if (currentPlaySecond==0) {
            [[PlayerManager sharedManager] playAudioWithFileName:self.filename delegate:self];
        } else {
            [[PlayerManager sharedManager] continuePlaying];
        }
        [self.playButton setTitle:@"pause" forState:UIControlStateNormal];
        [self.recordButton setEnabled:false];
    }
    self.isPlaying = !self.isPlaying;
}
-(void)initWaveFormView {
    waveformView = [[SCSiriWaveformView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 100)];
    waveformView.waveColor = [UIColor whiteColor];
    waveformView.primaryWaveLineWidth = 3.0;
    waveformView.secondaryWaveLineWidth = 1.0;
    [self.view addSubview:waveformView];
}
#pragma mark - Recording & Playing Delegate

- (void)recordingFinishedWithFileName:(NSString *)filePath time:(NSTimeInterval)interval {
    self.isRecording = NO;
    self.filename = filePath;
    fileTime = interval;
}

- (void)recordingTimeout {
    self.isRecording = NO;
}

- (void)recordingStopped {
    self.isRecording = NO;
}

- (void)recordingFailed:(NSString *)failureInfoString {
    self.isRecording = NO;
}

- (void)levelMeterChanged:(float)levelMeter {
    [waveformView updateWithLevel:levelMeter];
}

- (void)playingStoped {
    self.isPlaying = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.playButton setTitle:@"play" forState:UIControlStateNormal];
        [self.recordButton setEnabled:true];
        self.timerOfPlaying.text = @"";
    });
}

#pragma mark - notify callback

-(void)updateTimeLabel:(NSNotification *)text {
    currentPlaySecond = [text.userInfo[@"currentTime"] intValue];
    self.timerOfPlaying.text = [NSString stringWithFormat:@"00:%.2ld/00:%.2d",(long)currentPlaySecond,(int)fileTime];
}
@end
