{expect} = require '../util'
{BrowserModel: Model} = require '../util/model'

describe 'Model.fn', ->

  it 'supports get with single input', ->
    model = new Model
    model.set 'arg', 3
    out = model.fn '_out', 'arg', (arg) -> arg * 5
    expect(out).to.eql 15
    expect(model.get '_out').to.eql 15

  it 'supports get with multiple inputs', ->
    model = new Model
    model.set 'arg1', 3
    model.set 'arg2', 5
    out = model.fn '_out', 'arg1', 'arg2', (arg1, arg2) -> arg1 * arg2
    expect(out).to.eql 15
    expect(model.get '_out').to.eql 15

  it 'updates on input set and del', ->
    model = new Model
    model.set 'arg1', 3
    model.set 'arg2', 5
    model.fn '_out', 'arg1', 'arg2', (arg1, arg2) -> arg1 * arg2

    model.set 'arg1', 4
    expect(model.get '_out').to.eql 20

    model.del 'arg2'
    expect(model.get '_out').to.be.NaN()

    model.set 'arg2', 7
    expect(model.get '_out').to.eql 28

  it 'updates on property change of input', ->
    model = new Model
    model.set 'items', [1, 2, 3]
    model.fn '_reversed', 'items', (items) -> items.slice().reverse()

    expect(model.get 'items').to.specEql [1, 2, 3]
    expect(model.get '_reversed').to.specEql [3, 2, 1]

    model.set 'items.2', 4
    expect(model.get 'items').to.specEql [1, 2, 4]
    expect(model.get '_reversed').to.specEql [4, 2, 1]

  it 'updates on nested property of input', ->
    model = new Model
    model.set 'items', [
      {score: 0, name: 'x'}
      {score: 2, name: 'y'}
      {score: 1, name: 'z'}
    ]
    model.fn '_sorted', 'items', (items) ->
      items.slice().sort (a, b) -> a.score - b.score

    expect(model.get 'items').to.specEql [
      {score: 0, name: 'x'}
      {score: 2, name: 'y'}
      {score: 1, name: 'z'}
    ]
    expect(model.get '_sorted').to.specEql [
      {score: 0, name: 'x'}
      {score: 1, name: 'z'}
      {score: 2, name: 'y'}
    ]

    model.set 'items.0.score', 10
    expect(model.get 'items').to.specEql [
      {score: 10, name: 'x'}
      {score: 2, name: 'y'}
      {score: 1, name: 'z'}
    ]
    expect(model.get '_sorted').to.specEql [
      {score: 1, name: 'z'}
      {score: 2, name: 'y'}
      {score: 10, name: 'x'}
    ]

  it 'emits a set event when an input changes', (done) ->
    model = new Model
    model.set 'arg1', 3
    model.set 'arg2', 5
    model.fn '_out', 'arg1', 'arg2', (arg1, arg2) -> arg1 * arg2

    model.on 'set', '_out', (value, previous, isLocal) ->
      expect(value).to.equal 5
      expect(previous).to.equal 15
      expect(isLocal).to.equal true
      done()

    model.set 'arg1', 1

  it 'has no effect after being deleted', ->
    model = new Model
    model.set 'arg1', 3
    model.set 'arg2', 5
    model.fn '_out', 'arg1', 'arg2', (arg1, arg2) -> arg1 * arg2
    expect(model.get '_out').to.equal 15

    model.del '_out'
    expect(model.get '_out').to.equal undefined

    model.set 'arg1', 1
    expect(model.get '_out').to.equal undefined

  it 'has no effect after its parent is deleted', ->
    model = new Model
    model.set 'arg1', 3
    model.set 'arg2', 5
    model.fn 'stuff._out', 'arg1', 'arg2', (arg1, arg2) -> arg1 * arg2
    expect(model.get 'stuff._out').to.equal 15

    model.del 'stuff'
    expect(model.get 'stuff._out').to.equal undefined

    model.set 'arg1', 1
    expect(model.get 'stuff._out').to.equal undefined

  it 'has no effect after its parent is set to something else', ->
    model = new Model
    model.set 'arg1', 3
    model.set 'arg2', 5
    model.fn 'stuff._out', 'arg1', 'arg2', (arg1, arg2) -> arg1 * arg2
    expect(model.get 'stuff._out').to.equal 15

    model.set 'stuff', {_out: 'new stuff'}
    expect(model.get 'stuff._out').to.equal 'new stuff'

    model.set 'arg1', 1
    expect(model.get 'stuff._out').to.equal 'new stuff'

  it 'is not removed when its output should be NaN', ->
    model = new Model
    model.set 'arg1', 3
    model.set 'arg2', undefined
    model.set 'arr', []
    model.fn 'arr.0._out', 'arg1', 'arg2', (arg1, arg2) -> arg1 * arg2

    model.set 'arg1', 1
    expect(model.get 'arr.0._out').to.be.NaN()
    model.push 'arr', 'stuff'
    model.set 'arg1', 2
    expect(model.get 'arr.0._out').to.be.NaN()
    model.set 'arg2', 7
    expect(model.get 'arr.0._out').to.equal 14

  it 'supports specifying path via model.at', ->
    model = new Model
    out = model.at '_out'
    model.set 'arg', 5
    out.fn 'arg', (arg) -> arg * 2
    expect(model.get '_out').to.equal 10
