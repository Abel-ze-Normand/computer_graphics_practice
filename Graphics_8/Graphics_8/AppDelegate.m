//
//  AppDelegate.m
//  Graphics_8
//
//

#import "AppDelegate.h"
#import "Figure.h"

#define SCENE_WIDTH 600.f
#define SCENE_HEIGHT 600.f
#define SCENE_BORDER 50

#define D 1

#define R_OUT 7.f
#define R_IN 3.f

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (nonatomic, strong) Figure * figure;

@end

@implementation AppDelegate

@synthesize color_spread = _color_spread;
@synthesize intensity_spread = _intensity_spread;
@synthesize color_focused_1 = _color_focused_1;
@synthesize intensity_focused_1 = _intensity_focused_1;
@synthesize x_focused_1 = _x_focused_1;
@synthesize y_focused_1 = _y_focused_1;
@synthesize z_focused_1 = _z_focused_1;
@synthesize color_focused_2 = _color_focused_2;
@synthesize intensity_focused_2 = _intensity_focused_2;
@synthesize x_focused_2 = _x_focused_2;
@synthesize y_focused_2 = _y_focused_2;
@synthesize z_focused_2 = _z_focused_2;
@synthesize k_reflect = _k_reflect;
@synthesize k_losk = _k_losk;
@synthesize color_figure = _color_figure;

@synthesize lightingType = _lightingType;

@synthesize turnOx = _turnOx;
@synthesize turnOy = _turnOy;

@dynamic lightingTypeNames;

- (NSArray *)lightingTypeNames{
    
    return @[ @"поточечный", @"однотонный", @"Гуро", @"Фонга"];
    
}

- (NSArray *)viewerPos{ return @[ @0., @0., @1.]; }

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    self.color_spread = self.color_focused_1 = self.color_focused_2 = [NSColor colorWithCalibratedRed:1
                                                                                                green:1
                                                                                                 blue:1
                                                                                                alpha:1.0];
    self.color_figure = [NSColor colorWithCalibratedRed:1
                                                  green:1
                                                   blue:1
                                                  alpha:1];
    
    self.intensity_spread = self.intensity_focused_1 = self.intensity_focused_2 = 0.5;
    self.x_focused_1 = self.x_focused_2 = 1;
    self.z_focused_1 = self.z_focused_2 = 1;
    self.y_focused_1 = -1; self.y_focused_2 = 1;
    
    self.k_reflect = 0.5;
    self.k_losk = 1;
    
    self.lightingType = Pixelate;
}

- (IBAction)redraw:(id)sender{
    
    [self.figHUD endEditingFor:self];
    [self.lightHUD endEditingFor:self];
    
    if (!self.figure) return;
    else {
        switch (self.lightingType) {
            case Pixelate:
                self.scene.image = [self analogRender];
                break;
            case Phonge:
                self.scene.image = [self phongRender];
                break;
            case Monocolour:
                self.scene.image = [self monocolourRender];
                break;
            case Guro:
                self.scene.image = [self guroRender];
                break;
            default:
                break;
        }
    }
    
}

- (IBAction)loadFigureFromFile:(id)sender{
    
    NSOpenPanel * panel = [[NSOpenPanel alloc] init];
    panel.canChooseFiles = YES;
    panel.canChooseDirectories = NO;
    panel.allowedFileTypes = @[@"txt"];

    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK) {
            self.figure = [Figure initFormFile:panel.URL];
            [self redraw:self];
        }
    }];
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

double mult(NSArray * a, NSArray * b){
    
    double result = 0;
    for (int i = 0; i < a.count; i++) result += [a[i] doubleValue]*[b[i] doubleValue];
    return result;
    
}

double norm(NSArray * a){
    
    return sqrt(mult(a, a));
    
}

NSArray * interpolate_equally(NSArray *a, NSArray *b, NSArray *c){
    
    return @[ @(([a[0] doubleValue] + [b[0] doubleValue] + [c[0] doubleValue])/3),
              @(([a[1] doubleValue] + [b[1] doubleValue] + [c[1] doubleValue])/3),
              @(([a[2] doubleValue] + [b[2] doubleValue] + [c[2] doubleValue])/3)];
    
}

- (NSColor *)calculateColorWithNormal:(NSArray *)normal l1Pos:(NSArray *)l1pos l2Pos:(NSArray *)l2pos viewerPos:(NSArray *)viewerPos{
    
    double ln1 = mult(l1pos, normal)/norm(l1pos)/norm(normal);
    double ln2 = mult(l2pos, normal)/norm(l2pos)/norm(normal);
    
    l1pos = mult_a(l1pos, 1/norm(l1pos));
    l2pos = mult_a(l2pos, 1/norm(l2pos));
    ///norm(l1pos)/norm(normal);
    ///norm(l2pos)/norm(normal);
    
    NSArray * r1 = @[ @(2*[normal[0] doubleValue]*ln1 - [l1pos[0] doubleValue]),
                      @(2*[normal[1] doubleValue]*ln1 - [l1pos[1] doubleValue]),
                      @(2*[normal[2] doubleValue]*ln1 - [l1pos[2] doubleValue])];
   // NSLog(@"%@",r1);
    double cos_alpha1 = mult(r1, viewerPos)/norm(r1)/norm(viewerPos);

    NSArray * r2 = @[ @(2*[normal[0] doubleValue]*ln2 - [l2pos[0] doubleValue]),
                      @(2*[normal[1] doubleValue]*ln2 - [l2pos[1] doubleValue]),
                      @(2*[normal[2] doubleValue]*ln2 - [l2pos[2] doubleValue])];
   // NSLog(@"%@",r2);
    double cos_alpha2 = mult(r2, viewerPos)/norm(r2)/norm(viewerPos);
    
    double cos_tetha1 = ln1;
    double cos_tetha2 = ln2;

//    NSLog(@" cos_th1 = %lf, cos_th2 = %lf, cos_alp2 = %lf, cos_alp2 = %lf",
//          cos_tetha1,
//          cos_tetha2,
//          cos_alpha1,
//          cos_tetha2);
    
    double r = calculateIntensity(self.color_spread.redComponent * self.intensity_spread, // Ia_r
                                  self.color_figure.redComponent, //Kd_r, Ka_r
                                  self.color_focused_1.redComponent * self.intensity_focused_1,// I_li1_r
                                  self.color_focused_2.redComponent * self.intensity_focused_2,// I_li2_r
                                  cos_tetha1,
                                  cos_tetha2,
                                  cos_alpha1,
                                  cos_alpha2,
                                  self.k_reflect, //Ks
                                  self.k_losk); //n
    double g = calculateIntensity(self.color_spread.greenComponent * self.intensity_spread,
                                  self.color_figure.greenComponent,
                                  self.color_focused_1.greenComponent * self.intensity_focused_1,
                                  self.color_focused_2.greenComponent * self.intensity_focused_2,
                                  cos_tetha1,
                                  cos_tetha2,
                                  cos_alpha1,
                                  cos_alpha2, self.k_reflect, self.k_losk);
    double b = calculateIntensity(self.color_spread.blueComponent * self.intensity_spread,
                                  self.color_figure.blueComponent,
                                  self.color_focused_1.blueComponent * self.intensity_focused_1,
                                  self.color_focused_2.blueComponent * self.intensity_focused_2,
                                  cos_tetha1,
                                  cos_tetha2,
                                  cos_alpha1,
                                  cos_alpha2, self.k_reflect, self.k_losk);
   // NSLog(@"%lf %lf %lf",r,g,b);
    return [NSColor colorWithCalibratedRed:r
                                     green:g
                                      blue:b
                                     alpha:1.0];
    
    
}

double calculateIntensity(double Ia, double Ka, double I1, double I2, double cos_Tetha1, double cos_Tetha2, double cos_alpha1, double cos_alpha2, double Kl, double n){
    
    // NSLog(@"%lf %lf",cos_Tetha1, cos_Tetha2);
  //  NSLog(@"%lf %lf",cos_alpha1, cos_alpha2);
    
    cos_Tetha1 = cos_Tetha1 < 0 || isnan(cos_Tetha1) ? 0 : cos_Tetha1;
    cos_Tetha2 = cos_Tetha2 < 0 || isnan(cos_Tetha2) ? 0 : cos_Tetha2;

    cos_alpha1 = cos_alpha1 < 0 || isnan(cos_alpha1) ? 0 : cos_alpha1;
    cos_alpha2 = cos_alpha2 < 0 || isnan(cos_alpha2) ? 0 : cos_alpha2;
    
    double result = Ia*Ka + I1*(Ka*cos_Tetha1 + Kl*pow(cos_alpha1, n)) + I2*(Ka*cos_Tetha2 + Kl*pow(cos_alpha2, n));
    return result > 1 ? 1 : result;
    
}

CGPoint project(Vertex * v, size_t height, size_t width, Figure * fig){
    
    CGFloat x = (int)((width - 2*SCENE_BORDER)/(fig.maxX - fig.minX)*(v.x - fig.minX) + SCENE_BORDER);
    CGFloat y = (int)((height - 2*SCENE_BORDER)/(fig.maxY - fig.minY)*(v.y - fig.minY) + SCENE_BORDER);
    return CGPointMake(x, y);
    
}

CGPoint projectBack(size_t height, size_t width, Figure * fig, int x, int y){
    
    double old_x = (double)(fig.maxX - fig.minX)/(width - 2*SCENE_BORDER)*(x - SCENE_BORDER) + fig.minX;
    double old_y = (double)(fig.maxY - fig.minY)/(height - 2*SCENE_BORDER)*(y - SCENE_BORDER) + fig.minY;
    return CGPointMake(old_x, old_y);
    
}

double dotOnLine(CGPoint a, CGPoint b, double y){
    
    return (y - a.y)/(b.y - a.y)*(b.x - a.x) + a.x;//(x - a.x)/(b.x - a.x)*(b.y-a.y) + a.y;
    
}

void swap(Vertex ** p1, Vertex ** p2){
    
    Vertex * temp = *p2;
    *p2 = *p1;
    *p1 = temp;
    
}

void sortByY(NSArray *p){

    [p sortedArrayUsingComparator:^NSComparisonResult(Vertex * obj1, Vertex * obj2) {
        if (obj1.y < obj2.y) return NSOrderedAscending;
        else if(obj1.y > obj2.y) return NSOrderedDescending;
        else return NSOrderedSame;
    }];

}

NSArray * substr(NSArray * a, NSArray * b){
    return @[ @([a[0] doubleValue] - [b[0] doubleValue]),
              @([a[1] doubleValue] - [b[1] doubleValue]),
              @([a[2] doubleValue] - [b[2] doubleValue])];
}

NSArray * plus(NSArray * a, NSArray * b){
    return @[ @([a[0] doubleValue] + [b[0] doubleValue]),
              @([a[1] doubleValue] + [b[1] doubleValue]),
              @([a[2] doubleValue] + [b[2] doubleValue])];
}

NSArray * mult_a(NSArray * a, double b){
    
    return @[ @([a[0] doubleValue]*b),
              @([a[1] doubleValue]*b),
              @([a[2] doubleValue]*b)];
    
}

NSArray * interpolateNormal(CGPoint a, CGPoint b, CGPoint c, CGPoint x, NSArray * an, NSArray *bn, NSArray * cn){

    /*
    (C.x - V1.x) = (V2.x - V1.x) * m2 + (V3.x - V1.x)* m3;
    (C.y - V1.y) = (V2.y - V1.y) * m2 + (V3.y - V1.y)* m3;
    */
    double m3 = (-(x.x - a.x)*(b.y - a.y) + (b.x - a.x)*(x.y - a.y))/((c.y - a.y)*(b.x - a.x) - (c.x - a.x)*(b.y - a.y));
    double m2 = (-(x.x - a.x)*(c.y - a.y) + (c.x - a.x)*(x.y - a.y))/((b.y - a.y)*(c.x - a.x) - (b.x - a.x)*(c.y - a.y));
    double m1 =  1 - m2 - m3;
    
   // NSLog(@" %lf %lf %lf",m1,m2,m3);
    
//    if(m1 < 0 || m1 > 1|| m2 < 0 || m2 > 1 || m3 < 0 || m3 > 1) {
//        NSLog(@" (%d,%d), (%d,%d) (%d,%d)",(int)a.x,(int)a.y,(int)b.x,(int)b.y,(int)c.x,(int)c.y);
//        NSLog(@" (%d,%d)",(int)x.x, (int)x.y);
//        NSLog(@" %lf %lf %lf",m1,m2,m3);
//        return nil;
//    }
    return @[ @([an[0] doubleValue]*m1 + [bn[0] doubleValue]*m2 + [cn[0] doubleValue]*m3),
              @([an[1] doubleValue]*m1 + [bn[1] doubleValue]*m2 + [cn[1] doubleValue]*m3),
              @([an[2] doubleValue]*m1 + [bn[2] doubleValue]*m2 + [cn[2] doubleValue]*m3)];
    
}

Vertex * interpolateVertex(Vertex * a_o, Vertex * b_o, Vertex * c_o, CGPoint a, CGPoint b, CGPoint c, CGPoint x){
    
    double m3 = (-(x.x - a.x)*(b.y - a.y) + (b.x - a.x)*(x.y - a.y))/((c.y - a.y)*(b.x - a.x) - (c.x - a.x)*(b.y - a.y));
    double m2 = (-(x.x - a.x)*(c.y - a.y) + (c.x - a.x)*(x.y - a.y))/((b.y - a.y)*(c.x - a.x) - (b.x - a.x)*(c.y - a.y));
    double m1 = 1 - m2 - m3;
    
    //if (m1 < 0 || m1 > 1|| m2 < 0 || m2 > 1 || m3 < 0 || m3 > 1) return nil;
    return[Vertex initWithX:a_o.x * m1 + b_o.x * m2 + c_o.x * m3
                          Y:a_o.y * m1 + b_o.y * m2 + c_o.y * m3
                          Z:a_o.z * m1 + b_o.z * m2 + c_o.z * m3 normal:nil];
    
}

NSArray * crossProduct(NSArray * a, NSArray * b){
    
    return @[
             @([a[1] doubleValue]*[b[2] doubleValue] - [a[2] doubleValue]*[b[1] doubleValue]),
             @([a[2] doubleValue]*[b[0] doubleValue] - [a[0] doubleValue]*[b[2] doubleValue]),
             @([a[0] doubleValue]*[b[1] doubleValue] - [a[1] doubleValue]*[b[0] doubleValue])
             ];
    
}

CGImageRef CGImageCreateWithNSImage(NSImage *image) {
    NSSize imageSize = [image size];
    
    CGContextRef bitmapContext = CGBitmapContextCreate(NULL, imageSize.width, imageSize.height, 8, 0, [[NSColorSpace genericRGBColorSpace] CGColorSpace], kCGBitmapByteOrder32Host|kCGImageAlphaPremultipliedFirst);
    
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:bitmapContext flipped:NO]];
    [image drawInRect:NSMakeRect(0, 0, imageSize.width, imageSize.height) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
    [NSGraphicsContext restoreGraphicsState];
    
    CGImageRef cgImage = CGBitmapContextCreateImage(bitmapContext);
    CGContextRelease(bitmapContext);
    return cgImage;
}


CGPoint uv(double R, double r, CGPoint p){
    
    double v = atan(p.y/p.x);
    if (p.x < 0) {
        if (p.y < 0) v += M_PI;
        else v += M_PI;
    } else {
        if (p.y < 0) v += 2*M_PI;
    }
    
   // NSLog(@"%lf",v / M_PI * 180);
    
    double u = 0;
    if ( fabs(cos(v)) < 0.0001 ) {
        u = acos((p.y/sin(v) - R)/r);
      //  NSLog(@"%lf %lf %lf", v / M_PI * 180, u / M_PI * 180, p.y);
    }
    else u = acos((p.x/cos(v) - R)/r);
    return CGPointMake(u, v);
    
}

BOOL onTor(CGPoint p){
    
    return (p.x*p.x + p.y*p.y <= R_OUT*R_OUT) && (p.x*p.x + p.y*p.y >= R_IN*R_IN);
    
}

double tor_x(double R, double r, double u, double v){ return (R + r*cos(u))*cos(v); }
double tor_y(double R, double r, double u, double v){ return (R + r*cos(u))*sin(v); }
double tor_z(double R, double r, double u, double v){ return r*sin(u); }

NSArray * tor_normal(double R, double r, double u, double v){
    
    return @[@((- R*cos(v) + tor_x(R, r, u, v))),
             @((- R*sin(v) + tor_y(R, r, u, v))),
             @(tor_z(R, r, u, v))];
    
}

- (NSImage *)analogRender{
    
    NSImage *result = [[NSImage alloc] initWithSize:CGSizeMake(SCENE_WIDTH, SCENE_HEIGHT)];
    
    CGImageRef dest = CGImageCreateWithNSImage(result);
    NSBitmapImageRep * rep_dest = [[NSBitmapImageRep alloc] initWithCGImage:dest];
    
    size_t height = rep_dest.pixelsHigh;
    size_t width = rep_dest.pixelsWide;
    
    for (int i = 0; i < width; i++) {
        for (int j = 0; j < height; j++) {
            CGPoint local_coords = projectBack(height, width, self.figure, i, j);
            if (!onTor(local_coords)) continue;
            
            CGPoint u_v = uv(R_IN + (R_OUT - R_IN)/2,(R_OUT - R_IN) / 2,local_coords);
            NSArray *n = tor_normal(R_IN + (R_OUT - R_IN)/2,(R_OUT - R_IN) / 2, u_v.x, u_v.y);
            n = mult_a(n, 1/norm(n));
            
            NSArray *a_light_pos = @[ @(self.x_focused_1 - tor_x(R_OUT, R_IN, u_v.x, u_v.y)),
                                      @(-self.y_focused_1 - tor_y(R_OUT, R_IN, u_v.x, u_v.y)),
                                      @(self.z_focused_1 - tor_z(R_OUT, R_IN, u_v.x, u_v.y))];
            NSArray *b_light_pos = @[ @(self.x_focused_2 - tor_x(R_OUT, R_IN, u_v.x, u_v.y)),
                                      @(-self.y_focused_2 - tor_y(R_OUT, R_IN, u_v.x, u_v.y)),
                                      @(self.z_focused_2 - tor_z(R_OUT, R_IN, u_v.x, u_v.y))];
            
            [rep_dest setColor:[self calculateColorWithNormal:n
                                                        l1Pos:a_light_pos
                                                        l2Pos:b_light_pos
                                                    viewerPos:[self viewerPos]]
                           atX:i y:j];
            
            
        }
    }
    
    [result addRepresentation:rep_dest];
    
    CGImageRelease(dest);
    
    return result;
    
}

- (NSImage *)monocolourRender{
    
    NSImage *result = [[NSImage alloc] initWithSize:CGSizeMake(SCENE_WIDTH, SCENE_HEIGHT)];
    
    CGImageRef dest = CGImageCreateWithNSImage(result);
    NSBitmapImageRep * rep_dest = [[NSBitmapImageRep alloc] initWithCGImage:dest];
    
    size_t height = rep_dest.pixelsHigh;
    size_t width = rep_dest.pixelsWide;
    
    for (Poly *p in self.figure.polygons) {
        
        // if (((Vertex *)p.vertices[0]).z < 0 || ((Vertex *)p.vertices[1]).z < 0 || ((Vertex *)p.vertices[2]).z < 0) continue;
        
        p.vertices = [p.vertices sortedArrayUsingComparator:^NSComparisonResult(Vertex * obj1, Vertex * obj2) {
            if (obj1.y < obj2.y) return NSOrderedAscending;
            else if(obj1.y > obj2.y) return NSOrderedDescending;
            else return NSOrderedSame;
        }];
        
        CGPoint * vertices = (CGPoint *)malloc(sizeof(CGPoint) * 3);
        
        vertices[0] = project(p.vertices[0], height, width, self.figure);
        vertices[1] = project(p.vertices[1], height, width, self.figure);
        vertices[2] = project(p.vertices[2], height, width, self.figure);
        
        Vertex * intervertex = [Vertex initWithX:((Vertex *)p.vertices[0]).x / 3 + ((Vertex *)p.vertices[1]).x / 3 + ((Vertex *)p.vertices[2]).x / 3
                                               Y:((Vertex *)p.vertices[0]).y / 3 + ((Vertex *)p.vertices[1]).y / 3 + ((Vertex *)p.vertices[2]).y / 3
                                               Z:((Vertex *)p.vertices[0]).z / 3 + ((Vertex *)p.vertices[1]).z / 3 + ((Vertex *)p.vertices[2]).z / 3
                                          normal:nil];
        
        NSArray *a_light_pos = @[ @(self.x_focused_1 - intervertex.x),
                                  @(-self.y_focused_1 - intervertex.y),
                                  @(self.z_focused_1 - intervertex.z)];
        NSArray *b_light_pos = @[ @(self.x_focused_2 - intervertex.x),
                                  @(-self.y_focused_2 - intervertex.y),
                                  @(self.z_focused_2 - intervertex.z)];
        
        NSArray * int_n = interpolate_equally(((Vertex *)p.vertices[0]).normal,
                                              ((Vertex *)p.vertices[1]).normal,
                                              ((Vertex *)p.vertices[2]).normal);
        
        if ( !int_n || mult(int_n, [self viewerPos]) < 0) continue;
        
        NSColor * col = [self calculateColorWithNormal:int_n
                                                 l1Pos:a_light_pos
                                                 l2Pos:b_light_pos
                                             viewerPos:[self viewerPos]];
        
        for (int i = vertices[0].y; i < (int)vertices[1].y; i++) {
            
            int lPoint = dotOnLine(vertices[0], vertices[1], i);
            int rPoint = dotOnLine(vertices[0], vertices[2], i);
            
            int left = fmin(lPoint, rPoint);
            int right = fmax(lPoint, rPoint);
            
            for (int j = left; j <= right; j++) {
                
                [rep_dest setColor:col
                               atX:j y:i];
            }
        }
        for (int i = vertices[1].y; i < (int)vertices[2].y; i++){
            
            int lPoint = dotOnLine(vertices[1], vertices[2], i);
            int rPoint = dotOnLine(vertices[0], vertices[2], i);
            
            int left = fmin(lPoint, rPoint);
            int right = fmax(lPoint, rPoint);
            
            for (int j = left; j <= right; j++) {

                [rep_dest setColor:col
                               atX:j y:i];
            }
        }
        free(vertices);
    }
    
    [result addRepresentation:rep_dest];
    
    CGImageRelease(dest);
    
    return result;
    
}

- (NSImage *)phongRender{
    
    //if (self.turnOx != 0.0) [self.figure turnByOx:self.turnOx];
    
    NSImage *result = [[NSImage alloc] initWithSize:CGSizeMake(SCENE_WIDTH, SCENE_HEIGHT)];
    
    CGImageRef dest = CGImageCreateWithNSImage(result);
    NSBitmapImageRep * rep_dest = [[NSBitmapImageRep alloc] initWithCGImage:dest];
    
    size_t height = rep_dest.pixelsHigh;
    size_t width = rep_dest.pixelsWide;
    
    //    double a_len = sqrt(self.x_focused_1*self.x_focused_1 + self.y_focused_1*self.y_focused_1 + self.z_focused_1*self.z_focused_1);
    //    double b_len = sqrt(self.x_focused_2*self.x_focused_2 + self.y_focused_2*self.y_focused_2 + self.z_focused_2*self.z_focused_2);
//    NSArray *a_light_pos = @[ @(self.x_focused_1),
//                              @(-self.y_focused_1),
//                              @(self.z_focused_1)];
//    NSArray *b_light_pos = @[ @(self.x_focused_2),
//                              @(-self.y_focused_2),
//                              @(self.z_focused_2)];
    for (Poly *p in self.figure.polygons) {
        
        // if (((Vertex *)p.vertices[0]).z < 0 || ((Vertex *)p.vertices[1]).z < 0 || ((Vertex *)p.vertices[2]).z < 0) continue;
        
        p.vertices = [p.vertices sortedArrayUsingComparator:^NSComparisonResult(Vertex * obj1, Vertex * obj2) {
            if (obj1.y < obj2.y) return NSOrderedAscending;
            else if(obj1.y > obj2.y) return NSOrderedDescending;
            else return NSOrderedSame;
        }];
        
        CGPoint * vertices = (CGPoint *)malloc(sizeof(CGPoint) * 3);
        
        vertices[0] = project(p.vertices[0], height, width, self.figure);
        vertices[1] = project(p.vertices[1], height, width, self.figure);
        vertices[2] = project(p.vertices[2], height, width, self.figure);
        
        for (int i = vertices[0].y; i < (int)vertices[1].y; i++) {
            
            int lPoint = dotOnLine(vertices[0], vertices[1], i);
            int rPoint = dotOnLine(vertices[0], vertices[2], i);
            
            int left = fmin(lPoint, rPoint);
            int right = fmax(lPoint, rPoint);
            
            for (int j = left + 1; j <= right; j++) {
            
                Vertex * interVertex = interpolateVertex(p.vertices[0],
                                                         p.vertices[1],
                                                         p.vertices[2],
                                                         vertices[0],
                                                         vertices[1],
                                                         vertices[2], CGPointMake(j,i));
                
                NSArray *a_light_pos = @[ @(self.x_focused_1 - interVertex.x),
                                          @(-self.y_focused_1 - interVertex.y),
                                          @(self.z_focused_1 - interVertex.z)];
                NSArray *b_light_pos = @[ @(self.x_focused_2 - interVertex.x),
                                          @(-self.y_focused_2 - interVertex.y),
                                          @(self.z_focused_2 - interVertex.z)];
                
                NSArray *int_n = interpolateNormal(vertices[0],
                                                   vertices[1],
                                                   vertices[2],
                                                   CGPointMake(j, i),
                                                   ((Vertex *)p.vertices[0]).normal,
                                                   ((Vertex *)p.vertices[1]).normal,
                                                   ((Vertex *)p.vertices[2]).normal);
                if ( !int_n || !interVertex || mult(int_n, [self viewerPos]) < 0) {
                    
                   // NSLog(@"%@ %@",int_n, interVertex);
                    continue;
                }
                
                [rep_dest setColor:[self calculateColorWithNormal:int_n
                                                            l1Pos:a_light_pos
                                                            l2Pos:b_light_pos
                                                        viewerPos:[self viewerPos]]
                               atX:j y:i];
            }
        }
        for (int i = vertices[1].y; i < (int)vertices[2].y; i++){
            
          //  NSLog(@"%d",i);
            
            int lPoint = dotOnLine(vertices[1], vertices[2], i);
            int rPoint = dotOnLine(vertices[0], vertices[2], i);
            
            int left = fmin(lPoint, rPoint);
            int right = fmax(lPoint, rPoint);
            
            for (int j = left + 1; j <= right; j++) {
                
                Vertex * interVertex = interpolateVertex(p.vertices[0],
                                                         p.vertices[1],
                                                         p.vertices[2],
                                                         vertices[0],
                                                         vertices[1],
                                                         vertices[2], CGPointMake(j,i));
                
                NSArray *a_light_pos = @[ @(self.x_focused_1 - interVertex.x),
                                          @(-self.y_focused_1 - interVertex.y),
                                          @(self.z_focused_1 - interVertex.z)];
                NSArray *b_light_pos = @[ @(self.x_focused_2 - interVertex.x),
                                          @(-self.y_focused_2 - interVertex.y),
                                          @(self.z_focused_2 - interVertex.z)];
                
                NSArray *int_n = interpolateNormal(vertices[0],
                                                   vertices[1],
                                                   vertices[2],
                                                   CGPointMake(j, i),
                                                   ((Vertex *)p.vertices[0]).normal,
                                                   ((Vertex *)p.vertices[1]).normal,
                                                   ((Vertex *)p.vertices[2]).normal);
                
                if ( !int_n || !interVertex || mult(int_n, [self viewerPos]) < 0) continue;
                
                [rep_dest setColor:[self calculateColorWithNormal:int_n
                                                            l1Pos:a_light_pos
                                                            l2Pos:b_light_pos
                                                        viewerPos:[self viewerPos]]
                               atX:j y:i];
            }
        }
        free(vertices);
    }
    
    [result addRepresentation:rep_dest];
    
    CGImageRelease(dest);
    
    return result;
    
}

NSColor * interpolateColor(CGPoint a, CGPoint b, CGPoint c, CGPoint x, NSColor * a_col, NSColor *b_col, NSColor * c_col){
    
    double m3 = ((x.y - a.y)*(b.x - a.x) - (x.x - a.x)*(b.y - a.y))/((c.y - a.y)*(b.x - a.x) - (c.x - a.x)*(b.y - a.y));
    double m2 = ((x.y - a.y)*(c.x - a.x) - (x.x - a.x)*(c.y - a.y))/((b.y - a.y)*(c.x - a.x) - (b.x - a.x)*(c.y - a.y));
    double m1 = ((x.y - c.y)*(b.x - c.x) - (x.x - c.x)*(b.y - c.y))/((a.y - c.y)*(b.x - c.x) - (a.x - c.x)*(b.y - c.y));

    return [NSColor colorWithCalibratedRed:m1*a_col.redComponent + m2*b_col.redComponent + m3*c_col.redComponent
                                     green:m1*a_col.greenComponent + m2*b_col.greenComponent + m3*c_col.greenComponent
                                      blue:m1*a_col.blueComponent + m2*b_col.blueComponent + m3*c_col.blueComponent
                                     alpha:1.0];
    
}

- (NSImage *)guroRender{
    
    NSImage *result = [[NSImage alloc] initWithSize:CGSizeMake(SCENE_WIDTH, SCENE_HEIGHT)];
    
    CGImageRef dest = CGImageCreateWithNSImage(result);
    NSBitmapImageRep * rep_dest = [[NSBitmapImageRep alloc] initWithCGImage:dest];
    
    size_t height = rep_dest.pixelsHigh;
    size_t width = rep_dest.pixelsWide;

    for (Poly *p in self.figure.polygons) {
        
         if (((Vertex *)p.vertices[0]).z < 0 || ((Vertex *)p.vertices[1]).z < 0 || ((Vertex *)p.vertices[2]).z < 0) continue;
        
        p.vertices = [p.vertices sortedArrayUsingComparator:^NSComparisonResult(Vertex * obj1, Vertex * obj2) {
            if (obj1.y < obj2.y) return NSOrderedAscending;
            else if(obj1.y > obj2.y) return NSOrderedDescending;
            else return NSOrderedSame;
        }];
        
        CGPoint * vertices = (CGPoint *)malloc(sizeof(CGPoint) * 3);
        
        vertices[0] = project(p.vertices[0], height, width, self.figure);
        vertices[1] = project(p.vertices[1], height, width, self.figure);
        vertices[2] = project(p.vertices[2], height, width, self.figure);
        
        NSArray *a_light_pos = @[ @(self.x_focused_1 - ((Vertex *)p.vertices[0]).x),
                                  @(-self.y_focused_1 - ((Vertex *)p.vertices[0]).y),
                                  @(self.z_focused_1 - ((Vertex *)p.vertices[0]).z)];
        NSArray *b_light_pos = @[ @(self.x_focused_2 - ((Vertex *)p.vertices[0]).x),
                                  @(-self.y_focused_2 - ((Vertex *)p.vertices[0]).y),
                                  @(self.z_focused_2 - ((Vertex *)p.vertices[0]).z)];
        
        NSColor * col0 = [self calculateColorWithNormal:((Vertex *)p.vertices[0]).normal
                                                  l1Pos:a_light_pos
                                                  l2Pos:b_light_pos viewerPos:[self viewerPos]];
        
        a_light_pos = @[ @(self.x_focused_1 - ((Vertex *)p.vertices[1]).x),
                         @(-self.y_focused_1 - ((Vertex *)p.vertices[1]).y),
                         @(self.z_focused_1 - ((Vertex *)p.vertices[1]).z)];
        b_light_pos = @[ @(self.x_focused_2 - ((Vertex *)p.vertices[1]).x),
                         @(-self.y_focused_2 - ((Vertex *)p.vertices[1]).y),
                         @(self.z_focused_2 - ((Vertex *)p.vertices[1]).z)];
        
        NSColor * col1 = [self calculateColorWithNormal:((Vertex *)p.vertices[1]).normal
                                                  l1Pos:a_light_pos
                                                  l2Pos:b_light_pos viewerPos:[self viewerPos]];
        
        a_light_pos = @[ @(self.x_focused_1 - ((Vertex *)p.vertices[2]).x),
                         @(-self.y_focused_1 - ((Vertex *)p.vertices[2]).y),
                         @(self.z_focused_1 - ((Vertex *)p.vertices[2]).z)];
        b_light_pos = @[ @(self.x_focused_2 - ((Vertex *)p.vertices[2]).x),
                         @(-self.y_focused_2 - ((Vertex *)p.vertices[2]).y),
                         @(self.z_focused_2 - ((Vertex *)p.vertices[2]).z)];
        
        NSColor * col2 = [self calculateColorWithNormal:((Vertex *)p.vertices[2]).normal
                                                  l1Pos:a_light_pos
                                                  l2Pos:b_light_pos viewerPos:[self viewerPos]];
        
        for (int i = vertices[0].y; i < (int)vertices[1].y; i++) {
            
            int lPoint = dotOnLine(vertices[0], vertices[1], i);
            int rPoint = dotOnLine(vertices[0], vertices[2], i);
            
            int left = fmin(lPoint, rPoint);
            int right = fmax(lPoint, rPoint);
            
            for (int j = left; j <= right; j++) {
                
                [rep_dest setColor:interpolateColor(vertices[0],
                                                    vertices[1],
                                                    vertices[2],
                                                    CGPointMake(j, i),
                                                    col0,
                                                    col1,
                                                    col2)
                               atX:j y:i];
            }
        }
        for (int i = vertices[1].y; i < (int)vertices[2].y; i++){
            
            int lPoint = dotOnLine(vertices[1], vertices[2], i);
            int rPoint = dotOnLine(vertices[0], vertices[2], i);
            
            int left = fmin(lPoint, rPoint);
            int right = fmax(lPoint, rPoint);
            
            for (int j = left; j <= right; j++) {
                
                
                [rep_dest setColor:interpolateColor(vertices[0],
                                                    vertices[1],
                                                    vertices[2],
                                                    CGPointMake(j, i),
                                                    col0,
                                                    col1,
                                                    col2)
                               atX:j y:i];
            }
        }
        free(vertices);
    }
    
    [result addRepresentation:rep_dest];
    
    CGImageRelease(dest);
    
    return result;

    
}

@end
