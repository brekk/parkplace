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
        secretDef = fixture.definitions.secret
        readableDef = fixture.definitions.readable
        openDef = fixture.definitions.open
        writableDef = fixture.definitions.writable
        constantDef = fixture.definitions.constant
        guardedDef = fixture.definitions.guarded
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

            describe '.getSet', ()->
                simple = {}
                it 'should be a method of Parkplace', ()->
                    pp.getSet.should.be.ok
                    pp.getSet.should.be.a.Function

                it 'should define mutable getters and setters with no other instructions', ()->
                    rando = Math.round(Math.random() * 20000) + "KFBR392"
                    pp.scope simple
                    pp.getSet mutableDef.prop, {
                        get: ()->
                            return rando
                    }
                    simple.should.have.property mutableDef.prop
                    simple.hasOwnProperty(mutableDef.prop).should.be.ok
                    simple[mutableDef.prop].should.equal rando
                    (->
                        y = Math.round(Math.random() * 2000)
                        pp.getSet mutableDef.prop, {
                            set: (x)->
                                y = x
                                return y + "KFBR392"
                            get: ()->
                                return y + "KFBR392"
                        }
                    ).should.not.throwError

            describe '.scope', ()->
                
                it 'should create a definer with a given scope', ()->
                    zoningCommittee = pp.scope boardwalk
                    zoningCommittee.should.be.ok
                    zoningCommittee.should.have.properties 'define', 'mutable', 'secret', 'writable', 'open', 'constant', 'guarded', 'writable'
                    zoningCommittee.should.not.have.properties 'hidden', 'lookupHidden', 'scope'

                it 'should not leak definitions across scopes', ()->
                    zoningCommittee = pp.scope boardwalk
                    zoningCommittee.mutable mutableDef.prop, mutableDef.value
                    zoningCommittee.readable readableDef.prop, readableDef.value
                    zoningCommittee.open openDef.prop, openDef.value
                    zoningCommittee.writable writableDef.prop, writableDef.value
                    zoningCommittee.constant constantDef.prop, constantDef.value
                    zoningCommittee.guarded guardedDef.prop, guardedDef.value
                    (->
                        someOtherZone = pp.scope {
                            name: "marvin gardens"
                        }
                        someOtherZone.mutable mutableDef.prop, mutableDef.value
                        someOtherZone.readable readableDef.prop, readableDef.value
                        someOtherZone.open openDef.prop, openDef.value
                        someOtherZone.writable writableDef.prop, writableDef.value
                        someOtherZone.constant constantDef.prop, constantDef.value
                        someOtherZone.guarded guardedDef.prop, guardedDef.value
                    ).should.not.throwError
                    (->
                        noFlexZone = pp.scope {
                            name: "reading railroad"
                        }
                        noFlexZone.mutable mutableDef.prop, mutableDef.value
                        noFlexZone.readable readableDef.prop, readableDef.value
                        noFlexZone.open openDef.prop, openDef.value
                        noFlexZone.writable writableDef.prop, writableDef.value
                        noFlexZone.constant constantDef.prop, constantDef.value
                        noFlexZone.guarded guardedDef.prop, guardedDef.value
                    ).should.not.throwError
                
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
                
            describe '.secret', ()->
                # e: 0, w: 1, c: 0
                itShouldMaintainScope()
                itShouldNotBeEnumerable 'secret', secretDef
                itShouldRemainUnconfigurable secretDef.value
                itShouldBeWritable secretDef.prop

            describe '.readable', ()->
                # e: 1, w: 0, c: 0
                itShouldMaintainScope()
                itShouldBeEnumerable 'readable', readableDef
                itShouldRemainUnconfigurable readableDef.value
                itShouldNotBeWritable readableDef.prop

            describe '.open ', ()->
                # e: 1, w: 0, c: 1
                itShouldMaintainScope()
                itShouldBeEnumerable 'open', openDef
                itShouldRemainConfigurable openDef.value
                itShouldNotBeWritable openDef.prop

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

            describe '.guarded', ()->
                # e: 0, w: 0, c: 1
                itShouldMaintainScope()
                itShouldNotBeEnumerable 'guarded', guardedDef
                itShouldNotBeWritable guardedDef.prop
                itShouldRemainConfigurable guardedDef.prop

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

    catch e
        console.log "Error during testing!", e
        if e.stack?
            console.log e.stack
).call @
