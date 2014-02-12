class Visio.Figures.Circle extends Visio.Figures.Base

  type: Visio.FigureTypes.CIRCLE

  attrAccessible: ['percent', 'number']

  initialize: (config) ->

    Visio.Figures.Base.prototype.initialize.call @, config

    @twoPi = 2 * Math.PI

    @arc = d3.svg.arc()
      .startAngle(0)
      .innerRadius(0)
      .outerRadius(@height / 2)

    @centerG = @g.append('g')
      .attr("transform", "translate(" + @width / 2 + "," + @height / 2 + ")")

    @meter = @centerG.append("g")
      .attr("class", "progress-meter")

    @meter.append("path")
      .attr("class", "background")
      .attr("d", @arc.endAngle(@twoPi))

    @foreground = @meter.append("path")
      .attr("class", "foreground")

    @oldPercent = config.percent || 1

    @oldNumber = config.number

  render: ->
    i = d3.interpolate(@oldPercent, @percent)
    @centerG.transition()
      .duration(Visio.Durations.MEDIUM)
      .tween("percent", () =>
        return (t) =>
          @percent = i(t)
          @foreground.attr('d', @arc.endAngle(@twoPi * @percent)))

    #$(@text.node()).countTo
    #  from: @oldNumber
    #  to: @number
    #  speed: Visio.Durations.FAST
    #  formatter: Visio.Utils.countToFormatter

    @oldPercent = @percent || 0
    @oldNumber = @number || 0
    @
