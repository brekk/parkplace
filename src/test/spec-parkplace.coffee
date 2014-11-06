assert = require 'assert'
should = require 'should'
_ = require 'lodash'
pp = require '../lib/parkplace'

(->
    "use strict"
    try
        fixture = require './fixture.json'
        boardwalk = fixture.base
        mutableDef = fixture.definitions.mutable
        privateDef = fixture.definitions.private
        publicDef = fixture.definitions.public
        writableDef = fixture.definitions.writable
        constantDef = fixture.definitions.constant
        protectedDef = fixture.definitions.protected
        hiddenDef = fixture.definitions.hidden
        zoningCommittee = null

        # reusable tests
        itShouldBarfIf = (sentence, fx, negative=false)->
            unless _.isString sentence
                throw new TypeError "Gimme a string for a sentence."
            unless _.isFunction fx
                throw new TypeError "Quit wasting time and gimme a function."
            negate = if negative then ' not' else ''
            it "should#{negate} throw an error if #{sentence}", ()->
                if negative
                    fx.should.not.throwError
                else
                    fx.should.throwError

        itShouldNotBarfIf = (s, f, n=true)->
            itShouldBarfIf s, f, n

        itShouldMaintainScope = ()->
            itShouldBarfIf '.scope has not been called', ()->
                pp.mutable 'test', 100
                return

        itShouldRemainUnconfigurable = (prop)->
            itShouldBarfIf 'configurable is false', ()->
                pp.mutable prop, Math.random() * 2000
                return

        itShouldRemainConfigurable = (prop)->
            itShouldNotBarfIf 'configurable is false', ()->
                pp.mutable prop, Math.random() * 2000
                return

        itShouldNotBeWritable = (prop)->
            itShouldBarfIf 'writable is false', ()->
                boardwalk[prop] = Math.round Math.random() * 2000

        itShouldBeWritable = (prop)->
            itShouldNotBarfIf 'writable is true', ()->
                boardwalk[prop] = Math.round Math.random() * 2000

        itShouldNotBeEnumerable = (method, x)->
            it 'should hide variables from enumerable scope', ()->
                zoningCommittee[method] x.prop, x.value
                Object.keys(boardwalk).should.not.containEql x.prop
                boardwalk.propertyIsEnumerable(x.prop).should.eql false

        itShouldBeEnumerable = (method, x)->
            it 'should show variables within enumerable scope', ()->
                zoningCommittee[method] x.prop, x.value
                Object.keys(boardwalk).should.containEql x.prop
                boardwalk.propertyIsEnumerable(x.prop).should.eql true

        describe 'Parkplace', ()->

            describe '.define', ()->

                simple = {}
                
                it 'should be a method of Parkplace', ()->
                    pp.define.should.be.ok
                    pp.define.should.be.a.Function
                
                it 'should define mutable properties with no other instructions', ()->
                    pp.define mutableDef.prop, mutableDef.value, null, simple
                    simple.should.have.property mutableDef.prop
                    simple.hasOwnProperty(mutableDef.prop).should.be.ok
                    simple[mutableDef.prop].should.equal mutableDef.value
                    (->
                        pp.define mutableDef.prop, Math.random()*10, null, simple
                    ).should.not.throwError
                
                it 'should throw an error if no scope object is given and .scope is not called', ()->
                    (->
                        pp.define 'test', Math.random() * 10
                    ).should.throwError
                
                it 'should not throw an error if no scope object is given and .scope has been called', ()->
                    (->
                        zap = {}
                        pzap = pp.scope zap
                        pzap.define 'test', Math.random() * 10
                    ).should.not.throwError

            describe '.scope', ()->
                
                it 'should create a definer with a given scope', ()->
                    zoningCommittee = pp.scope boardwalk
                    zoningCommittee.should.be.ok
                    zoningCommittee.should.have.properties 'define', 'mutable', 'private', 'writable', 'public', 'constant', 'protected'
                    zoningCommittee.should.not.have.properties 'hidden', 'lookupHidden', 'scope'
                
                it 'should add a .get and a .has method to the scoped definer', ()->
                    zoningCommittee.should.have.properties 'has', 'get'
                    pp.should.not.have.properties 'has', 'get'

            describe '.mutable', ()->
                # e: 1, w: 1, c: 1
                itShouldMaintainScope()

                it 'should allow properties to be defined', ()->
                    zoningCommittee.mutable mutableDef.prop, mutableDef.value
                    boardwalk[mutableDef.prop].should.be.ok

                itShouldNotBarfIf 'a property is redefined', ()->
                    zoningCommittee.mutable mutableDef.prop, 'zopzopzop'
                
                it 'should allow property definitions to be redefined', ()->
                    zoningCommittee.mutable mutableDef.prop, 'zopzopzop'
                    boardwalk[mutableDef.prop].should.be.ok
                    boardwalk[mutableDef.prop].should.eql 'zopzopzop'

                it 'should allow property values to be changed', ()->
                    hip3 = 'hiphiphip'
                    boardwalk[mutableDef.prop] = hip3
                    boardwalk[mutableDef.prop].should.eql hip3
                
            describe '.private', ()->
                # e: 0, w: 1, c: 0
                itShouldMaintainScope()
                itShouldNotBeEnumerable 'private', privateDef
                itShouldRemainUnconfigurable privateDef.value
                itShouldBeWritable privateDef.prop


            describe '.public ', ()->
                # e: 1, w: 0, c: 0
                itShouldMaintainScope()
                itShouldBeEnumerable 'public', publicDef
                itShouldRemainUnconfigurable publicDef.value
                itShouldNotBeWritable publicDef.prop

            describe '.writable', ()->
                # e: 1, w: 1, c: 0
                itShouldMaintainScope()
                itShouldBeEnumerable 'writable', writableDef
                itShouldRemainConfigurable writableDef.prop
                itShouldBeWritable writableDef.prop

            describe '.constant', ()->
                # e: 0, w: 0, c: 0
                itShouldMaintainScope()
                itShouldNotBeEnumerable 'constant', constantDef
                itShouldRemainUnconfigurable writableDef.prop
                itShouldNotBeWritable writableDef.prop

            describe '.protected', ()->
                # e: 0, w: 0, c: 1
                itShouldMaintainScope()
                itShouldNotBeEnumerable 'protected', protectedDef
                itShouldNotBeWritable protectedDef.prop
                itShouldRemainConfigurable protectedDef.prop

            describe '.hidden', ()->
                it 'should add hidden properties', ()->
                    pp.hidden hiddenDef.prop, hiddenDef.value

            describe '.scope().get', ()->
                it 'should allow access to existing properties', ()->
                    x = zoningCommittee.get mutableDef.prop
                    should(x).be.ok

                it 'should return null on non-extant properties', ()->
                    x = zoningCommittee.get 'jipjopple'
                    should(x).not.be.ok
                    should(x).eql null

                it 'should allow access to hidden scope', ()->
                    x = zoningCommittee.get hiddenDef.prop, true
                    x.should.be.ok
                    x.should.eql hiddenDef.value

            describe '.scope().has', ()->
                it 'should return false on a non-present value', ()->
                    x = zoningCommittee.has 'whatevernonrealsies'
                    (x).should.eql false

                it 'should return true on a present value', ()->
                    x = zoningCommittee.has hiddenDef.prop, true
                    (x).should.be.ok

            describe '.lookupHidden', ()->
                it 'should allow access to hidden values', ()->
                    x = pp.lookupHidden hiddenDef.prop
                    x.should.be.ok
                    x.should.eql hiddenDef.value


            # describe '.lookupHidden', ()->

    catch e
        console.log "Error during testing!", e
        if e.stack?
            console.log e.stack
).call @
