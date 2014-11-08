# It's called Park Place, because that's a good definition of a property

"use strict"
_ = require 'lodash'

pp = {}

# our define function is a simple wrapper around an Object.defineProperty call
# and we reuse this function in each of the methods below .scope
pp.define = (prop, value, settings, onObject)->
    unless value?
        throw new Error "Expected to be given value for property."
    settings = _.assign {
        enumerable: true
        writable: true
        configurable: true
        value: value
    }, settings
    # for convenience, the onObject passes through the scope function's wrapper
    # so that you don't have to establish a separate variable for it
    unless _.isObject onObject
        scope = pp.lookupHidden 'scope'
        if scope?
            onObject = scope
    unless _.isObject onObject
        throw new TypeError "Attempted to define property on non-object. Consider using parkplace.scope(context)."
    if _.isFunction Object.defineProperty
        Object.defineProperty onObject, prop, settings
    else
        onObject[prop] = value

pp.scope = (ref)->
    scopedDefinition = _.assign {}, pp
    # make it un-rescopable, 'cause that's confusing
    delete scopedDefinition.scope
    delete scopedDefinition.hidden
    delete scopedDefinition.lookupHidden
    scopedDefinition.has = (property, andHidden=false)->
        hasOwn = ref[property]?
        unless andHidden
            return hasOwn
        return hasOwn or pp.lookupHidden(property)?

    scopedDefinition.get = (property, andHidden=false)->
        if @has property, andHidden
            unless andHidden
                return ref[property]
            else
                if @has property, andHidden
                    return pp.lookupHidden property
        return null
    pp.hidden 'scope', ref
    return scopedDefinition

# Now, the definitions:

# e: 1, w: 1, c: 1
# mutable is a fixed-parameter version of define,
# and essentially an alias
pp.mutable = (prop, value)->
    pp.define prop, value

# e: 0, w: 1, c: 0
pp.private = (prop, value)->
    settings = {
        enumerable: false
        writable: true
        configurable: false
    }
    pp.define prop, value, settings

# e: 1, w: 0, c: 0
pp.readable = (prop, value)->
    settings = {
        enumerable: true
        writable: false
        configurable: false
    }
    pp.define prop, value, settings

# e: 1, w: 0, c: 1
pp.public = (prop, value)->
    settings = {
        enumerable: true
        writable: false
        configurable: true
    }
    pp.define prop, value, settings

# e: 1, w: 1, c: 0
pp.writable = (prop, value)->
    settings = {
        enumerable: true
        writable: true
        configurable: false
    }
    pp.define prop, value, settings

# e: 0, w: 0, c: 0
pp.constant = (prop, value)->
    settings = {
        enumerable: false
        writable: false
        configurable: false
    }
    pp.define prop, value, settings

# e: 0, w: 0, c: 1
pp.protected = (prop, value)->
    settings = {
        enumerable: false
        writable: false
        configurable: true
    }

# this is for things that are scoped out of any context
# enumerable or otherwise (and are therefore truly private)
hiddenContext = {}
pp.hidden = (prop, value, force=false)->
    if !hiddenContext[prop]? or force
        pp.define prop, value, {}, hiddenContext
        return true
    return false

# if there's a hidden property, use this function to find it
pp.lookupHidden = (key)->
    if hiddenContext[key]?
        return hiddenContext[key]
    return null

module.exports = pp
return pp