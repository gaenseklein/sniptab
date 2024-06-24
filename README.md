# sniptab
a simple snippets-plugin for the [micro editor](https://github.com/zyedidia/micro) to let you insert pre-configured snippets on the cursor location. 
it is meant to replace the standard ["snippets plugin"](https://github.com/micro-editor/updated-plugins/tree/master/micro-snippets-plugin), which 
unfortunately is abandoned since a while. 
but as the flow-logik is different for my use-case its nearly a complete rewrite

## differences to the standard snippet plugin
- it inserts on tab 
- it changes cursor-position only downwards
- no state-control whatsoever - whats inserted is inserted. if you dont like whats been inserted use ctrl+z
- snippet-shortcuts can be preceded by tab and whitespaces 
- it pre-intends following lines if snippet has more then one line
- arrow-keys, enter, escape leaves current snippet

## usage
- write your snippet-shortcut
- press tab (or whatever you have configured to use snippet-insert for)
- if snippet-shortcut is found snippet is inserted, cursor moves to first position of snippet if found
- if snippet has more then one cursor-position a second tab jumps to next cursor position
- arrowkeys, escape and enter leaves the current snippet (you cant jump anymore on tab)
- changing windows leaves the current snippet


## install 
install sniptab to your micro, for example go to your plugin directory of micro and clone this repo:
```
cd ~/.config/plug
git clone https://github.com/gaenseklein/sniptab
```

## configuration
add sniptab.on_tab to your bindings.json (normaly in `~/.config/micro/bindings.json`) for tab, 
prefferably in the front.
the whole line could look something like this:
```
	"Tab": "lua:sniptab.on_tab|Autocomplete|IndentSelection|InsertTab"
```

## known issues
- pageup, pagedown and start/pos1 are not recognized and therefore the current snippet is not left
- other movement-handlers (for example by micro) have the same issue