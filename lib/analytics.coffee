#
# Simple wrapper around mixpanel to simplify common analytics actions.
# This should also provide a central place to put analytics logic when/if other
# services like Google Analytics are integrated.
#

_ = require 'underscore'
_s = require 'underscore.string'
sd = require('sharify').data
qs = require('querystring')
sparkMd5Hash = require('spark-md5').hash
Cookies = require '../components/cookies/index.coffee'

module.exports = (options) =>
  return if module.exports.getUserAgent()?.indexOf?('PhantomJS') > -1
  { @ga, @location } = options
  @location ?= window?.location
  if sd.GOOGLE_ANALYTICS_ID
    googleAnalyticsParams = cookieDomain: 'artsy.net'

    if sd.CURRENT_USER?.id
      googleAnalyticsParams.userId = sd.CURRENT_USER?.id

    @ga? 'create', sd.GOOGLE_ANALYTICS_ID, googleAnalyticsParams

module.exports.getUserAgent = ->
  window?.navigator?.userAgent

# Delta tracking pixel
module.exports.delta = (event, data, el) ->
  data.name = event
  data.method = 'import'
  data.pixel = 1
  url = 'https://' + sd.DELTA_HOST + '/?' + qs.stringify(data)
  el.append '<img src="' + url + '" style="display:none;" />'

module.exports.registerCurrentUser = ->
  # Don't track admins
  return if sd.CURRENT_USER?.type == 'Admin'

  userType = if sd.CURRENT_USER then "Logged In" else "Logged Out"

  ga?('set', 'dimension1', userType)
  mixpanel?.register?("User Type": userType)

# This basically just sets some defaults loosely based on the
# Analytics wrapper class from Gravity
categories =
  impression: 'Impressions'
  hover: 'UI Interactions'
  click: 'UI Interactions'
  submit: 'UI Interactions'
  funnel: 'Funnel Progressions'
  segment: 'UI A/B Test Segments'
  error: 'UI Errors'
  multi: 'Multi-object Events'
  timing: 'Timing'
  other: 'Other Events'

module.exports.track = track =
  _.reduce(Object.keys(categories), (memo, kind) ->
    memo[kind] = (description, options = {}) ->

      # Don't track admins
      return if sd.CURRENT_USER?.type is 'Admin'

      # Format and Send mixpanel event
      unless typeof mixpanel is 'undefined'
        options.category = categories[kind] or categories.other

        _.defaults options,
          queryString: window?.location.search
          page: window?.location.pathname
          referrer: document?.referrer
          source_referrer: Cookies.get('force-referrer')
          collector_level: sd.CURRENT_USER?.collector_level
          user_id: sd.CURRENT_USER?.id
          lab_features: sd.CURRENT_USER?.lab_features

        mixpanel.track? description, options

      # Send google analytics event
      ga? 'send', {
        hitType: 'event'
        eventCategory: options.category
        eventAction: description
        eventLabel: options.label
        nonInteraction: (if options.category in ['Funnel Progressions', 'Impressions', 'Timing'] then 1 else 0)
      }
    memo
  , {})

module.exports.trackForms = (selector, description, options = {}) ->
  mixpanel.track_forms selector, description, options

module.exports.trackLinks = (selector, description, options = {}) ->
  mixpanel.track_links selector, description, options

module.exports.modelNameAndIdToLabel = (modelName, id) ->
  throw new Error('Requires modelName and id') unless modelName? and id?
  "#{_s.capitalize(modelName)}:#{id}"

#
# Tracks the time it takes between the page request and the specified event
#
# Needs to get the time from the server to account for any discrepancies with client-side time
#
module.exports.trackTimeTo = trackTimeTo = (description) ->
  return if not sd.REQUEST_TIMESTAMP?

  stopwatch = Date.now()
  $.ajax
    type: 'GET'
    url: '/system/time'
    success: (data) =>
      ajaxTime = Date.now() - stopwatch
      milliseconds = data.time - sd.REQUEST_TIMESTAMP - ajaxTime
      track.timing description, {milliseconds: milliseconds}

# Special multi-event
#
# GA imposes a 500 byte limit on event labels
# For multis, each id is hashed to 8 characters + event id, leaving room for 55 ids
# Going with 50 to be conservative and account for the model name
maxTrackableMultiIds = 50
# Browser url length limit is 2048 characters, this is the length that we will allot the
# artwork ids so that we safely stay under this limit (rest of url for the impression
# event is 511 chars in this case)
maxUnhashedTrackableLength = 1300

module.exports.encodeMulti = (ids) ->
  ids = _.compact(ids)
  (_.map ids, (id) -> sparkMd5Hash(id).substr(0, 8) ).join("-")

module.exports.trackMulti = (description, data) =>
  ga? 'send', 'event', categories['multi'], description, data

module.exports.multi = (description, modelName, ids) ->
  return unless ids?.length > 0

  # chunk ids by maxTrackableMultiIds and maxUnhashedTrackableLength
  chunkedIds = _.groupBy(ids, (a, b) => return Math.floor(b / maxTrackableMultiIds))

  for chunk, index in _.toArray(chunkedIds)
    # Fire log events at 1/2 second intervals
    ((encodedIds) =>
      _.delay( =>
        @trackMulti description, @modelNameAndIdToLabel(modelName, encodedIds)
      , (500 * index) + 1)
    )(@encodeMulti(chunk))

# Code using this function should cope with it returning undefined
module.exports.getProperty = (property) =>
  # We need to be extra safe here - sometimes mixpanel has not loaded, sometimes it has but doesn't have the get_property function
  mixpanel?.get_property?(property)

module.exports.unsetProperty = (property) =>
  mixpanel?.unregister?(property)

# Code using this function should cope with it returning undefined
module.exports.setProperty = (hash) =>
  mixpanel?.register_once?(hash)

# These need to be set up individually before using. Read this non-sense:
# https://developers.google.com/analytics/devguides/platform/customdimsmets
module.exports.setDimension = (index, value) ->
  ga? 'set', index, value

# Calls back when mixpanel has loaded. Useful for pages that do testing on
# load. Such as AB testing the way a certain page looks.
module.exports.load = (callback) ->
  called = false
  cb = ->
    return if called
    called = true
    callback()
  if mixpanel?.__loaded then cb() else window.analytics.ready cb
  setTimeout cb, 5000 # Ensure we callback whether mixpanel is working or not
