//
//  AppDelegate.h
//  Graphics_8
//
//

#import <Cocoa/Cocoa.h>

typedef enum : NSUInteger {
    Pixelate,
    Monocolour,
    Guro,
    Phonge
} LightingType;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, strong) NSColor * color_spread;
@property (nonatomic) double intensity_spread;

@property (nonatomic, strong) NSColor * color_focused_1;
@property (nonatomic) double intensity_focused_1;
@property (nonatomic) double x_focused_1;
@property (nonatomic) double y_focused_1;
@property (nonatomic) double z_focused_1;

@property (nonatomic, strong) NSColor * color_focused_2;
@property (nonatomic) double intensity_focused_2;
@property (nonatomic) double x_focused_2;
@property (nonatomic) double y_focused_2;
@property (nonatomic) double z_focused_2;

@property (nonatomic, strong) NSColor * color_figure;
@property (nonatomic) double k_reflect;
@property (nonatomic) double k_losk;

@property (nonatomic, weak) NSArray * lightingTypeNames;

@property (nonatomic) LightingType lightingType;

@property (nonatomic, weak) IBOutlet NSImageView * scene;

@property (nonatomic) double turnOx;
@property (nonatomic) double turnOy;

@property (nonatomic, weak) IBOutlet NSWindow * figHUD;
@property (nonatomic, weak) IBOutlet NSWindow * lightHUD;

@end

