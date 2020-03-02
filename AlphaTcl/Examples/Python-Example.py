# Python-Example.py
# 
# Distributed as an example of Alpha's Python mode.
#
# Pyth mode is available at
# 
# <http://www.python.org/emacs/python-mode/>
#

# Source of original document:
# 
# <http://www.enme.ucalgary.ca/~nascheme/python/>
# 
# Reproduced with the permission of the author.
#

#!/usr/bin/env python
#
# Create HTML from a GIF file and text input.
#
# Usage: gif2html.py pic.gif < input > output.html
#
# Neil Schemenauer <nascheme@enme.ucalgary.ca>

import Image
import sys
import string
import htmlentitydefs

# reverse table for HTML entity names
entitydefs = {}
for name, value in htmlentitydefs.entitydefs.items():
    entitydefs[value] = name

def getc(file):
    while 1:
        c = file.read(1)
        if not c:
            raise EOFError
        if c not in string.whitespace:
            return c

def main(graphic, input, output, transparent=(255, 0, 255)):
    output.write('<html><body bgcolor=#000000><basefont size=1><pre>')
    im = Image.open(graphic)
    im = im.convert('RGB')
    # try to keep aspect the same (make height 2/3 of original)
    im = im.resize((im.size[0], im.size[1]*3/5))
    d = im.getdata()
    l, w = im.size
    last_pixel = None
    font_open = 0
    for i in range(w):
        for j in range(l):
            pixel = d[i*l+j]
            if pixel == transparent:
                output.write('&nbsp;')
            else:
                c = getc(input)
                if pixel != last_pixel:
                    if font_open:
                        output.write('</font>')
                    font_open = 1
                    output.write('<font color=#%.2x%.2x%.2x>' % pixel)
                if entitydefs.has_key(c):
                    c = '&%s;' % entitydefs[c]
                output.write(c)
                last_pixel = pixel
        output.write('\n')

    output.write("""</font></pre><br>
        <a href="http://www.enme.ucalgary.ca/~nascheme/python/gif2html.py">
        gif2html.py</a></body></html>""")

if __name__ == '__main__':
    main(sys.argv[1], sys.stdin, sys.stdout)
