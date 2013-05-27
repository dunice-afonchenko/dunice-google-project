mongoose = require 'mongoose'
request = require 'request'
async = require 'async'
config = require './../../config/scanner'
GooglePlaces = require 'googleplaces'
qs = require 'querystring'
_ = require 'underscore'
_.mixin require 'underscore.deferred'

Business = require('../models/business')
Scanner = require('../models/scanner')
#mongoose.connect ('mongodb://127.0.0.1/duniceGoogleProject')
cronJob = require('cron').CronJob

# TODO: handle errors when nothing is found
# TODO: deploy to amazon ec2
# TODO: filters on the page
# TODO: change flow - research 1 by 1
# TODO: webpage: socket.io, pause, start, restart, stop, remove
#       support several parallel processes, google map integration


class ScannerController


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


  _parseWebsite: (url, cb)->
    console.log '_parseWebsite', url
    request url, (err, response) ->
      if err or response.statusCode isnt 200
        return cb err

      console.log 'request is good'
      body = response.body

      reg = {
        wp: /wp-content|wp-admin|wp-includes/
        email: /([a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+\.[a-zA-Z0-9]+)/
        twitter: /(twitter.com\/[a-zA-Z0-9._-]+(\/[a-zA-Z0-9_-]+)*)/
        facebook: /(facebook.com\/[a-zA-Z0-9._-]+(\/[a-zA-Z0-9_-]+)*)/
        linkedIn: /(linkedin.com\/[a-zA-Z0-9._-]+(\/[a-zA-Z0-9_-]+)*)/
      }


      cb null, {
        isWP:     reg.wp.test body
        email:    body.match(reg.email)?[0]    or null
        twitter:  body.match(reg.twitter)?[0]  or null
        facebook: body.match(reg.facebook)?[0] or null
        linkedIn: body.match(reg.linkedIn)?[0] or null
      }


  getDetails: (place, cb)->
    @_placeDetailsRequest {reference:place.reference}, (response) ->
      #      return console.log 'response', response
      rightPlace = unless _.isUndefined(response.result.website)
        response.result
      else null
      cb? null, rightPlace


  getRightPlaces: (params, cb)->
    console.log 'getRightPlaces',  params
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


  getBusinesses: (params, cb)->
    @getRightPlaces params, (err, places)=>

      # for test
      places = [places[0]]


      funcs = _.map places, (place)=>
        (callback)=>

            query = qs.stringify {
              url: place.website
              key: config.apiKey
            }

            urlDesktop = [config.pageSpeed, query, config.pageSpeedDesktop].join('')
            urlMobile  = [config.pageSpeed, query, config.pageSpeedMobile].join('')

            async.parallel [
              (cbp)=>
                return cbp null, {
                  name: place.name
                  website: place.website
                  adress: place.formatted_address or null
                  phone: place.formatted_phone_number or null
                }
#              (cbp)=> @_parseWebsite place.website, cbp
#              (cbp)=> request urlDesktop, (err, res)->
#                return cbp err if err
#                cbp err, pageSpeedDesktop: JSON.parse(res.body)
#              (cbp)=> request urlMobile, (err, res)->
#                return cbp err if err
#                cbp err, pageSpeedMobile: JSON.parse(res.body)
            ], (errors, results)->
              json = _.extend.apply _, [{}].concat(results)
              business = new Business {json}
              business.save callback

      async.series funcs, cb


controller = new ScannerController config


exports.index = (req, res)->
  res.render 'scanner/base'

exports.new = (req, res) ->
  res.render 'scanner/new',
    scanner: new Scanner({})

exports.businesses = (req, res) ->
  query = req.query
  params = {
    location: [query.latitude, query.longitude]
    radius: query.radius
  }
  controller.getBusinesses params, (err, results)->
    console.log 'results', {err, businesses}
    return res.render '/businesses',
      businesses: businesses

