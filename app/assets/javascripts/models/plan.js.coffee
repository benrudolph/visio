class Visio.Models.Plan extends Visio.Models.Parameter

  constructor: () ->
    @indicators = new Visio.Collections.Indicator()
    @outputs = new Visio.Collections.Output()
    @problemObjectives = new Visio.Collections.ProblemObjective()
    @ppgs = new Visio.Collections.Ppg()

  urlRoot: '/plans'

  paramRoot: 'plan'
