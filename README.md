# ExtendScript Compiler

## Why?

To keep development of large ExtendScript projects easier to handle I split the projects into multiple files/modules which you will typically find in the `src` directory. This works great for me but is a pain for users to install. So, to make script installation as easy as possible I needed an automated way to get everything compiled into a single readable '.jsx' script file.

I could just export to a JSXBIN file but I like for my open source scripts to be human readable...

## How it works...

The script reads through the supplied script looking for any [ExtendScript Preprocessor Directives](https://extendscript.docsforadobe.dev/extendscript-tools-features/preprocessor-directives.html) and replaces them with contents from that file.

```bash
./compile.sh sample_jsx_project/src/script.jsx > sample_jsx_project/compiledScript.jsx
```

⚠️ You may need to make the script executable (`chmod +x compile.sh`) before running the command above.

## What can it detect?

This script tries to process `include` and `includepath` statements just as the ExtendScript engine does so that no changes have to be made to the source code.

### include file

Inserts the contents of the named file into this file at the location of this statement.

```javascript
#include "../include/lib.jsxinc"
//@include "../include/file.jsxinc"
```

If the file to be included cannot be found, the script throws an error.

### includepath path

One or more paths that the #include statement should use to locate the files to be included. The semicolon (;) separates path names.

If a `#include` file name starts with a slash (/), it is an absolute path name, and the include paths are ignored. Otherwise, the script attempts to find the file by prefixing the file with each path set by the `#includepath` statement.

```javascript
#includepath "include;../include"
#include "file.jsxinc"
//@includepath "include;../include"
//@include "file.jsxinc"
```

Multiple #includepath statements are allowed; the list of paths changes each time an #includepath statement is executed.