// Copyright © 2014 Kent Displays, Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#import <UIKit/UIKit.h>

#import "BBFiltering.h"

// Switch states
#define TSW_FLAG                (1 << 0)
#define BSW_FLAG                (1 << 1)
#define RDY_FLAG                (1 << 2)

#if TARGET_OS_IPHONE
#define PATH_CLASS UIBezierPath
#else
#define PATH_CLASS NSBezierPath
#endif

// Set distance threshold for drawing a new segment (10*0.01mm = 0.1mm).
#define DISTANCE_THRESHOLD_SQUARED (10*10)

#define TICKS_PER_MM    100         // Digitizer resolution is 0.01 mm
#define MS_PER_SAMPLE   6.924f      // 144.425 samples per second
#define PEN_ANGLE_COS   0.866f      // Assuming stylus held at 30 deg angle.
#define SCALE           0.75f       // Scale factor for reported linewidth (to make recorded lines sharper than actual device).

// Macro to convert from velocity in mm/s to distance (in digitizer units) between successive samples.
#define V2D(vel)       ((vel)*TICKS_PER_MM*MS_PER_SAMPLE/1000)

// Macro to convert from line width expressed in mm to scaled line width expressed in digitizer units.
#define MM2DIG(mm)     ((mm)*TICKS_PER_MM*SCALE)

// Macro to convert from mass in grams (normal to surface) to corresponding digitizer pressure reading (along stylus).
#define M2P(mass)      ((mass)*PEN_ANGLE_COS*1023.0f/600.0f + 0.5f)

// Array of digitizer pressure readings for which line widths are provided.
const uint16_t mass[] = {M2P(10.0f), M2P(25.0f), M2P(50.0f), M2P(100.0f),
    M2P(150.0f), M2P(200.0f), M2P(250.0f), M2P(300.0f), M2P(350.0f),
    M2P(400.0f), M2P(450.0f), M2P(500.0f), M2P(550.0f), M2P(600.0f)};
#define MASS_NUM_ENTRIES   (sizeof(mass)/sizeof(mass[0]))

typedef enum {NO_PTS, ONE_PT, MULTIPLE_PTS} pathState_t;

typedef struct
{
    int16_t x;
    int16_t y;
    int16_t p;
} coord_t;

typedef struct
{
    uint8_t  msg;
    uint8_t  flags;
    uint16_t x;
    uint16_t y;
    uint16_t p;
} drawCoordMsg_t;

typedef struct
{
    uint16_t x1;
    uint16_t x2;
    uint16_t y1;
    uint16_t y2;
    float lineWidth;
} path_t;

typedef struct
{
    coord_t last;
    coord_t cur;
    coord_t vel;
    uint8_t t;
} filter_t;

// Data type for encoding trace width versus stylus speed.
typedef struct
{
    float    distance;          // In digitizer units (speed ~ distance between consecutive points).
    float    lineWidth[14];     // In digitizer units.
} lwmap_t;

static drawCoordMsg_t lastCoord;
static pathState_t pathState = NO_PTS;
static filter_t currFilter;

@implementation BBFiltering

+ (NSArray *)filteredPathsForCaptureMessage:(BBSyncCaptureMessage *)captureMessage {
    float lineWidth;
    uint32_t dist_sq;
    float velAvg, pressAvg;
    uint8_t i;
    NSMutableArray *paths = [NSMutableArray new];
    drawCoordMsg_t pCoord = {0, captureMessage.flags, captureMessage.x, captureMessage.y, captureMessage.pressure};
    
    // Process based on number of points already received in current trace.
    switch (pathState)
    {
        case NO_PTS:
            if ((pCoord.flags & (RDY_FLAG + TSW_FLAG)) == (RDY_FLAG + TSW_FLAG))  // Contact?
            {
                // Have first point.
                pathState = ONE_PT;
                
                // Initialize the dynamic filter.
                filterSetPos(&currFilter, &pCoord);
                
                // Reset filter for line width.
                resetLineWidthFilter();
            }
            break;
            
        case ONE_PT:
            if ((pCoord.flags & (RDY_FLAG + TSW_FLAG)) == (RDY_FLAG + TSW_FLAG))  // Contact?
            {
                // Apply filter and get distance**2 of filtered position from last rendered position.
                dist_sq = filterApply(&currFilter, &pCoord);
                
                // Render new position to PDF if sufficiently far from last rendered position.
                if (dist_sq >= DISTANCE_THRESHOLD_SQUARED)
                {
                    pathState = MULTIPLE_PTS;
                    
                    // Compute/draw the first segment of the trace to PDF.
                    velAvg = sqrt(dist_sq)/currFilter.t;
                    pressAvg = ((float)currFilter.last.p + currFilter.cur.p)/2;
                    computeLineWidth(velAvg, pressAvg, &lineWidth);
                    
                    [paths addObject:[self createPathWithLineWidth:lineWidth]];
                    
                    // Reset "last" point for filter.
                    filterSetLast(&currFilter);
                }
            }
            else  // No contact.
            {
                pathState = NO_PTS;
                
                // Draw the dot/period for the single point to PDF.
                velAvg = -1.0f;
                pressAvg = currFilter.cur.p;
                computeLineWidth(velAvg, pressAvg, &lineWidth);
                
                [paths addObject:[self createPathWithLineWidth:lineWidth]];
            }
            break;
            
        case MULTIPLE_PTS:
            if ((pCoord.flags & (RDY_FLAG + TSW_FLAG)) == (RDY_FLAG + TSW_FLAG))  // Contact?
            {
                // Apply filter and get distance**2 of filtered position from last rendered position.
                dist_sq = filterApply(&currFilter, &pCoord);
                
                // Render new position to PDF if sufficiently far from last rendered position.
                if (dist_sq >= DISTANCE_THRESHOLD_SQUARED)
                {
                    // Compute/draw the next trace segment to PDF.
                    velAvg = sqrt(dist_sq)/currFilter.t;
                    pressAvg = ((float)currFilter.last.p + currFilter.cur.p)/2;
                    computeLineWidth(velAvg, pressAvg, &lineWidth);
                    
                    [paths addObject:[self createPathWithLineWidth:lineWidth]];
                    
                    // Reset "last" point for filter.
                    filterSetLast(&currFilter);
                }
            }
            else  // No contact.
            {
                pathState = NO_PTS;
                
                // Will use fixed (current) velocity to compute line width during final convergence
                // to prevent artificial blobbing at the end of traces (due to artificial slowdown
                // induced by repeating final digitizer coordinate).
                velAvg = sqrt(currFilter.vel.x*currFilter.vel.x + currFilter.vel.y*currFilter.vel.y);
                
                // Provide filter final coordinate multiple times to converge on pen up point.
                for (i = 0; i < 4; i++)
                {
                    // Apply filter and get distance**2 of filtered position from last rendered position.
                    dist_sq = filterApply(&currFilter, &lastCoord);
                    
                    // Render new position to PDF if sufficiently far from last rendered position.
                    if (dist_sq >= DISTANCE_THRESHOLD_SQUARED)
                    {
                        // Compute line width.
                        pressAvg = ((float)currFilter.last.p + currFilter.cur.p)/2;
                        computeLineWidth(velAvg, pressAvg, &lineWidth);
                        
                        [paths addObject:[self createPathWithLineWidth:lineWidth]];
                        
                        // Reset "last" point for filter.
                        filterSetLast(&currFilter);
                    }
                }
            }
            break;
    }
    
    // Store coordinate for finalizing trace at pen up.
    memcpy(&lastCoord, &pCoord, sizeof(drawCoordMsg_t));
    
    return paths;
}

+ (PATH_CLASS *)createPathWithLineWidth:(float)lineWidth {
    PATH_CLASS *path = [PATH_CLASS bezierPath];
    [path setLineCapStyle:kCGLineCapRound];
    [path moveToPoint:CGPointMake(currFilter.last.x, currFilter.last.y)];
    [path setLineWidth:lineWidth];
    [path addLineToPoint:CGPointMake(currFilter.cur.x, currFilter.cur.y)];
    return path;
}

// Array of line widths vs. pressure at various velocities.
const lwmap_t lwmap[] =
{
    //   v(mm/s)       10g*               25g*               50g               100g               150g               200g               250g               300g               350g               400g               450g               500g               550g*              600g*
    {V2D(  1.0f), { MM2DIG(0.720000f), MM2DIG(0.800000f), MM2DIG(0.908937f), MM2DIG(1.108957f), MM2DIG(1.266351f), MM2DIG(1.388042f), MM2DIG(1.462073f), MM2DIG(1.540000f), MM2DIG(1.618852f), MM2DIG(1.701938f), MM2DIG(1.793265f), MM2DIG(1.860000f), MM2DIG(1.920000f), MM2DIG(1.954108f)}},
    {V2D(  5.0f), { MM2DIG(0.490000f), MM2DIG(0.530000f), MM2DIG(0.614119f), MM2DIG(0.758321f), MM2DIG(0.868824f), MM2DIG(0.910000f), MM2DIG(0.942034f), MM2DIG(1.000218f), MM2DIG(1.047881f), MM2DIG(1.083052f), MM2DIG(1.155148f), MM2DIG(1.196536f), MM2DIG(1.250000f), MM2DIG(1.286546f)}},
    {V2D( 30.0f), { MM2DIG(0.300000f), MM2DIG(0.340000f), MM2DIG(0.387672f), MM2DIG(0.493372f), MM2DIG(0.565948f), MM2DIG(0.620261f), MM2DIG(0.673648f), MM2DIG(0.710716f), MM2DIG(0.746997f), MM2DIG(0.777846f), MM2DIG(0.815101f), MM2DIG(0.837235f), MM2DIG(0.880000f), MM2DIG(0.926857f)}},
    {V2D( 75.0f), { MM2DIG(0.290000f), MM2DIG(0.295000f), MM2DIG(0.320000f), MM2DIG(0.374948f), MM2DIG(0.422921f), MM2DIG(0.473530f), MM2DIG(0.508386f), MM2DIG(0.541358f), MM2DIG(0.577623f), MM2DIG(0.600577f), MM2DIG(0.621771f), MM2DIG(0.651861f), MM2DIG(0.670000f), MM2DIG(0.690000f)}},
    {V2D(100.0f), { MM2DIG(0.280000f), MM2DIG(0.290000f), MM2DIG(0.302881f), MM2DIG(0.338898f), MM2DIG(0.387231f), MM2DIG(0.433664f), MM2DIG(0.452389f), MM2DIG(0.482745f), MM2DIG(0.516970f), MM2DIG(0.534589f), MM2DIG(0.557370f), MM2DIG(0.581577f), MM2DIG(0.610000f), MM2DIG(0.620000f)}},
    {V2D(180.0f), { MM2DIG(0.250000f), MM2DIG(0.260000f), MM2DIG(0.280375f), MM2DIG(0.311056f), MM2DIG(0.362906f), MM2DIG(0.390511f), MM2DIG(0.414745f), MM2DIG(0.436406f), MM2DIG(0.463840f), MM2DIG(0.478165f), MM2DIG(0.501515f), MM2DIG(0.521805f), MM2DIG(0.540000f), MM2DIG(0.550000f)}}
};
#define LWMAP_NUM_ENTRIES  (sizeof(lwmap)/sizeof(lwmap[0]))

// State of line width filter.
static float oldLW = -1.0f;

///////////////////////////////////////////////////////////////////////////////
// Function:  resetLineWidthFilter
// Purpose:   Clears line width filter for start of a new trace.
// Inputs:    None
// Outputs:   None
// Notes:     None
///////////////////////////////////////////////////////////////////////////////
void resetLineWidthFilter(void)
{
    oldLW = -1.0f;
}


///////////////////////////////////////////////////////////////////////////////
// Function:  computeLineWidth
// Purpose:   Convert stylus pressure/speed into a linewidth value expressed
//            in digitizer units.
// Inputs:    vel - velocity expressed in digitizer units per sample interval
//            pressure - digitizer pressure reading
//            pLineWidth  - pointer to location to return line width
// Outputs:   None.
// Note:      If vel < 0, the stylus was lifted after a single contact point.
///////////////////////////////////////////////////////////////////////////////
void computeLineWidth(float vel, float pressure, float *pLineWidth)
{
    uint8_t i, j;
    float dist;
    float lwa, lwb, lw;
    
    // Compute distance btw. successive samples in digitizer units.
    if (vel < 0)
        dist = V2D(75.0f);   // Don't know real speed if only have one point => Assume a mid-level.
    else
        dist = vel;
    
    // Saturate distance at range we have data for.
    if (dist < lwmap[0].distance)
        dist = lwmap[0].distance;
    else if (dist > lwmap[LWMAP_NUM_ENTRIES-1].distance)
        dist = lwmap[LWMAP_NUM_ENTRIES-1].distance;
    
    // Saturate pressure at range we have data for.
    if (pressure < mass[0])
        pressure = mass[0];
    else if (pressure > mass[MASS_NUM_ENTRIES - 1])
        pressure = mass[MASS_NUM_ENTRIES - 1];
    
    // Find the indices for distance (velocity).
    for (i = 1; i < LWMAP_NUM_ENTRIES; i++)
    {
        if (dist <= lwmap[i].distance)
            break;
    }
    
    // Find the indices for mass (pressure).
    for (j = 1; i < MASS_NUM_ENTRIES; j++)
    {
        if (pressure <= mass[j])
            break;
    }
    
    // Interpolate based on mass (pressure) first.
    lwa = lwmap[i-1].lineWidth[j-1]  +  (pressure - mass[j-1])*(lwmap[i-1].lineWidth[j-0] - lwmap[i-1].lineWidth[j-1])/(mass[j-0] - mass[j-1]);
    lwb = lwmap[i-0].lineWidth[j-1]  +  (pressure - mass[j-1])*(lwmap[i-0].lineWidth[j-0] - lwmap[i-0].lineWidth[j-1])/(mass[j-0] - mass[j-1]);
    
    // Interpolate based on speed (distance) second.
    lw = lwa + (dist - lwmap[i-1].distance)*(lwb - lwa)/(lwmap[i-0].distance - lwmap[i-1].distance);
    
    // Initialize filter if needed.
    // (The max value helps eliminate ink blobs at the start of traces due to impact pressures and/or low speeds.)
    if (oldLW < 0)
        oldLW = (lw > 45.0f ? 45.0f : lw);
    
    //  Filter A:  (LW changes too quickly for close samples and too slowly for far samples.)
    //  lw = (lw + 7*oldLW)/8;
    
    //  Filter B:
    //  if (dist <= oldLW)
    //    {
    //      lw = 0.1*lw + 0.9*oldLW;
    //    }
    //  else if (dist <= 5*oldLW)
    //    {
    //      float alpha = 0.1 + 0.9*(dist-oldLW)/(4*oldLW);
    //      lw = alpha*lw + (1 - alpha)*oldLW;
    //    }
    
    //  Filter C:  ** Seems to perform the best.
    lw = (2*dist*lw + oldLW*oldLW)/(2*dist + oldLW);
    
    //  Filter D:
    //  lw = (2*dist + oldLW)/(2*dist + lw)*lw;
    
    // Remember last linewidth for filtering.
    oldLW = lw;
    
    // Store the line width.
    *pLineWidth = lw;
}

// Initializes a provided dynamic filter with the first point in a trace.
void filterSetPos(filter_t *f, const drawCoordMsg_t *pCoord)
{
    f->last.x = f->cur.x = (int16_t)pCoord->x;
    f->last.y = f->cur.y = (int16_t)pCoord->y;
    f->last.p = f->cur.p = (int16_t)pCoord->p;
    
    f->vel.x = f->vel.y = f->vel.p = 0.0;
    f->t = 0;
}

// Notifies a provided dynamic filter that a new segment has been drawn.
void filterSetLast(filter_t *f)
{
    f->last.x = f->cur.x;
    f->last.y = f->cur.y;
    f->last.p = f->cur.p;
    f->t = 0;
}


// Dynamic filter Proportional and Derivative controller gains
// (includes effects of mass and sample time (K*T/mass)).
#define KPP     1229   // 1229/8192 = 0.1500 ~0.15f
#define KDD     4915   // 4915/8192 = 0.6000 ~0.6f

// Updates dynamic filter state based on new reference coordinate.
uint32_t filterApply(filter_t *f, const drawCoordMsg_t *pCoord)
{
    int32_t ax, ay, ap;
    uint32_t dist_sq;
    
    // Update delta time (samples) since last segment drawn (threshold met).
    if (f->t < 255)
        f->t++;
    
    // Calculate 8192 (= 2^13) x acceleration.
    ax = (int32_t)KPP*((int32_t)pCoord->x - f->cur.x) - (int32_t)KDD*f->vel.x;
    ay = (int32_t)KPP*((int32_t)pCoord->y - f->cur.y) - (int32_t)KDD*f->vel.y;
    ap = (int32_t)KPP*((int32_t)pCoord->p - f->cur.p) - (int32_t)KDD*f->vel.p;
    
    // Calculate new position.
    f->cur.x += f->vel.x;
    f->cur.y += f->vel.y;
    f->cur.p += f->vel.p;
    
    // Calculate new velocity.
    f->vel.x = (((int32_t)f->vel.x << 13) + ax) >> 13;
    f->vel.y = (((int32_t)f->vel.y << 13) + ay) >> 13;
    f->vel.p = (((int32_t)f->vel.p << 13) + ap) >> 13;
    
    // Calculate squared distance of current point from "last" point.
    dist_sq = ((f->cur.x - f->last.x)*(f->cur.x - f->last.x) + (f->cur.y - f->last.y)*(f->cur.y - f->last.y));
    
    return dist_sq;
}


@end
