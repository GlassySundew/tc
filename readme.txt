IMPORTANT NOTES:
1. player entity must to be in the top of entities list in tiled to have correct sorting order(or at least in the bottom in entity array containter in-game)

# butler push sdl_win.zip GlassySundew/total-condemn:win --userversion 0.0.1
# gcc -O3 -o tc -std=c11 -I out out/main.c  -lhl /home/glassysundew/hashlink/*.hdll -lGLU -lpthread -lm -luv -Llib -lSDL2
