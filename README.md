WSDLtoJS
========

xslt to generate template JavaScript from Cascade Server WSDL

It runs. I haven't verified it is complete yet, but it is generating 10,542 lines of output.

It doesn't generate code that will pass JSLint yet. 
The main issue is missing commas when two separate implementations are next to each other.

I will use this to improve the [Grunt Cascade Examples Wiki](https://github.com/jraller/Grunt-Cascade-Examples/wiki).

# To Do

Fix the comma issue
Pull comments from in the WSDL context if possible and turn them into js comments.
