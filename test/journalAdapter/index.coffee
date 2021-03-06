{expect} = require '../util'
{adapter} = require '../util/store'

module.exports = adapter 'journal', (run) ->

  run 'commit', run.allModes, require './commit'
  run 'STM commit', run.stm, require './stmCommit'

  run 'journal flushing', (getStore) ->
    it 'should reset the version', (done) ->
      store = getStore()
      store.set 'color', 'green', 1, (err) ->
        expect(err).to.be.null()
        store._journal.version (err, ver) ->
          expect(ver).to.be(1)
          store.flush (err) ->
            expect(err).to.be.null()
            store._journal.version (ver) ->
              expect(ver).to.not.be.ok()
              done()

    it 'should return an error if the journal fails to flush', (done) ->
      store = getStore()
      store._journal.flush = (callback) ->
        callback new Error
      store.flushJournal (err) ->
        expect(err).to.be.an Error
        done()
