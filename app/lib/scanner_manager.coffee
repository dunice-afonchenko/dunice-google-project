mongoose = require 'mongoose'
request = require 'request'
async = require 'async'
GooglePlaces = require 'googleplaces'
qs = require 'querystring'
_ = require 'underscore'
_.mixin require 'underscore.deferred'
Business = require('../models/business')
Scanner = require('../models/scanner')
cronJob = require('cron').CronJob


config =
  apiKey: "AIzaSyApPPpRTK4MgpwGeIP0OLVYcV2TY70I6_k"
  outputFormat: "json"
  pageSpeed: 'https://www.googleapis.com/pagespeedonline/v1/runPagespeed?'
  pageSpeedDesktop: '&strategy=desktop'
  pageSpeedMobile: '&strategy=mobile'


# TODO: handle errors when nothing is found
# TODO: deploy to amazon ec2
# TODO: filters on the page
# TODO: change flow - research 1 by 1
# TODO: webpage: socket.io, pause, start, restart, stop, remove
#       support several parallel processes, google map integration




class ScannerManager

  constructor: (@scanner)->
    @requests = 0
    @googlePlaces = new GooglePlaces config.apiKey, config.outputFormat
    @defer = new _.Deferred
    new cronJob("*/4 * * * * *", =>
#    new cronJob("15 0 * * * *", =>
      @defer.resolve()
    , null, true, "America/Los_Angeles")


  _continue: (argsCount, cb)->
#    throw 'Custom error argsCount' if argsCount isnt in [1, 2]
    return =>
      [error, response] = args = if argsCount is 2 then [arguments[0], arguments[1]] else [null, arguments[0]]
      #      if Math.random()>0.3
      #        response.status = 'not OK'
      #      console.log 'status', response.status
      next = response.status is 'OK'
      if next
        cb.apply @, args
      else
        @defer = new _.Deferred
        _.when(@defer).done =>
          cb.apply @, args

  _getParams: ->
    {
      location: [@scanner.get('latitude'), @scanner.get('longitude')]
      radius: @scanner.get('radius')
    }


  _placeSearch: (cb)->
    @googlePlaces.placeSearch @_getParams(), @_continue(1, cb)


  _placeDetailsRequest: (place, cb)->
    @googlePlaces.placeDetailsRequest place, @_continue(1, cb)


  _parseWebsite: (url, cb)->
    request url, (err, response) ->
      if err or response.statusCode isnt 200
        return cb err

      body = response.body

      reg = {
        wp: /wp-content|wp-admin|wp-includes/
        email: /([a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+\.[a-zA-Z0-9]+)/
        twitter: /(twitter.com\/[#!a-zA-Z0-9._-]+(\/[#!a-zA-Z0-9_-]+)*)/
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
    @_placeDetailsRequest {reference:place.reference}, (error, response) ->
      rightPlace = unless _.isUndefined(response.result.website)
        response.result
      else null
      cb? null, rightPlace

#  _filterPlaces: (places, cb)->
#    cb null, places

  getRightPlaces: (cb)->
    @_placeSearch (error, response) =>
      places = response.results

      funcs = _.map places, (place)=>
        (cb)=>
          @getDetails place, (err, rightPlace)->
            cb err, rightPlace
      async.series funcs, (errors, results)->
        rightPlaces = _.filter results, (place)-> place?
        cb null, rightPlaces


  getBusinesses: (cb)->
    @getRightPlaces (err, places)=>

      # for test
#      places = [places[0]]
#      places = [places[0], places[1]]
#      places = places.slice(0,3)


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
              (cbp)=> @_parseWebsite place.website, cbp
              (cbp)=> request urlDesktop, (err, res)->
                return cbp err if err
                cbp err, pageSpeedDesktop: JSON.parse(res.body)
              (cbp)=> request urlMobile, (err, res)->
                return cbp err if err
                cbp err, pageSpeedMobile: JSON.parse(res.body)
            ], (errors, results)=>
              json = _.extend.apply _, [{}].concat(results)
              business = new Business {json}
              business.save (err, results)=>
                @scanner.businesses.push business
                callback null, business
      async.series funcs, cb


  exec: ->
    @scanner.status = 'Progress'
    @scanner.save()
    @getBusinesses (errors, businesses)=>
      @scanner.status = 'Completed'
      @scanner.save()



exports.ScannerManager = ScannerManager

