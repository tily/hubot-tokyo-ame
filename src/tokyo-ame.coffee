# Description:
#   A hubot script to notify rainfall intensity changes at some point in Tokyo
#
# Dependencies:
#   cron
#
# Configuration:
#   HUBOT_TOKYO_AME_LATITUDE
#   HUBOT_TOKYO_AME_LONGITUDE
#   HUBOT_TOKYO_AME_CHANNEL
#   HUBOT_TOKYO_AME_SCHEDULE - defaults to "* */5 * * * *"
#   HUBOT_TOKYO_AME_ENDPOINT - defaults to http://ame2.herouapp.com/intensity
#
# Author:
#   tily <tidnlyam@gmail.com>

cron = require('cron').CronJob

config =
  latitude: process.env.HUBOT_TOKYO_AME_LATITUDE
  longitude: process.env.HUBOT_TOKYO_AME_LONGITUDE
  channel: process.env.HUBOT_TOKYO_AME_CHANNEL
  around: process.env.HUBOT_TOKYO_AME_AROUND
  schedule: process.env.HUBOT_TOKYO_AME_SCHEDULE or "0 */5 * * * *"
  endpoint: process.env.HUBOT_TOKYO_AME_ENDPOINT or "http://ame2.herokuapp.com/intensity"
  descriptions: [
    "降雨なし"
    "より弱い雨"
    "弱い雨"
    "並の雨"
    "やや強い雨"
    "強い雨"
    "やや激しい雨"
    "激しい雨"
    "より激しい雨"
    "非常に激しい雨"
    "猛烈な雨"
  ]
module.exports = (robot) ->
  robot.respond /rainfall/, ()->
    crawl(notify)

  robot.respond /debug/, ()->
    robot.brain.set("prev", 5)

  location = ()->
    config.around or "here (https://maps.google.com/?q=" + config.latitude + "," + config.longitude + "&z=19)"

  crawl = (callback)->
    url = config.endpoint + '?latitude=' + config.latitude + '&longitude=' + config.longitude
    robot.http(url).get() (err, res, body) ->
      callback(body)

  notify = (body)->
    curr = body
    prev = robot.brain.get("prev")
    robot.logger.info("notify", curr, prev)
    if prev != null and curr != prev
      prev_desc = config.descriptions[prev]
      curr_desc = config.descriptions[curr]
      message = "Rainfall intensity changed from " + prev_desc + " to " + curr_desc + " around " + location() + "."
      robot.send {room: config.channel}, message
    robot.brain.set("prev", curr)

  new cron config.schedule, (-> crawl(notify)), null, true, "Asia/Tokyo"
