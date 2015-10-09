benv = require 'benv'
sinon = require 'sinon'
rewire = require 'rewire'
moment = require 'moment'
Backbone = require 'backbone'
{ fabricate } = require 'antigravity'
setupAuctionReminder = rewire '../index'
setupAuctionReminder.__set__ 'AuctionReminderView',
  benv.requireWithJadeify require.resolve('../view'), ['template']

describe 'setupAuctionReminder', ->
  before (done) ->
    benv.setup ->
      benv.expose $: benv.require 'jquery'
      Backbone.$ = $
      $.support.transition = end: 'transitionend'
      $.fn.emulateTransitionEnd = -> @trigger $.support.transition.end
      done()

  after ->
    benv.teardown()

  beforeEach ->
    sinon.stub Backbone, 'sync'
      .yieldsTo 'success', [
        fabricate 'sale', id: 'first', end_at: moment().add(1, 'hour').format()
        fabricate 'sale', id: 'second', end_at: moment().add(1, 'hour').format()
        fabricate 'sale', id: 'is-over-but-cached-and-being-returned', end_at: moment().subtract(1, 'hour').format()
      ]

    setupAuctionReminder()

  afterEach ->
    Backbone.sync.restore()

  it 'sets up the reminders', ->
    Backbone.sync.args[0][1].url
      .should.equal '/auctions/reminders'

    $('.auction-reminders').should.have.lengthOf 1
    $('.auction-reminder').should.have.lengthOf 2

    $('.js-dismiss:first').click() # Dismiss first

    $('.auction-reminders').should.have.lengthOf 1
    $('.auction-reminder').should.have.lengthOf 1

    $('.js-dismiss:first').click() # Dismiss second

    $('.auction-reminders').should.have.lengthOf 0
    $('.auction-reminder').should.have.lengthOf 0

    $('body').html().should.eql ''