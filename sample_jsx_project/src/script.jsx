// sample script file

// DATA FROM THE BASE SCRIPT FILE
alert("code from base script");

//@includepath "include;another_module"
//@include "include1.jsxinc"
#include "include2.jsxinc"
//@include "include3.jsxinc"
#include "include4.jsxinc"
//@include "include5.jsxinc"

// testing indentation and single quotes capture
if (true) {
  #includepath '../include'
  #include "include6.jsxinc"
  #include '/Users/jbd/Dropbox/DEV/projects/extend-script-compiler/sample_jsx_project/polyfills/include7.jsxinc'
}

// MORE DATA FROM WITHIN THE BASE SCRIPT
alert("more code from base script");
