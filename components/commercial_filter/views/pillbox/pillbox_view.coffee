Backbone = require 'backbone'
_ = require 'underscore'
s = require 'underscore.string'
mediumMap = require '../../filters/medium/medium_map.coffee'
{ formatMoney } = require 'accounting'

template = -> require('./index.jade') arguments...

module.exports = class PillboxView extends Backbone.View
  events:
    'click .cf-pillbox__pillboxes_clear' : 'clear'

  initialize: ({ @params, @artworks }) ->
    throw new Error 'Requires a params model' unless @params?
    throw new Error 'Requires an artworks collection' unless @artworks?

    @listenTo @params, 'change', @render
    @listenTo @artworks, 'zero:results reset', @render

  clear: (e) ->
    param = $(e.currentTarget).data('value')
    @params.unset(param)

  medium: ->
    mediumMap[@params.get('medium')] if @params.has('medium')

  size: (label, attr) ->
    if @params.has(attr)
      [ min, max ] = _.map @params.get(attr).split("-"), (val) -> parseInt val
      plus = if max is @params.get('ranges')[attr]?.max then "+" else ""
      "#{label}: #{min} – #{max}#{plus} in."

  price: ->
    if @params.has('price_range')
      [ min, max ] = _.map @params.get('price_range').split("-"), (val) -> parseInt val
      plus = if max is @params.get('ranges').price_range.max then "+" else ""
      "#{formatMoney(min, { precision: 0 })} – #{formatMoney(max, { precision: 0 })}#{plus}"

  render: (hasResults = true) ->
    @$el.html template
      color: @params.get('color')
      medium: @medium()
      price: @price()
      width: @size 'Width', 'width'
      height: @size 'Height', 'height'
      hasResults: hasResults