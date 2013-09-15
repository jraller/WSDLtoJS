WSDLtoJS
========

xslt to generate template JavaScript from Cascade Server WSDL

This tool is designed to translate the Cascade Server WSDL into JavaScript while preserving the inline comments. 
The intention is to make it easier for web developers to read the WSDL (which requires a lot of jumping around 
a large file to follow) in a language that hopefully is familiar to them. In addition this should provide some handy 
reference for anyone using the [soap-cascade](https://github.com/jraller/soap-cascade) library.

It runs. I haven't verified it is complete yet (as of 2013/9/14), but it is generating 16,292 lines of output.

The code it is generating does pass JSLint, it has not been field verified for all arguments. When in question 
consult the raw WSDL.

I will use this to improve the [Grunt Cascade Examples Wiki](https://github.com/jraller/Grunt-Cascade-Examples/wiki).

# To Do

- [x] Fix the comma issue
- [x] Pull comments from in the WSDL context if possible and turn them into js comments.
- [ ] Share with the larger community at the Cascade Server Users Conference.
