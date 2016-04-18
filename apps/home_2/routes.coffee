_ = require 'underscore'
Q = require 'bluebird-q'
{ parse } = require 'url'
Backbone = require 'backbone'
sd = require('sharify').data
Items = require '../../collections/items'
HeroUnits = require '../../collections/hero_units'
{ client } = require '../../lib/cache'
metaphysics = require '../../lib/metaphysics.coffee'
welcomeHero = require './welcome'
query = require './queries/initial'

getRedirectTo = (req) ->
  req.body['redirect-to'] or
  req.query['redirect-to'] or
  req.query['redirect_uri'] or
  parse(req.get('Referrer') or '').path or
  '/'

positionWelcomeHeroMethod = (req, res) ->
  method = if req.cookies?['hide-welcome-hero']? then 'push' else 'unshift'
  res.cookie 'hide-welcome-hero', '1', expires: new Date(Date.now() + 31536000000)
  method

@index = (req, res, next) ->
  return next() unless req.user?
  heroUnits = new HeroUnits
  timeToCacheInSeconds = 300 # 5 Minutes

  # homepage:featured-sections
  featuredLinks = new Items [], id: '529939e2275b245e290004a0', item_type: 'FeaturedLink'
  # homepage:featured-links
  featuredArticles = new Items [], id: '5172bbb97695afc60a000001', item_type: 'FeaturedLink'
  # homepage:featured-shows
  featuredShows = new Items [], id: '530ebe92139b21efd6000071', item_type: 'PartnerShow'

  Q.allSettled(_.compact([
    heroUnits.fetch(cache: true, cacheTime: timeToCacheInSeconds)
    metaphysics query: query, req: req
    featuredLinks.fetch(cache: true)
    featuredArticles.fetch(cache: true, cacheTime: timeToCacheInSeconds)
    featuredShows.fetch(cache: true, cacheTime: timeToCacheInSeconds)
  ])).spread( (heroUnitPromise, { value: { home_page_modules } }) ->
    # filter related_artists out until data is available
    modules = _.reject home_page_modules, (module) -> module.key is 'related_artists'

    heroUnits[positionWelcomeHeroMethod(req, res)](welcomeHero) unless req.user?

    res.locals.sd.HERO_UNITS = heroUnits.toJSON()
    res.locals.sd.USER_HOME_PAGE = modules

    res.render 'index',
      heroUnits: heroUnits
      modules: modules
      featuredLinks: featuredLinks
      featuredArticles: featuredArticles
      featuredShows: featuredShows
  ).done()

@redirectToSignup = (req, res) ->
  res.redirect "/sign_up"

@redirectLoggedInHome = (req, res, next) ->
  pathname = parse(req.url or '').pathname
  req.query['redirect-to'] = '/' if pathname is '/log_in' or pathname is '/sign_up'
  if req.user? then res.redirect getRedirectTo(req) else next()