## vitag

A script for Mac OS X (10.9+) that reads files and folder paths and their current tags into a text document, opens it in an editor, and applies any tag changes when the file is saved and closed.

### Installation

Copy `vitag` into a folder in your path and make it executable (`chmod ug+x vitag`).

*I may make this available as a gem eventually, but it currently has no non-standard dependencies and is pretty damn simple. Trying to keep it that way...*

### Usage 

`vitag [options] [path]`

A list of files with their current tags following the path in square brackets will open in your editor. 

1. Modify the content between the square brackets with a comma-separated list (leading/trailing whitespace ignored). 
2. Save and close the file

That's it. A little text editor magic with search and replace can make batch file/folder tagging with conditional filters a breeze.

### Options

    -d, --depth DEPTH          Level of nested directories to include (default 0, current only)
    -f, --filter GLOB_PATTERN  Only modify files matching GLOB_PATTERN (case insensitive)
    -I                         When used with -f, make case sensitive
    -e, --editor EDITOR        Force editor to use (default $EDITOR)
    -v, --verbose LEVEL        Level of debug messages to output
    -h, --help                 

By default it will use, in order of preference, \$EDITOR, `vim`, or `vi`, determined by the first available executable found. Specify an editor directly with `-e`/`--editor`.

If no path argument is given, it uses the current working directory.

With no depth flag, it will search the current directory for both files and folders. Adding `-d X`/`--depth X` (where X is an integer) will search nested directories with 1 being the root of folders within the current path. There's currently no error checking on maximum file count, so err on the conservative side.

`-f`/`--filter` can be any shell glob pattern, e.g. "*.pdf". It defaults to case-insensitivity, but you can use the `-I` switch to force it.

### Examples

Tagging folders in my base project directory

    $ vitag -f "nv*"

Opens vim with a temp file containing:

    nv []
    nvremind []
    nvremindapp []

If I edit that to be:

    nv [@nvalt,cocoa]
    nvremind [@nvremind,nvalt,ruby]
    nvremindapp [@nvremindapp,cocoa]

When I save and close, my tags will be:

    $ tag -l nv*
    nv                              @nvalt,cocoa
    nvremind                        @nvremind,nvalt,ruby
    nvremindapp                     @nvremindapp,cocoa

By the way, if you're tagging on the command line, don't do it without [tag](https://github.com/jdberry/tag) (available through homebrew, `brew install tag`). This script would be a lot faster if I used `tag` or an Obj-C implementation directly instead of looping through `mdls` and `xargs` calls, but I didn't want to add dependencies off the bat. I may add the option if it starts frustrating me.
