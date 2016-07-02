//
//  Figure.h
//  Graphics_8
//
//

#import <Foundation/Foundation.h>

@interface Figure : NSObject

@property (strong, nonatomic) NSArray * polygons;

@property (nonatomic, readonly) double minX;
@property (nonatomic, readonly) double minY;
@property (nonatomic, readonly) double minZ;
@property (nonatomic, readonly) double maxX;
@property (nonatomic, readonly) double maxY;
@property (nonatomic, readonly) double maxZ;

+ (instancetype)initFormFile:(NSURL *)url;

- (void)turnByOx:(double)angle;

@end


@interface Vertex : NSObject

@property (nonatomic) double x;
@property (nonatomic) double y;
@property (nonatomic) double z;
@property (nonatomic, strong) NSArray * normal;

+ (instancetype)initWithX:(double )x Y:(double)y Z:(double)z normal:(NSArray *)normal;

- (void)turnByOx:(double)angle;

- (void)turnByOy:(double)angle;


@end

//@interface Line : NSObject
//
//@property (nonatomic, strong) Vertex * v0;
//@property (nonatomic, strong) Vertex * v1;
//
//+ (instancetype)initWithV0:(Vertex *)v0 V1:(Vertex *)v1;
//
//@end

@interface Poly : NSObject

@property (nonatomic, strong) NSArray * vertices;

@end
