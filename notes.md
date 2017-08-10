Thought about VESA:

The video memory pointer provided by a mode info block is an actual 32-bit pointer, not a segment:offset pointer.
That could be why it's impossible for me to draw to the screen just now.

I found this out by reading the VESA specification:

http://www.phatcode.net/res/221/files/vbe20.pdf