#!/bin/bash
echo "Please wait while we update the cscope database"
find . -name "*.c" -o -name "*.o" -o -name "*.h" -o -name "*.S" -o -name "*.ld" -o -name "*.asm" -o -name "*.mk" -o -name "*.d" -o -name "*.sym"  > cscope.files
cscope -q -R -b -i cscope.files
echo "Cscope database updated"
