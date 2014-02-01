class Visio.Models.ExportModule extends Backbone.Model

  defaults:
    title: 'My Awesome New Visualization'
    description: 'Description'

    # Custom settings for the visualization
    state: {}

    # Whether or not to include the contributing parameters
    include_parameter_list: false

    # Whether or not to include explanations of the algorithms
    include_explaination: false

    # Data for exporting
    data: null

  figure: ->
    Visio.Figures[@get 'figure_type']

  figure_config: {}

  urlRoot: '/export_modules'

  pdfUrl: ->
    "#{@urlRoot}/#{@id}/pdf.pdf"

  paramRoot: 'export_module'