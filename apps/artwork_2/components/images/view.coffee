{ throttle } = require 'underscore'
Backbone = require 'backbone'
deepZoom = require '../deep_zoom/index.coffee'
template = -> require('./index.jade') arguments...

module.exports = class ArtworkImagesView extends Backbone.View
  events:
    'click .js-artwork-images__images__image': 'zoom'
    'click .js-artwork-images__pages__page': 'activate'
    'click .js-artwork-images__arrows__next': 'next'
    'click .js-artwork-images__arrows__prev': 'prev'
    'mousemove': -> @detect arguments...

  @cache: (selector) -> -> @[selector] ?= @$(selector)

  pages: @cache '.js-artwork-images__pages__page'
  images: @cache '.js-artwork-images__images__image'

  initialize: ->
    @detect = throttle @__detect__, 500

  __detect__: (e) ->
    @$el.attr 'data-focus', 'active'
    clearTimeout @activity
    @activity = setTimeout =>
      @$el.attr 'data-focus', 'inactive'
    , 1000

  __activate__: (id) ->
    @$active = @images().add @pages()
      .attr 'data-state', 'inactive'
      .filter "[data-id=#{id}]"

    $loader = @$active
      .attr 'data-state', 'active'
      .find '.js-artwork-images__images__image__display'

    $loader
      .css 'background-image': "url(#{$loader.data 'src'})"
      .imagesLoaded background: true, ->
        $loader.attr 'data-state', 'loaded'

  index: ->
    @images().index @$active

  activate: (e) ->
    e.preventDefault()
    @__activate__ $(e.currentTarget).data 'id'

  prev: (e) ->
    e.preventDefault()
    i = @index()
    i = if i + 1 < @images().length then i + 1 else 0
    @__activate__ $(@images().get i).data 'id'

  next: (e) ->
    e.preventDefault()
    i = @index() - 1
    @__activate__ $(@images().get i).data 'id'

  zoom: (e) ->
    e.preventDefault()
    deepZoom $(e.currentTarget).data 'id'

  render: $.noop
