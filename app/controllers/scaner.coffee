#mongoose = require 'mongoose'
request = require 'request'
async = require 'async'
config = require './googleConfig.coffee'
GooglePlaces = require 'googleplaces'
qs = require 'querystring'
_ = require 'underscore'
_.mixin require('underscore.deferred')

cronJob = require("cron").CronJob

#mongoose.connect 'mongodb://localhost/dunice-google-project'

class GooglePlacesWrapper

  constructor: ({apiKey, outputFormat})->
    @requests = 0
    @googlePlaces = new GooglePlaces apiKey, outputFormat
    @defer = new _.Deferred
    new cronJob("*/4 * * * * *", =>
#    new cronJob("15 0 * * * *", =>
#      console.log 'resolve'
      @defer.resolve()
    , null, true, "America/Los_Angeles")

  _continue: (cb)->
    return (response)=>
#      if Math.random()>0.3
#        response.status = 'not OK'
#      console.log 'status', response.status
      next = response.status is 'OK'
      if next
        cb.apply @, arguments
      else
        args = arguments
        @defer = new _.Deferred
        _.when(@defer).done =>
#          console.log 'next'
          cb.apply @, args

  _placeSearch: (params, cb)->
    @googlePlaces.placeSearch params, @_continue(cb)

  _placeDetailsRequest: (place, cb)->
    @googlePlaces.placeDetailsRequest place, @_continue(cb)

  getDetails: (place, cb)->
    @_placeDetailsRequest {reference:place.reference}, (response) ->
#      return console.log 'response', response
      rightPlace = unless _.isUndefined(response.result.website) then response.result else null
      cb? null, rightPlace

  getRightPlaces: (params, cb)->
    @_placeSearch params, (response) =>
      places = response.results
      funcs = _.map places, (place)=>
        (cb)=>
          @getDetails place, (err, rightPlace)->
            console.log '===new place'
            cb err, rightPlace
      async.series funcs, (errors, results)->
        rightPlaces = _.filter results, (place)-> place?
        cb null, rightPlaces


gpw = new GooglePlacesWrapper config
contacts = []
gpw.getRightPlaces {
  location: [32.048243,-81.101074],
  radius: 1000,
}, (err, places)->
#  console.log 'done', places #, {err, places}
  _.each places, (place, index) ->
    contact = {}
    contact.name = place.name
    contact.website = place.website

    if !place.formatted_address
      contact.adress = 'Not exist'
    else
      contact.adress = place.formatted_address

    if !place.formatted_phone_number
      contact.phone = 'Not exist'
    else
      contact.phone = place.formatted_phone_number
    contacts.push(contact)

#  businessSchema = new Schema {
#    name: String,
#    adress: String,
#    phone: String,
#    website: String,
#    pageSpeedDesktop: String,
#    pageSpeedMobile: String
#  }
#
#  Business = mongoose.model 'Business', businessSchema

  async.each contacts, (item) ->
    queryOptions = {
      method: 'GET',
      url: item.website,
      key: config.apiKey
    }
    query = qs.stringify queryOptions

#    request {uri: config.pageSpeed + query + config.pageSpeedDesktop}, (err, resDesktop) ->
#      if !err && resDesktop.statusCode == 200
#        console.log '-------------->', resDesktop

#    request {uri: config.pageSpeed + query + config.pageSpeedMobile}, (err, resMobile) ->
#      if !err && resMobile.statusCode == 200
#        console.log '-------------->', resMobile

    request {uri: item.website}, (err, response) ->
      if !err && response.statusCode == 200
#        console.log '<><><><><><><><><><><><><><><><>', response
        regWP = new RegExp '/wp-content|wp-admin|wp-includes/'
        isWP = regWP.test(response.body)
        console.log '+++++++++++', isWP, item.website

#        regEMail = new RegExp '/[A-Z0-9._%+-]+@([a-z0-9_\.-]+)\.([a-z\.]{2,6})/g'
#        eMail = regEMail.exec(response.body)
#        console.log 'EMAIL<<<<', eMail, '--------', item.website

