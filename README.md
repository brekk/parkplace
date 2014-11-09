parkplace
=========

A property definer. (parkplace is a good definition of a property.)

    npm install parkplace --save

At a base level, parkplace is a wrapper around the ES5 [Object.defineProperty][] function (it will fall back to simply assigning properties in a pre-ES5 environment).

    # coffeescript:
    pp = require 'parkplace'
    someObjectToDefinePropertiesOn = {}
    pp.define 'someProp', 'someValue', {
        enumerable: true
        writable: true
        configurable: true
    }, someObjectToDefinePropertiesOn

    # javascript:
    pp = require('parkplace');
    someObjectToDefinePropertiesOn = {};
    pp.define('someProperty', 100, {
        enumerable: true,
        writable: true,
        configurable: true
    }, someObjecToDefinePropertiesOn);

by calling scope, we get a copy of the base parkplace with some additional convenience methods (`get` and `has`) but we no longer have to specify which object we are defining properties on (the last parameter of `define`, above):

    # coffeescript:
    scoped = pp.scope someObject
    # (I like to use a triple-underscore, but you do you.)
    ___ = pp.scope someObject
    ___.define 'someProp', 'someValue', {
        enumerable: true
        writable: true
        configurable: true
    }
    # the last parameter can now be omitted (as compared to the earlier example, above)

    # javascript
    ___ = pp.scope(someObject);
    ___.define('someProp', 'someValue', {
        enumerable: true,
        writable: true,
        configurable: true
    }/* omitted param would go here */);

In addition to the base define function, there are nearly the permutations for the the second-to-last parameter of `define` above:

*  `mutable` - enumerable, writable, configurable (essentially an alias of `define`)
*  `private` - non-enumerable, writable, non-configurable
*  `readable` - enumerable, non-writable, non-configurable
*  `public` - enumerable, non-writable, configurable
*  `writable` - enumerable, writable, non-configurable
*  `constant` - non-enumerable, non-writable, non-configurable
*  `protected` - enumerable, writable, configurable

(I didn't see much purpose in a non-enumerable, writable, configurable property, as it feels like a secret API, but perhaps one can be added in the future. And if you want a truly private context, use `hidden` below.)

So, all together now:

    # coffeescript
    "use strict"
    someObject = {}
    # now we make a definer
    ___ = require('parkplace').scope someObject

    ___.constant 'PI', Math.PI
    console.log someObject.PI is Math.PI       # prints true

    ___.public 'name', 'publizity'
    console.log Object.keys someObject         # prints ['name']

    ___.private 'license', "KFBR392"
    console.log Object.keys someObject         # prints []

    # maybe in some other file, down the line
    ___.mutable 'license', "somenewvalue"      # throws TypeError: Cannot redefine property: license

The scoped definer also has the convenience methods `has` which returns a boolean (true if property is defined) and `get`, which returns the matched value or `null`:

    console.log ___.has 'license'                        # prints true
    console.log ___.get 'license'                        # prints 'KFBR392'

    console.log ___.get('license') is someObject.license # prints true




[Object.defineProperty]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/defineProperty (Object.defineProperty)