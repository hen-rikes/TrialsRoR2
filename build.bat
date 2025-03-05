@echo off

::-mwindows 

set LIBS=-l .\lib\raylib.lib -l opengl32 -l gdi32 -l winmm 
set FLAGS=--wincrt=none -g0 
set RAYLIBBINDINGS=.\raylib_bindings\raylib_bindings.c3 

c3c %FLAGS% %LIBS% compile %RAYLIBBINDINGS% main.c3
