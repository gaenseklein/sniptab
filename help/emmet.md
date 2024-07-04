# emmet 

this plugin tries to bring the [emmet.io](emmet.io) [cheat sheets](https://docs.emmet.io/cheat-sheet/) to micro.
with the emmet-syntax you can write simple to complex html-structures in a short way.

what it supports from the cheat-sheet:
* ID: `#` example: `p#chapter` => `<p id="chapter"></p>`
* Class: `.` example: `span.invisible` => `<span class="invisible"></span>`
* Child: `>` example: `ul>li` => `<ul><li></li></ul>`
* Sibling: `+` example: `ul>li+li` => `<ul><li></li><li></li></ul>`
* Climb-up:`^` example: `ul>li^p` => `<ul><li></li></ul><p></p>` 
* Multiplication: `*` example: `ul>li*3` => `<ul><li></li><li></li><li></li></ul>`
* Item numbering: `$` example: `li.item$*3` => `<ul><li class="item1"></li><li class="item2"></li><li class="item3"></li></ul>`
* Without End: `/` example: `img/` => `<img>`
* Custom Attributes: `[]` example: `a[href="test.md"]` => `<a href="test.md"></a>`
* Text: `{}` example: `button{click me}` => `<button>click me</button>`
* Abbreviations: (`img` => `img[src]/` => `<img src="">`)
* implicit tag names:
	div:  `.class` => `<div class="class"></div>`
	ul: `ul>.item` => `<ul><li class="item"></li></ul>`
	em: `em>.item` => `<em><span class="item"></span></em>`
	table: `table>.row>.cell` => `<table><tr class="row"><td class="cell"></td></tr></table>`

what it lacks in support:
* Grouping:`()`
* Recursive abbreviations: (`!` => `!!!+html`)
* CSS