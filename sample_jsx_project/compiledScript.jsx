// sample script file

// DATA FROM THE BASE SCRIPT FILE
alert("code from base script before imports");

// file: include1.jsxinc
alert("code from include1.jsxinc");

// file: nested_include1.jsxinc
alert("code from nested_include1.jsxinc");

alert("more code from include1.jsxinc after nested import of nested_include1.jsxinc");
// file: include2.jsxinc
alert("code from include2.jsxinc");
// file: include3.jsxinc
alert("code from include3.jsxinc");

// file: nested_include2.jsxinc
alert("code from nested_include2.jsxinc");

alert("more code from include3.jsxinc after import of nested_include2.jsxinc");
// file: include4.jsxinc
alert("code from include4.jsxinc");
// file: include5.jsxinc
alert("code from include5.jsxinc");

// testing indentation and single quotes capture
if (true) {
  // file: include6.jsxinc
alert("code from include6.jsxinc");
  // file: include7.jsxinc
alert("code from include7.jsxinc");
}

// MORE DATA FROM WITHIN THE BASE SCRIPT
alert("more code from base script after imports");
