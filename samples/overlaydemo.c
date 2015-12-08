/*
** Minimalistic overlay demo program.
**
** Shows how to load overlay files from disk.
**
** 2009-10-02, Oliver Schmidt (ol.sc@web.de)
**
*/



#include <stdio.h>
#include <conio.h>
#ifndef __CBM__
#include <fcntl.h>
#include <unistd.h>
#else
#include <device.h>
#endif


extern void _OVERLAY1_LOAD__[], _OVERLAY1_SIZE__[];
extern void _OVERLAY2_LOAD__[], _OVERLAY2_SIZE__[];
extern void _OVERLAY3_LOAD__[], _OVERLAY3_SIZE__[];


/* Functions resident in an overlay can call back functions resident in the
** main program at any time without any precautions. The function log() is
** an example for such a function resident in the main program.
*/
void log (char *msg)
{
    printf ("Log: %s\n", msg);
}


/* In a real-world overlay program one would probably not use a #pragma but
** rather place all the code of certain source files into the overlay by
** compiling them with --code-name OVERLAY1.
*/
#pragma code-name (push, "OVERLAY1");

void foo (void)
{
    /* Functions resident in an overlay can access all program variables and
    ** constants at any time without any precautions because those are never
    ** placed in overlays. The string constant below is an example for such
    ** a constant resident in the main program.
    */
    log ("Calling main from overlay 1");
}

#pragma code-name (pop);


#pragma code-name (push, "OVERLAY2");

void bar (void)
{
    log ("Calling main from overlay 2");
}

#pragma code-name (pop);


#pragma code-name (push, "OVERLAY3");

void foobar (void)
{
    log ("Calling main from overlay 3");
}

#pragma code-name(pop);


unsigned char loadfile (char *name, void *addr, void *size)
{
#ifndef __CBM__

    int file = open (name, O_RDONLY);
    if (file == -1) {
        log ("Opening overlay file failed");
        return 0;
    }
    read (file, addr, (unsigned) size);
    close (file);

#else

    /* Avoid compiler warnings about unused parameters. */
    (void) addr; (void) size;
    if (cbm_load (name, getcurrentdevice (), NULL) == 0) {
        log ("Loading overlay file failed");
        return 0;
    }

#endif
    return 1;
}


void main (void)
{
    log ("Calling overlay 1 from main");

    /* The symbols _OVERLAY1_LOAD__ and _OVERLAY1_SIZE__ were generated by the
    ** linker. They contain the overlay area address and size specific to a
    ** certain program.
    */
    if (loadfile ("ovrldemo.1", _OVERLAY1_LOAD__, _OVERLAY1_SIZE__)) {

        /* The linker makes sure that the call to foo() ends up at the right mem
        ** addr. However it's up to user to make sure that the - right - overlay
        ** is actually loaded before making the the call.
        */
        foo ();
    }

    log ("Calling overlay 2 from main");

    /* Replacing one overlay with another one can only happen from the main
    ** program. This implies that an overlay can never load another overlay.
    */
    if (loadfile ("ovrldemo.2", _OVERLAY2_LOAD__, _OVERLAY2_SIZE__)) {
        bar ();
    }

    log ("Calling overlay 3 from main");
    if (loadfile ("ovrldemo.3", _OVERLAY3_LOAD__, _OVERLAY3_SIZE__)) {
        foobar ();
    }

    cgetc ();
}
