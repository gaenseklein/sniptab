# insert jsdoc emmet

move your cursor to where you want to insert your emmet, open micro command prompt and type "jsdoc" 
followed by your emmet. 
the structure flow is name .type "description". 
you can use > and + and ^ like in html emmet. 
if you use quotes or spaces dont forget to put your emmet into single-quotes.

style-sheet: 
## basic
> jsdoc 'name.string"my name"'
 * @param {string} name - description

## object with childs
> jsdoc 'objectname.object"description">name.string"description 1"+age.number"description 2"'
 * @param {Object} objectname - description
 * @param {string} objectname.name - description 1
 * @param {number} objectname.age - description 2

## multiple params with +
> jsdoc name.string+age.number
 * @param {string} name - ${0}
 * @param {number} age - ${0} 

## multiple params with ,
> jsdoc name.string,age.number
 * @param {string} name - ${0}
 * @param {number} age - ${0}

## multiple params with object with childs, going up with ^
> jsdoc player.object>name.string,age.number^,ball.object
 * @param {Object} player - ${0}
 * @param {string} player.name - ${0}
 * @param {number} player.age - ${0}
 * @param {Object} ball - ${0}
 
## .type# = array of type:
> jsdoc 'namelist.object#>name.string"description 1"+department.string"description 2"'
 * @param {Object[]} namelist -${0}
 * @param {string} namelist[].name - description 1
 * @param {string} namelist[].department - description 2
 
## ? = optional
> jsdoc name.string?
 * @param {string} [name] - ${0}
 
## one type or another: add more classes to it:
> jsdoc name.string.string#
 * @param {(string|string[])} - ${0}

## any type = *
> jsdoc 'name.*"description"'
 * @param {*} name - description

## repeating parameter = $
> jsdoc name.number$
 * @param {...number} name - ${0}

## callback:
> jsdoc name.callback
 * @callback name
 
## return: 
> jsdoc '=.type"description"'
 * @returns {type} description

## return multiple types:
> jsdoc '=.number.Array"description"'
 * @returns {(number|Array)} description

##  returns a promise:
>  jsdoc =promise.number
 * @returns {Promise<number>} description

##  type definition:
>  jsdoc 'typename.typedef.object>id.string"an id"+name.string"your name"+age.number"your age"'
 * @typedef typename
 * @type {object}
 * @property {string} id - an id
 * @property {string} name - your name
 * @property {number} age - your age
