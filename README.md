Purpose and features
====================

FireAphisClearerTool (FACT) is a small project intended to make a life
with ClearCase a little bit happier. The project tries to achieve the
goal in two ways:

1. Create an intuitive front end for IBM Rational ClearCase SCM.
2. Create a library that simplifies the process of development of scripts
   that interact with ClearCase.

CLI
---

By executing bin/cli.rb the user enters the CLI mode. This mode is designed
to support common use cases. It is supposed to make the job done in minimum 
key presses and without the need to remember numerous commands.

Here's the current menus hierarchy of the CLI mode:

'''
    Undeliverd activities
        |
        --- Activity change set
                |
                --- File information
                        |
                        --- Change set predecessor diff
'''

        
Development status
==================

The project is in the development state and doesn't have stable realeases
yet. The development is done in short iterations, each delivering a small 
but complete feature. A couple of first releases will be released as beta 
releases for the field testing, before a stable version is released. The 
first iteration is scheduled to be complete by the end of May 2011.


Dependencies
============

No compatibility tests with different versions were performed. The versions
listed here are the ones installed in the current deployments and the
development environment.

- Ruby 1.8.5

- HighLine (http://highline.rubyforge.org/)
  Developed with 1.6.1, should work with earlier versions as well.
