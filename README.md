Purpose and features
====================

FireAphisClearerTool (FACT) is a small project intended to make a life
with ClearCase a little bit happier. The project tries to achieve the
goal in two ways:

1. Create an intuitive front end for IBM Rational ClearCase SCM.
2. Create a library that simplifies the process of development of scripts
   that interact with ClearCase.

IBM Rational ClearCase comes bundled with two user interfaces: one 
graphical and one command line based. Both, in my humble opinion, impact
user productivity severely. The graphical interface requires unreasonable
amount of mouse clicks for simple tasks, it doesn't support keyboard
input, its output is obscure, it is inconsistent and it is ugly. The 
command line tool tries to solve all the problems in the world thus having 
a very complicated syntax and an enormous amount of commands and options.

From my personal experience, I tend to perform same tasks over and over
again. Each time I have to choose between tedious and cluttered GUI and
looking through my notes for the correct combination of over sophisticated
command line commands.

This tool allows to perform the most common tasks in minimal amount of
clicks and supplies only the necessary information in the most readable
format, I could think of. Hope you will enjoy it too.


CLI
---

By executing bin/cli.rb the user enters the CLI mode. This mode is designed
to support common use cases. It is supposed to make the job done in minimum 
key presses and without the need to remember numerous commands.

Here's the current menus hierarchy of the CLI mode:

```
    Undelivered activities
        |
        --- Activity change set
                |
                --- File information
                        |
                        --- Change set predecessor diff
```

Dependencies
============

The tool requires Ruby, ClearCase cleartool (comes bundled with ClearCase) 
and HighLine gem (http://highline.rubyforge.org/). Cleartool has to be on 
your PATH.

Tested with the following versions:

- CentOS 5.3
- Ruby 1.8.5
- HighLine 1.6.1
- IBM Rational ClearCase 7.0.1

If you run it on different versions, let me know, so I can update the list.
