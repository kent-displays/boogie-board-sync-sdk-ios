# Boogie Board Sync SDK v1.0 for iOS

The software development kit provides a library for communicating with a Boogie Board Sync on iOS. This library allows developers to view, modify and retrieve aspects of the file system on the Sync. It also allows developers to retrieve real-time information like current position of the stylus and a user pressing the save and erase button.

- [Installing](#installing)
- [Structure](#structure)
- [Documentation](#documentation)
- [Requirements](#requirements)
- [Questions?](#questions)
- [License](#license)

## Installing

#### Option 1: Download entire project
Download the entire project directory and try out the included example project.

#### Option 2: Include library

1. Include this library in your current project by adding all the files under BBSync to your current project's target.
2. Make sure to add the following frameworks to your project's target under Build Phases.

	![frameworks-image](http://i.imgur.com/PeiSoT6.png)
	
3. Inside your project's Info.plist file add the following entries.

	![properties-image](http://i.imgur.com/RtztYaI.png)

4. In your AppDelegate.m file import the Sync SDK library.

	```
	#import "BBSync.h"
	```	
5. Set up the library to automatically find and connect to a Boogie Board Sync by placing the following code in your App Delegate's application:didFinishLaunchingWithOptions: method.

	```
	- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    	// Override point for customization after application launch.
    	[BBSessionController sharedController];
    	return YES;
	}
	```
6. Check out the provided example and how to interface with the Sync SDK library.
	
## Structure

### BBSessionController
Automatically manages the connection to a Boogie Board Sync. This includes setting up and tearing down connections. Provides notifications for the connection and disconnection of a Sync.

**Note:** Must be initialized during ```application:didFinishLaunchingWithOptions:```, in your App Delegate to ensure controller is set up to find currently connected devices at launch.

### BBSyncFileTransferClient
Facilitates the communication with a Boogie Board Sync through a file transfer protocol based on OBEX File Transfer. The use of this client allows for files to be downloaded, deleted, traversed and listed on a Sync. The connection must first be made to the file transfer server before executing any other requests. Do this by calling ```connect``` and wait for the delegate's ```didConnect:``` to be called. Once finished with the file transfer client, remember to call ```disconnect```.

**Note:** Before trying to make requests, the BBSessionController must first be set up. 

### BBSyncStreamingClient
Facilitates communication with a Boogie Board Sync through a custom data capture protocol based on HID. The use of this client allows for real time information including paths drawn, button pushes and raw data reports.
 
When the streaming client is first set up it will be put into ```BBSyncModeFile```. If no reporting is required then it is encouraged to put the streaming server into ```BBSyncModeNone```. If drawn paths are required then the streaming server must be put into ```BBSyncModeCapture```.

**Note:** Before trying to make requests, the BBSessionController must first be set up.

## Documentation

Appledocs for this library can be found here.

## Requirements
	
	- ARC
	- iOS 6.0+

## Questions?

For questions or comments email or contact us on Twitter

- [cfullmer@kentdisplays.com](mailto:cfullmer@kentdisplays.com)
- [@camdenfullmer](http://twitter.com/camdenfullmer)

## License

Copyright © 2014 Kent Displays, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

