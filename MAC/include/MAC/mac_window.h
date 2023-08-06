#ifndef MAC_WINDOW_H_
#define MAC_WINDOW_H_


#ifdef __OBJC__
#import <Cocoa/Cocoa.h>

@interface Mac_WindowDelegate : NSObject <NSWindowDelegate>
@property (nonatomic, strong) NSView *contentView;
@end
#endif

#include <stdint.h>
#include <stdbool.h>
#include <MacTypes.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct MAC_Window MAC_Window;
typedef UInt32 MAC_WindowID;

typedef enum
{
    MAC_WINDOW_RESIZABLE = 0x00000001,
    MAC_WINDOW_MINIMIZED = 0x00000002,
    MAC_WINDOW_MAXIMIZED = 0x00000004,
    MAC_WINDOW_FULLSCREEN = 0x00000008,
    MAC_WINDOW_METAL = 0x00000010,
} MAC_WindowFlags;


struct MAC_Window
{
    int width;
    int height;
    const char* title;
    MAC_WindowID id;
    MAC_Window *parent;
    MAC_Window *children;
    UInt32 flags;
    void *delegate;
};


/*
    Functions for creating and managing windows
    Window default Functionalities:
        - Closable
        - Minimizable
*/
MAC_Window* createWindow(int width, int height, const char* title);
void closeWindow(MAC_Window* window);
bool isWindowOpen(MAC_Window* window);
void destroyWindow(MAC_Window* window);
void runWindow();
/*
    Functions for managing window hierarchies
*/
void addChildWindow(MAC_Window* parent, MAC_Window* child);
void removeChildWindow(MAC_Window* parent, MAC_Window* child);

/*
    Functions for managing window flags
*/
void setWindowFlag(MAC_Window* window, UInt32 flags);

#ifdef __cplusplus
}
#endif

#endif // MAC_WINDOW_H_