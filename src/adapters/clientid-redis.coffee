module.exports = (racer) ->
  racer.adapters.clientId.Redis = ClientIdRedis

ClientIdRedis = (@_options) ->
  return

ClientIdRedis::generateFn = ->
  {redisClient} = @_options
  return (callback) ->
    redisClient.incr 'clientClock', (err, val) ->
      return callback err if err
      clientId = val.toString(36)
      callback null, clientId
