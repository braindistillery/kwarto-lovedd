









#   kwarto-lovedd


##  Intro

An implementation of the board game
[quarto](https://en.wikipedia.org/wiki/Quarto_(board_game))
written in C, brought to life by [löve](https://love2d.org).


##  Howto

Instructions for PC, see the section below for Android.

*   install löve

*   clone (or download and extract) the repository, go to the directory
    containing `main.lua`, and type the command `love .`

*   or, optionally, create a zip file from the directory contents
    and rename it to, say, `kwarto.love`
    (command line: `zip -9r kwarto.love .`),
    and then double-clicking this file is supposed to work

*   yet another possibility is to use
    [ZeroBrane Studio](https://studio.zerobrane.com):
    open `main.lua`, and from ‘Menu’|‘Project’ choose
    ‘Project Directory’|‘Set From Current File’ and ‘Lua Interpreter’|‘LÖVE’


##  Droid

*   install löve from the store:
    [org.love2d.android](https://play.google.com/store/apps/details?id=org.love2d.android)
    or manually:
    [love-10.0.2-android.apk](https://bitbucket.org/rude/love/downloads/love-0.10.2-android.apk)

*   create the directory `/sdcard/lovegame` on the device
    (löve will search there for the file named `main.lua`).

*   download into that directory (or download and copy there)
    the files `main.lua`, `conf.lua`, the directories
    `data`, `images` and `libs` (x64 libraries are not needed here).

*   launch ‘LÖVE for Android’
