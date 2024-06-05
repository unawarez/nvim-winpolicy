# nvim-winpolicy

Experiment in making the editing experience not suck when maximized on an
ultrawide montior.

Currently, just makes a scratch window to the left of the main window. The
`WinResize` event is watched in order to declaratively auto-resize/close/create
said scratch window, keeping the main window in a place where if it were 80
characters wide it would be centered.

This is also maybe a long-term project in declarative Neovim window management,
hence the name "winpolicy".
