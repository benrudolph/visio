class Visio.Routers.IndexRouter extends Backbone.Router

  initialize: (options) ->

    @map = Visio.Graphs.map(
      margin:
        top: 0
        left: 0
        right: 0
        bottom: 0
      selection: d3.select '#map'
      width: $(window).width()
      height: 500)


    Visio.manager.getMap().done((map) =>
      @map.mapJSON(map)
      @map()
    )

    plans = Visio.manager.get('plans')
    plans.fetchSynced().done(() ->
      Visio.manager.set('plans', plans)
    )

  routes:
    ':plan_id/:type': 'list'
    '*default': 'index'

  index: () ->
    console.log 'index'

  list: (plan_id, type) ->

    @listView.close() if @listView

    @listView = new Visio.Views.ParameterListView(
      model: Visio.manager.plan(plan_id)
      type: type || Visio.Parameters.INDICATORS
    )

    $('header').after(@listView.el)
