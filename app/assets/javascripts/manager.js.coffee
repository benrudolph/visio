class Visio.Models.Manager extends Backbone.Model

  initialize: () ->
    @set('db', new ydn.db.Storage(Visio.Constants.DB_NAME))

  defaults:
    'plans': new Visio.Collections.Plan()
    'ppgs': new Visio.Collections.Ppg()
    'goals': new Visio.Collections.Goal()
    'outputs': new Visio.Collections.Output()
    'problem_objectives': new Visio.Collections.ProblemObjective()
    'indicators': new Visio.Collections.Indicator()
    'date': new Date()
    'db': null
    'mapMD5': null
    'syncTimestampId': 'sync_timestamp_id_'
    'yearList': [2012, 2013, 2014, 2015]

  year: () ->
    @get('date').getFullYear()

  setYear: (year) ->
    @set('date', new Date(year, 1))

  plan: (idOrISO) ->
    if idOrISO.length == 3
      plan = @get('plans').find((p) =>
        if p.get('country')
          p.get('country').iso3 == idOrISO && p.get('year') == @year()
        else
          false
      )
      return plan
    else
      return @get('plans').get(idOrISO)

  plans: (options) ->
    @get('plans').where(options)

  getSyncDate: (id) ->
    db = @get('db')
    db.get(Visio.Stores.SYNC, id)

  setSyncDate: (id) ->
    d = new Date()
    db = @get('db')

    db.put(Visio.Stores.SYNC, { synced_timestamp: +d }, id)

  getMap: () ->
    db = @get('db')
    assert(@get('mapMD5'))

    $.when(db.get(Visio.Stores.MAP, @get('mapMD5'))).then((record) =>
      if !record
        return $.get('/map')
      else
        return record
    ).done((record) =>
      db.put(Visio.Stores.MAP, record, @get('mapMD5'))
    ).done(() =>
      db.get(Visio.Stores.MAP, @get('mapMD5'))
    )
