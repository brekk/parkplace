# It's called Park Place, because that's a good definition of a property

"use strict"
_ = require 'lodash'

pp = {}

(->
# this is for things that are scoped out of any context
# enumerable or otherwise (and are therefore truly private)
hiddenContext = {}
pp.hidden = (prop, value, force=false)->
    if !hiddenContext[prop]? or force
        @define prop, value, {}, hiddenContext
        return true
    return false

# if there's a hidden property, use this function to find it
pp.lookupHidden = (key)->
    if hiddenContext[key]?
        return hiddenContext[key]
    return
)()

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
        scope = @lookupHidden 'scope'
        if scope?
            onObject = scope
    unless _.isObject onObject
        throw new TypeError "Attempted to define property on non-object. Consider using parkplace.scope(context)."
    if _.isFunction Object.defineProperty
        Object.defineProperty onObject, prop, settings
    else
        onObject[prop] = value

pp.getSet = (prop, getSet, settings, onObject)->
    settings = _.assign {
        enumerable: true
        writable: true
        configurable: true
    }, settings
    # for convenience, the onObject passes through the scope function's wrapper
    # so that you don't have to establish a separate variable for it
    unless _.isObject onObject
        scope = @lookupHidden 'scope'
        if scope?
            onObject = scope
    unless _.isObject onObject
        throw new TypeError "Attempted to define property on non-object. Consider using parkplace.scope(context)."
    if !_.isObject(getSet) or !(getSet.get? or getSet.set?)
        throw new TypeError "getSet expects a hash which contains either .get or .set or both."
    if getSet.get? and !_.isFunction getSet.get
        throw new TypeError "Expected .get to be a function."
    if getSet.set? and !_.isFunction getSet.set
        throw new TypeError "Expected .set to be a function."
    if _.isFunction Object.defineProperty
        Object.defineProperty onObject, prop, getSet, settings
    else
        throw new Error "Unable to define getters and setters, unsupported."


pp.scope = (ref)->
    # Now, the definitions:
    rescoped = _.clone pp
    # make it un-rescopable, 'cause that's confusing
    delete rescoped.scope
    # e: 1, w: 1, c: 1

    # mutable is a fixed-parameter version of define,
    # and essentially an alias
    rescoped.mutable = (prop, value, getSet=false)->
        args = [prop, value, {}, ref]
        if getSet
            return @getSet.apply @, args
        return @define.apply @, args

    # e: 0, w: 1, c: 0
    rescoped.secret = (prop, value, getSet=false)->
        settings = {
            enumerable: false
            writable: true
            configurable: false
        }
        args = [prop, value, settings, ref]
        if getSet
            return @getSet.apply @, args
        return @define.apply @, args

    # e: 1, w: 0, c: 1
    rescoped.open = (prop, value, getSet=false)->
        settings = {
            enumerable: true
            writable: false
            configurable: true
        }
        args = [prop, value, settings, ref]
        if getSet
            return @getSet.apply @, args
        return @define.apply @, args

    # e: 0, w: 0, c: 1
    rescoped.guarded = (prop, value, getSet=false)->
        settings = {
            enumerable: false
            writable: false
            configurable: true
        }
        args = [prop, value, settings, ref]
        if getSet
            return @getSet.apply @, args
        return @define.apply @, args

    # e: 1, w: 0, c: 0
    rescoped.readable = (prop, value, getSet=false)->
        settings = {
            enumerable: true
            writable: false
            configurable: false
        }
        args = [prop, value, settings, ref]
        if getSet
            return @getSet.apply @, args
        return @define.apply @, args

    # e: 1, w: 1, c: 0
    rescoped.writable = (prop, value, getSet=false)->
        settings = {
            enumerable: true
            writable: true
            configurable: false
        }
        args = [prop, value, settings, ref]
        if getSet
            return @getSet.apply @, args
        return @define.apply @, args

    # e: 0, w: 0, c: 0
    rescoped.constant = (prop, value, getSet=false)->
        settings = {
            enumerable: false
            writable: false
            configurable: false
        }
        args = [prop, value, settings, ref]
        if getSet
            return @getSet.apply @, args
        return @define.apply @, args

    rescoped.has = (property, andHidden=false)->
        hasOwn = ref[property]?
        unless andHidden
            return hasOwn
        return hasOwn or @lookupHidden(property)?

    rescoped.get = (property, andHidden=false)->
        if @has property, andHidden
            unless andHidden
                return ref[property]
            else
                if @has property, andHidden
                    return @lookupHidden property
        return null
    rescoped.hidden 'scope', ref
    return rescoped

module.exports = pp
return pp