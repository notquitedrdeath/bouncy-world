//
//  Debug.h
//  Library Files
//
//  Created by Timothy Death on 30/03/13.
//  Copyright (c) 2013 Timothy Death. All rights reserved.
//

#ifndef Bouncy_World_Debug_h
#define Bouncy_World_Debug_h

/*
 Defines DLog function which is an extended version of NSLog, giving function, line and argument details
 */
#ifdef DEBUG
#   define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define DLog(...)
#endif


#endif
