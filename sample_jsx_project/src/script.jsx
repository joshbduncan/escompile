// sample script file

// DATA FROM THE BASE SCRIPT FILE
alert("code from base script before imports");

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
  #include '/Users/jbd/Dropbox/DEV/projects/escompile/sample_jsx_project/polyfills/include7.jsxinc'
}

// testing nested relative includes
if (true) {
  if (true) {
    if (true) {
      if (true) {
        //@include "../nesting/include98.jsxinc"
      }
    }
  }
}

// MORE DATA FROM WITHIN THE BASE SCRIPT
alert("more code from base script after imports");
