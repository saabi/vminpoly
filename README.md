vminpoly
========

A polyfill for CSS units vw, vh &amp; vmin.

Simple online [demo](http://saabi.github.com/vminpoly) right here. A more sophisticated [responsive demo](http://saabi.github.com/vminpoly/demo2.html) demonstrating vw/vh/vmin units along with *media queries*, working right down to IE5.5 on the desktop and Opera Mini on mobiles!! (In Opera Mini the browser must be refreshed after changing phone orientations as it appears it doesn't trigger the window resize event)

This is a working proof of concept right now. There's a lot of cleanup to do on the code.

Since most browsers ignore rules they don't understand, the code must load and parse the original CSS sourcecode. It does this using a javascript [CSS parser](https://github.com/tabatkins/css-parser). Once this is done, it filters the generated tree leaving only rules that use 'vh', 'vw' & 'vmin' units.
At window resize time, it generates CSS code for the 'px' equivalents and appends it in a 'style' element at the end of the 'head' element. The generated code respects media queries.

As it is, it's fast enough for a lot of cases, but the code can still be optimized greatly, both in parsing and in resizing.

Also, any suggestions on how to better organize the repo, specially with respect to third party code, is greatly appreciated.

Notes
-----
* It's working fine in IE5.5+, Firefox, Opera and even Opera Mini, which doesn't support any of the units or media queries. Chrome, Safari and the Firefox beta don't need it.
* Well... Chrome and Safari actually can benefit from it as they don't properly handle font-size natively while resizing the window.


TODO:
-----

* IE9 and IE10 support vw, vh & vm, so the code should only translate 'vmin' units to 'vm'
* Only linked stylesheets are being parsed right now but it's very easy to also parse 'style' elements.
* Also, recursively parse @import rules.
* Add some more examples of what can be achieved.

In short, the only browser with apparently full native support right now is Firefox beta (Aurora). The rest will benefit from this polyfill immediately, even without the badly needed code polishing.

Latest Changes:
---------------

* After some bug fixes it finally works down to **IE5.5 on the desktop** and **Opera Mini on mobile**!!
* Also, I removed the dependency on jQuery.
* Now resizes correctly right after page load.
* Media query support!! (rudimentary, but check out the [new demo!](http://saabi.github.com/vminpoly/demo2.html))
* Right now, media queries only apply to rules with vw,vh/vmin units. Other rules won't be applied just yet. More to come...
