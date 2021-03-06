# Budget Single Year Figure
# Data: Collection of parameters (operation, ppg, etc.)
class Visio.Figures.Bsy extends Visio.Figures.Sy

  type: Visio.FigureTypes.BSY

  templateTooltip: HAML['tooltips/bsy']

  initialize: (config) ->
    # which attributes to keep when exporting
    @attrConfig.push 'sortAttribute'
    @attrConfig.push 'query'

    # Stores the query of a certain operation. 'ken' will match the Kenya operation
    config.query or= ''

    super config

    scenarioExpenditures = {}
    scenarioExpenditures[Visio.Scenarios.OL] = true

    @breakdownBy = 'budget_type'
    @filters or= new Visio.Collections.FigureFilter([
      {
        id: 'normalized'
        filterType: 'checkbox'
        values: {
          normalized: false,
        }
        human: { normalized: 'Cost Per Beneficiary' }
        callback: =>
          @render()
      },
      {
        id: 'breakdown_by'
        filterType: 'radio'
        values:
          budget_type: true
          pillar: false
        callback: (name, attr) =>
          $.publish "legend.breakdown", [name]
          @render()
      },
      {
        id: 'budget_type'
        filterType: 'checkbox'
        values: _.object(_.values(Visio.Budgets), _.values(Visio.Budgets).map(-> true))
        callback: => @render()
      },
      {
        id: 'pillar'
        filterType: 'checkbox'
        values: _.object(_.keys(Visio.Pillars), _.keys(Visio.Pillars).map(-> true))
        human: Visio.Pillars
        callback: => @render()
      },
      {
        id: 'scenarios-budgets'
        filterType: 'checkbox'
        values: _.object(_.values(Visio.Scenarios), _.values(Visio.Scenarios).map(-> true))
        human:
          'Above Operating Level': 'Budget AOL'
          'Operating Level': 'Budget OL'
        callback: (name, attr) =>
          @render()
      },
      {
        id: 'scenarios-expenditures'
        filterType: 'checkbox'
        values: scenarioExpenditures
        human:
          'Operating Level': 'Expenditure'
        callback: (name, attr) =>
          @render()
      }
    ])


    # Determines the breakdown of the stack graph. Either budget type or pillar

    @sortAttribute or= 'total'

    # Width of a single .bar element
    @barWidth = 10

    # Margin between .box elements
    @barMargin = 8

    # Margin between .bar elements
    @barInnerMargin = 1

    @tickPadding = 20

    @x = d3.scale.linear()
      .range([0, @adjustedWidth])

    @y = d3.scale.linear()
      .range([@adjustedHeight, 0])

    @yAxis = d3.svg.axis()
      .scale(@y)
      .orient('left')
      .ticks(3)
      .tickPadding(@tickPadding)
      .tickFormat((d) -> if d == 0 then 0 else Visio.Formats.SI_SIMPLE(d))
      .tickSize(-@adjustedWidth)

    @g.append('g')
      .attr('class', 'y axis')
      .attr('transform', 'translate(0,0)')
      .append("text")
        .attr("y", 0)
        .attr("dy", "-.21em")
        .attr("transform", "translate(#{-@tickPadding}, -25)")
        .attr('text-anchor', 'end')
        .html =>
          @yAxisLabel()

    $.subscribe "hover.#{@cid}.figure", @hover
    $.subscribe "mouseout.#{@cid}.figure", @mouseout


    # Lines
    #
    # Bottom line of BSY graph
    @g.append('line')
      .attr('class', 'bsy-line')
      .attr('x1', 0)
      .attr('x2', @adjustedWidth)
      .attr('y1', @adjustedHeight)
      .attr('y2', @adjustedHeight)

    $(@svg.node()).parent().on 'mouseleave', =>
      $.publish "hover.#{@cid}.figure", [@selectedDatum.get('d'), true] if @selectedDatum.get('d')?

  render: (opts) ->

    filtered = @filtered @collection, opts?.isPng
    @_filtered = filtered

    # Normalized sets whether we normalize the budget by population
    normalized = @filters.get('normalized').filter('normalized')

    breakdownBy = @filters.get('breakdown_by').active()

    # Expensive computation so don't want to repeat if not necessary
    @y.domain [0, d3.max(filtered, (d) ->
      data = d.selectedBudgetData(Visio.manager.year(), @filters)
      olData = (new Visio.Collections.Budget(data.where({ scenario: Visio.Scenarios.OL }))).amount()
      aolData = (new Visio.Collections.Budget(data.where({ scenario: Visio.Scenarios.AOL }))).amount()

      population = if normalized then d.selectedPopulation() else 1

      if olData > aolData then olData / population else aolData / population

    )]


    self = @

    scenarios = self.filters.get('scenarios-budgets').active().map (scenario) ->
        { scenario: scenario, type: Visio.Syncables.BUDGETS }

    scenarios = scenarios.concat(self.filters.get('scenarios-expenditures').active().map (scenario) ->
        { scenario: scenario, type: Visio.Syncables.EXPENDITURES })

    @maxParameters = Math.floor @adjustedWidth / (scenarios.length * @barWidth + @barMargin)
    @x.domain([0, @maxParameters])

    boxes = @g.selectAll('g.box').data filtered, (d) -> d.id
    boxes.enter().append('g')
    boxes.attr('class', @boxClasslist)
      .transition()
      .duration(Visio.Durations.FAST)
      .attr('transform', (d, i) -> 'translate(' + self.x(i) + ', 0)')
      .each((d, idx) ->
        box = d3.select @

        # Keep population 1 if we aren't normalizing
        population = if normalized then d.selectedPopulation() else 1


        # Render rect container for bars
        container = box.selectAll('.bar-container').data([d])
        container.enter().append('rect')
        container.attr('width', self.barWidth * scenarios.length)
          .attr('height', self.adjustedHeight + self.barMargin / 2)
          .attr('x', 0)
          .attr('y', -self.barMargin / 2)
          .attr('class', (d) ->
            classList = ['bar-container']
            classList.push 'hover' if d.id == self.hoverDatum?.id

            return classList.join ' ')
          .style('stroke-dasharray', (d) ->
            topDash = self.barWidth * scenarios.length
            perimeter = (self.barWidth * 2 * scenarios.length) + ((self.height + self.barMargin) * 2)

            [topDash, perimeter - topDash].join ' ' )

        container.exit().remove()

        box.selectAll('.bar').remove()


        # Render bars for each scenario type (AOL, OL, Expenditure OL)
        scenarioBars = box.selectAll('.scenario-bar').data(scenarios)
        scenarioBars.enter().append('rect')
        scenarioBars.attr('class', (d) ->
            classList = ['scenario-bar']
            classList.push Visio.Utils.stringToCssClass(d.scenario) + '-bar'
            classList.push Visio.Utils.stringToCssClass(d.type.singular) + '-bar'
            classList.join ' ')
          .attr('width', self.barWidth - self.barInnerMargin)
          .attr('height', self.adjustedHeight)
          .attr('x', (d, i) -> i * self.barWidth)
          .attr('y', 0)

        scenarioBars.on 'mouseenter', (d) ->
          type = "#{Visio.Utils.stringToCssClass(d.scenario)}-#{d.type.singular}"
          $(".bsy-value[data-type=\"#{type}\"]").addClass('highlight')

        scenarioBars.on 'mouseout', (d) ->
          type = "#{Visio.Utils.stringToCssClass(d.scenario)}-#{d.type.singular}"
          $(".bsy-value[data-type=\"#{type}\"]").removeClass('highlight')

        scenarioBars.exit().remove()

        values = []

        _.each scenarios, (scenario, i) ->
          amountData = d.selectedData(scenario.type, Visio.manager.year(), self.filters).where
            scenario: scenario.scenario

          breakdownTypes = self.breakdownTypes()
          sum = 0

          _.each breakdownTypes, (breakdownType, j) ->
            # data for scenario and breakdownType
            breakdownData = _.filter amountData, (datum) ->
              datum.get(breakdownBy) == breakdownType

            amount = new Visio.Collections.AmountType(breakdownData).amount() / population

            # Render each bar of a scenario and breakdown type
            bars = box.selectAll(".#{Visio.Utils.stringToCssClass(scenario.scenario)}-bar.#{Visio.Utils.stringToCssClass(breakdownType)}-bar.#{scenario.type.singular}-bar").data([breakdownType])
            bars.enter().append('rect')
            bars.attr 'class', ->
              classList = ["#{Visio.Utils.stringToCssClass(scenario.scenario)}-bar",
                "#{Visio.Utils.stringToCssClass(breakdownType)}-bar",
                "#{scenario.type.singular}-bar",
                'bar']
              classList.join ' '

            height = self.adjustedHeight - self.y(amount) - self.barInnerMargin
            height = 0 unless height > 0

            bars.transition()
              .duration(Visio.Durations.FAST)
              .attr('x', -> i * self.barWidth)
              .attr('width', -> self.barWidth - self.barInnerMargin)
              .attr('y', -> self.y(amount + sum))
              .attr('height', -> height)

            sum += amount

            bars.exit().remove()

          values.push { scenario: scenario, sum: sum }

        box.attr 'original-title', (d) ->
          self.templateTooltip
            values: values
            normalized: normalized
            d: d

      )

    boxes.on 'mouseenter', (d, idx) ->
      $.publish "hover.#{self.cid}.figure", [idx, false]
      $(@).tipsy('show')

    boxes.on 'mouseleave', (d, idx) ->
      $(@).tipsy('hide')
      $.publish "mouseout.#{self.cid}.figure", idx

    boxes.on 'click', (d, i) =>
      if @selectedDatum.get('d')?.id == d.id
        box = @g.select ".box-#{d.id}"
        box.classed 'selected', false
        @selectedDatum.set 'd', null
        return

      @selectedDatum.set 'd', d
      @g.selectAll('.box').classed 'selected', false unless @isExport
      box = @g.select ".box-#{d.id}"
      box.classed 'selected', true
      $.publish "active.#{@figureId()}", [d, i]

    boxes.exit().remove()

    @$el.find('.box').tipsy()
    @tipsyHeaderBtns()
    @renderLegend()


    @g.select('.y.axis')
      .transition()
      .duration(Visio.Durations.FAST)
      .call(@yAxis)
    @g.select('.y.axis text')
      .html =>
        @yAxisLabel()
    @

  # Filters data based on a string query
  queryByFn: (d) =>
    _.isEmpty(@query) or d.toString().toLowerCase().indexOf(@query.toLowerCase()) != -1

  # Sorts the data based on the sortAttribute
  sortFn: (a, b) =>
    filters = new Visio.Collections.FigureFilter()
    normalized = @filters.get('normalized').filter('normalized')
    populationA = if normalized then a.selectedPopulation() else 1
    populationB = if normalized then b.selectedPopulation() else 1

    switch @sortAttribute
      when Visio.Scenarios.OL, Visio.Scenarios.AOL
        values = {}
        values[Visio.Scenarios.AOL] = Visio.Scenarios.AOL == @sortAttribute
        values[Visio.Scenarios.OL] = Visio.Scenarios.OL == @sortAttribute
        filters.add
            id: 'scenario',
            filterType: 'checkbox'
            values: values

    filters.add @filters.toJSON()

    if @sortAttribute == 'percent'
      filters.remove 'scenario'
      bData = b.selectedBudgetData(null, filters)
      aData = a.selectedBudgetData(null, filters)
      bOL = new Visio.Collections.Budget(bData.where({ scenario: Visio.Scenarios.OL })).amount() / populationB
      aOL = new Visio.Collections.Budget(aData.where({ scenario: Visio.Scenarios.OL })).amount() / populationA
      bAOL = new Visio.Collections.Budget(bData.where({ scenario: Visio.Scenarios.AOL })).amount() / populationB
      aAOL = new Visio.Collections.Budget(aData.where({ scenario: Visio.Scenarios.AOL })).amount() / populationA
      v = (bOL / (bOL + bAOL)) - (aOL / (aOL + aAOL))

      if v != 0 then v else ((bOL + bAOL) - (aOL + aAOL))


    else
      (b.selectedBudget(null, filters) / populationB - a.selectedBudget(null, filters) / populationA)

  filtered: (collection, isPng) =>
    chain = _.chain(collection.models).filter(@queryByFn).sort(@sortFn)
    chain = chain.filter(@activeFn) if isPng
    chain.value()

  hover: (e, idxOrDatum, scroll = true) =>
    self = @
    @hoverDatum = null
    box = null
    idx = null

    # Remove any hover classes
    boxes = @g.selectAll('.box')
    boxes.selectAll('.bar-container').classed 'hover', false

    # Determine the idx if it's a datum, determine datum if we're given index
    if _.isNumber idxOrDatum
      idx = idxOrDatum
      result = @findBoxByIndex idx
    else
      @hoverDatum = idxOrDatum
      result = @findBoxByDatum @hoverDatum

    box = result.box
    idx = result.idx
    @hoverDatum = result.datum

    return unless @hoverDatum?
    box.select('.bar-container').classed 'hover', true

    @renderSvgLabels() if @isExport

    if scroll
      if idx >= @maxParameters
        difference = idx - @maxParameters
        @x.domain [0 + difference, @maxParameters + difference]

      else if @x.domain()[0] > 0
        @x.domain [0, @maxParameters]

      @g.selectAll('g.box')
        .transition()
        .duration(Visio.Durations.VERY_FAST)
        .attr('transform', (d, i) => 'translate(' + @x(i) + ', 0)')
        .attr 'class', @boxClasslist

  breakdownTypes: =>
    breakdownBy = @filters.get('breakdown_by').active()
    if breakdownBy == 'budget_type'
      _.values Visio.Budgets
    else if breakdownBy == 'pillar'
      _.keys Visio.Pillars

  mouseout: (e, i) =>
    @g.selectAll('.bar-container').classed 'hover', false

  graphLabels: =>
    self = @

    scenariosLength = @filters.get('scenarios-budgets').active().length +
        @filters.get('scenarios-expenditures').active().length

    @g.selectAll(".graph-label").remove()

    graphLabels = @g.selectAll('.graph-label').data @activeData.models
    graphLabels.enter().append('text')
      .attr('class', 'label graph-label')
      .attr('x', (m, i) =>
        idx = _.chain(@_filtered).pluck('id').indexOf(m.id).value()
        @x(idx) + ((scenariosLength / 2) * self.barWidth))
      .attr('y', self.adjustedHeight + 2 * self.barWidth)
      .attr('dy', '.3em')
      .text (m, i) =>
        Visio.Utils.numberToLetter i

  getMax: =>
    @collection.length

  yAxisLabel: ->
    normalized = @filters.get('normalized').filter 'normalized'
    title = if normalized then 'Budget Per Beneficiary' else 'Budget'

    achievement_type = Visio.Utils.humanMetric Visio.manager.get 'achievement_type'
    return @templateLabel
        title: title
        subtitles: ['in US Dollars']
