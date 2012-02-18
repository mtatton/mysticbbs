This file showcases the direction of where this software wants to go as it
continues to expand.  Some things that will probably be mentioned will be
vague, and serve mostly to remind me of my own ideas.

The scope of this file is to document bugs and future enhancements/ideas.

BUGS AND POSSIBLE ISSUES
========================

? Validate ARCHIVE extensions are not case sensitive in Mystic
! GOTO does not always work properly in MPL (IceDevil)
! Complex boolean evaluations using numerical variables can sometime fail to
  compile (IceDevil)
! After data file review, add missing variables to various MPL Get/Put
  functions.
! MYSTPACK has access denied errors (caphood)
? Reapern66 has expressed that the minimal CPU requirements may be too
  agressive.  Work with him to sort out his baseline, and potentially reduce
  the CPU requirement for new versions.  Or just tell people the code is
  already available GPL and let them compile it if it is a problem?
! RAR internal viewer does not work with files that have embedded comments

FUTURE / IDEAS / WORK IN PROGRESS / NOTES
=========================================

- ANSI post-processor for message uploads via FSE
- ANSI reading support in fullscreen reader
- Ability to override read-type per message base (usersetting/normal/lightbar)
- Ability to override index setting per message base (same as above)
- Ability to override listing type per file base (same as above)
- Ability to list files in a base that is not the current file base
- MCI code to show how many files are in current filebase
- New ANSI template system
- Online ANSI file viewer (integrate with art gallery)
- Online ANSI help system
- Finish System Configuration rewrite
- Finish Data structure review
- NEWAPP.MPS
- Online text editor / ansi editor?
- Better theme selection (menu command option to select theme)
- Externalize remaining prompt data (msg flags, etc)
- File comments and rating system
- Global node message menu command (0;) = add option to ignore your own node
- Integrate eventual online ANSI help system into configuration utilities
- FUPLOAD command that does an automated Mass Upload from MBBSUTIL
- LEET "TIMER" event menu commands from Mystic 2
- In fact, replace entire menu engine iwth Mystic 2 engine which is SO far
  beyond anything built in ever... But converting old menus will be the
  challenge.  Do people really want to re-do their menu commands for all the
  added features, if that is needed?
- If not above, then possibly add whatever CAN be added in without a complete
  overhaul. (Everything except chain execution and specific key event chains
  I think?)
- Split 1 and 2 column msg/file list prompts and provide a user ability to
  pick which they'd like to use?
- File attachments and crossposts
- User-directories?  How could this be used?  Next two items?
- Ability to save a message post if a user is disconnected while posting.
- Ability to save file queue if a user is disconnected with a queue.
- User 2 User chat system and private split screen/normal chat.  For the
  Linux and OSX peeps that do not have a page sysop function.
- NNTP server completion
- MBBSCGI (or PHP DLL) [Grymmjack might have the only MBBSCGI copy]
- If not the above then finish the HTTP server?
- Rework code base to compile with newly released FPC (2.6.0).
- SDL versions of m_input and m_output and also use SDL if that becomes
  reality for the ability to play WAV/MP3/MIDI files etc as SysOp
  notification of events and pages.  Maybe someone else can take on creating
  a mimic of m_Output_Windows and m_Input_Windows using SDL?  This would
  benefit the entire FPC community, and not just Mystic.  NetRunner could
  also have a full screen mode in Windows, Linux, and OSX.
- Possibility of OS/2 port again?  Need to find a working OS/2 VMware in
  order to do this.  Once MDL is ported over it should almost just work.
- How feasible is an Amiga port?  Can an emulator on the PC side be good
  enough to use as a development environment?  How reliable/complete is FPC
  for Amiga?  Does anyone even care? :)
- MBBSTOP rewrite
- MVIEW rewrite to mimic oldskool AcidView type deals, which would be amazing
  combined with the SDL stuff if that happens.
- Mystic-DOS rewrite or just code a file manager which would probably be a
  lot nicer using the new ANSI UI.  Combined with the text/ansi editor a
  SysOp would never need to use anything else to draw/maintain their setup
  even from a remote telnet connection in Windows, if desired.
- MIDE version using the Lazaurs GUI editor [Spec].   Maybe he would be
  interested in working on that?
- PCBoard-style "quickscan"?  Yes?  No?
- Filebase allow anonymous flag for FTP or just use FreeFiles
- Build in "telnetd" STDIO redirection into MIS in Linux/OSX
