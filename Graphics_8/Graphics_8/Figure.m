//
//  Figure.m
//  Graphics_8
//

#import "Figure.h"

@implementation Figure

@synthesize polygons = _polygons;

@synthesize minX = _minX;
@synthesize minY = _minY;
@synthesize minZ = _minZ;
@synthesize maxX = _maxX;
@synthesize maxY = _maxY;
@synthesize maxZ = _maxZ;

+ (instancetype)initFormFile:(NSURL *)url{
    
//    NSError * error = nil;
    NSString * jsonString = [[NSString alloc] initWithContentsOfURL:url
                                                     encoding:NSUTF8StringEncoding
                                                        error:nil];
//    if (error) @throw [[NSException alloc] initWithName:@"Reading file exception"
//                                                reason:@"Cannot read the file"
//                                              userInfo:nil];
    Figure * result = [[Figure alloc] init];
    NSDictionary * figureDict = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]
                                                                options:0
                                                                  error:nil];
    
    NSMutableArray * polygons = [[NSMutableArray alloc] init];
    for (NSArray * dictPolygon in figureDict[@"polygons"]) {
        
        Poly * p = [[Poly alloc] init];
        
        NSMutableArray * vertices = [[NSMutableArray alloc] init];
        
        for (NSNumber * vertexIndex in dictPolygon) {
            
            NSArray * vdict = figureDict[@"coords"][[vertexIndex intValue]];
            NSArray * vnorm = figureDict[@"normals"][[vertexIndex intValue]];
            
            Vertex * v = [Vertex initWithX:[vdict[0] doubleValue]
                                         Y:[vdict[1] doubleValue]
                                         Z:[vdict[2] doubleValue]
                                     normal:vnorm];
            [vertices addObject:v];
        }
        
        p.vertices = [vertices copy];
        [polygons addObject:p];
        
    }
    
    result.polygons = polygons;
    [result defineBorders];
    
    return result;
    
}

- (void)defineBorders{
    
    _minX = INT32_MAX;
    _minY = INT32_MAX;
    _minZ = INT32_MAX;
    _maxX = INT32_MIN;
    _maxY = INT32_MIN;
    _maxZ = INT32_MIN;
    
    for (Poly * p in self.polygons) {
        for (Vertex *v in p.vertices) {
            _minX = fmin(v.x,_minX);
            _minY = fmin(v.y,_minY);
            _minZ = fmin(v.z,_minZ);
            _maxX = fmax(v.x,_maxX);
            _maxY = fmax(v.y,_maxY);
            _maxZ = fmax(v.z,_maxZ);
        }
    }
    
}

- (void)turnByOx:(double)angle{
    
    for (Poly * p in self.polygons) {
        for (Vertex * v in p.vertices) {
            [v turnByOx:angle];
        }
    }
    
}

@end

@implementation Vertex

@synthesize x = _x;
@synthesize y = _y;
@synthesize z = _z;
@synthesize normal = _normal;

+ (instancetype)initWithX:(double)x Y:(double)y Z:(double)z normal:(NSArray *)normal{
    
    Vertex * result = [[Vertex alloc] init];
    result.x = x;
    result.y = y;
    result.z = z;
    result.normal = normal;
    return result;
    
}

- (void)turnByOx:(double)angle{
    
    double o_y = self.y;
    double o_z = self.z;
    self.y = cos(angle / 180 * M_PI)*o_y - sin(angle / 180 * M_PI)*o_z;
    self.z = sin(angle / 180 * M_PI)*o_y + cos(angle / 180 * M_PI)*o_z;
    
    self.normal = @[ self.normal[0],
                     @(cos(angle / 180 * M_PI)*[self.normal[1] doubleValue] - sin(angle / 180 * M_PI)*[self.normal[2] doubleValue]),
                     @(sin(angle / 180 * M_PI)*[self.normal[1] doubleValue] + cos(angle / 180 * M_PI)*[self.normal[2] doubleValue])];
}

- (void)turnByOy:(double)angle{
    
    
    
}

@end

//@end

@implementation Poly

@synthesize vertices = _vertices;

@end