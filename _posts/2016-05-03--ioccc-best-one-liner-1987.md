---
layout: post
title: "Annonated IOCCC best one-liner winner program"
categories: c code
---

```c
/* ioccc.c */

/* IOCCC best one-liner winner 1987 by David Korn ---

main() { printf(&unix["\021%six\012\0"],(unix)["have"]+"fun"-0x60);}

from <http://www.ioccc.org/years.html#1987>
*/

/* A detailed set of samples to show how this works
   by David Ireland, copyright (C) 2002.

   Modified by William Cheung
     for GCC Version 4.8.3 on CentOS 7 (x86_64)
   See 
       http://www.di-mgt.com.au/src/korn_ioccc.txt
     for original code
*/

#include <stdio.h>

int main() 
{
    
    // int unix;
    // We do not need to declare 'unix', or we will get an error:
    //   expected identifier or ‘(’ before numeric constant
    // because unix is a predefined macro that expands to 1 (only on 
    // unix-like systems perhaps) 

    printf("unix=%d\n", unix); /* =1 */    

    /* This prints the string "un", 
       i.e. "fun" starting at offset [1] */
    printf("%s\n","fun"+1);

    /* This prints 97 = the int value of the 2nd char 'a' */
    printf("%d\n", "have"[1]);

    /* just like this */
    printf("%d\n", 'a');

    /* ditto because x[1] = 1[x] */
    printf("%d\n", (1)["have"]);

    /* 97 - 96 = 0x61 - 0x60 = 1 */
    printf("%d\n", (1)["have"] - 0x60);

    /* So this is the same as "fun" + 1, printing "un" */
    printf("%s\n", "fun" + ((1)["have"] - 0x60));

    /* Rearrange and use unix variable instead of 1 */
    printf("%s\n", (unix)["have"]+"fun"-0x60);

    /* ...thus we have the first argument in the printf call. */

    /* Both these print the string "bcde", ignoring the 'a' */
    printf("%s\n", "abcde" + 1);
    printf("%s\n", &"abcde"[1]);

    /* so does this */
    printf("%s\n", &(1)["abcde"]);

    /* and so does this (NB [] binds closer than &) */
    printf("%s\n", &unix["abcde"]);

    /* This prints "%six" + newline */
    printf("%s", &"?%six\n"[1]);

    /* So does this: note that
       \012 = 0x0a = \n,
       the first \021 char is ignored,
       and the \0 is superfluous, probably just for symmetry */
    printf("%s", &"\021%six\012\0"[1]);

    /* and so does this */
    printf("%s", &unix["\021%six\012\0"]);

    /* Using this as a format string, we can print "ABix" */
    printf(&unix["\021%six\012\0"], "AB");

    /* just like this does */
    printf("%six\n", "AB");

    /* So, we can print "unix" like this */
    printf("%six\n", (unix)["have"]+"fun"-0x60);
    
    /* or, finally, like this */
    printf(&unix["\021%six\012\0"],(unix)["have"]+"fun"-0x60);

    return 0;
}
```
