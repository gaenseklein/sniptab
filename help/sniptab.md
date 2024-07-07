# sniptab

a snippets-plugin to let you insert pre-configured snippets on the cursor location. 

## usage

### normal snippets 

- write your snippet-shortcut
- press tab (or whatever you have configured to use snippet-insert for)
- if snippet-shortcut is found snippet is inserted, cursor moves to first position of snippet if found
- if snippet has more then one cursor-position a second tab jumps to next cursor position
- arrowkeys, escape and enter leaves the current snippet (you cant jump anymore on tab)
- changing windows leaves the current snippet

alternatively you can open your micro-terminal with ctrl+e and type `snip $word` where $word is the 
shortcut for your snippet - example `snip div` to insert a div at current cursor-position

### emmet

- open your micro-terminal (`ctrl+e` by default)
- type your emmet preceded by "emmet " - for example:
>emmet button.load>img
- if your emmet contains spaces or quotes you have to put it inside quotes (use single outside and double inside)
- emmet is still not fully ready but works in simpler cases
- emmet only works for html right now 
- for further help with emmet see [emmet help page](emmet.md) or in your micro-command `>help emmet`

### jsdoc emmet

- open your micro-terminal (`ctrl+e` by default)
- type your jsdoc emmet preceded by "jsdoc " - for example:
>jsdoc player.object>name.string+score.number
- if your jsdoc-emmet contains spaces or quotes you have to put it inside quotes (use single outside and double inside)
- for further help with jsdoc-emmet see [jsdoc-emmet help page](jsdoc.md) or in your micro-command `>help jsdoc`


## snippet-definitions
- a snippet-file for the filetype is placed in the "snippets"-directory of the plugin
- a line starting with "snippet" starts a new snippet
- after a whitespace comes the shortcut of the snippet
- following codelines have to be preceded by a tab
- cursor-positions can be entered by `${number:filltext}` where `:filltext` is optional
- the numbers are not important - its parsed from first to last ignoring the actual number

- the pre-configured snippets are from the default "snippets"-plugin for micro, therefore its syntax is also used
- for now only one keyword per snippet-definition is allowed
- keywords in the text have to be first position in a line or preceded by a tab or whitespace to be parsed correctly

## alter snippet-definitions

`>edit-snip` in your micro-command-prompt opens the corresponding snippets-file for the current filetype. 
edit them, save them, continue working - no need to leave micro. 


# install 
install sniptab to your micro, for example go to your plugin directory of micro and clone this repo:
```
cd ~/.config/plug
git clone https://github.com/gaenseklein/sniptab
```

afterwards add sniptab.on_tab to your bindings.json (normaly in `~/.config/micro/bindings.json`) for tab, 
prefferably in the front.
the whole line could look something like this:
```
	"Tab": "lua:sniptab.on_tab|Autocomplete|IndentSelection|InsertTab"
```

alternatively you can add a shortcut to open the terminal prefixed with the "snip" keyword by: 
