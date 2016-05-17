/*
Retrieved Mon 16 May 17:04:18 PDT 2016
http://stackoverflow.com/questions/3649874/how-to-get-keyboard-state-in-linux
http://stackoverflow.com/questions/448944/c-non-blocking-keyboard-input
http://linux.die.net/man/3/fd_zero
http://stackoverflow.com/questions/23068559/linux-input-device-reading-ioctleviocgkey-versus-readinput-event
http://www.linuxjournal.com/article/6429?page=0,0 - Using the Input Subsystem, Part II
http://man7.org/linux/man-pages/man2/open.2.html

Example usage:
getkey /dev/input/by-path/*-kbd lshift

Logic is inversed.  So will return true when shift key is not pressed else return non-zero.

This is good for bash logic because it means we can detect a shift key or a program error.
*/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include <linux/input.h>

void usage ( int argc, char *argv[] )
{
    printf("Usage:\n\t%s device key\n\ne.g. path - /dev/input/by-path/platform-3f980000.usb-usb-0:1.2:1.0-event-kbd\n\nvalid keys are:\n\tlshift\t- Left Shift key\n" , argv[0]);

    exit(EXIT_FAILURE);
}

int main ( int argc, char *argv[], char *env[] )
{
    if ( argc != 3 )    usage(argc, argv);

    int key;

    if ( strcmp(argv[2], "lshift") == 0 )       key = KEY_LEFTSHIFT;
    else if ( strcmp(argv[2], "rshift") == 0 )  key = KEY_RIGHTSHIFT;
    else if ( strcmp(argv[2], "lalt") == 0 )    key = KEY_LEFTALT;
    else if ( strcmp(argv[2], "ralt") == 0 )    key = KEY_RIGHTALT;
    else if ( strcmp(argv[2], "lctrl") == 0 )   key = KEY_LEFTCTRL;
    else if ( strcmp(argv[2], "rctrl") == 0 )   key = KEY_RIGHTCTRL;


    FILE *kbd = fopen("/dev/input/by-path/platform-3f980000.usb-usb-0:1.2:1.0-event-kbd", "r");
    char key_map[KEY_MAX/8 + 1];    //  Create a byte array the size of the number of keys

    memset(key_map, 0, sizeof(key_map));    //  Initate the array to zero's
    ioctl(fileno(kbd), EVIOCGKEY(sizeof(key_map)), key_map);    //  Fill the keymap with the current keyboard state

    int keyb = key_map[key/8];  //  The key we want (and the seven others arround it)
    int mask = 1 << (key % 8);  //  Put a one in the same column as out key state will be in;

    return (keyb & mask);  //  Returns true if pressed otherwise false
}
