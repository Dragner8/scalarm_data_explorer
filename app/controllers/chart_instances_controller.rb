require 'erb'
class ChartInstancesController < ApplicationController
  before_filter :load_experiment, only: :show
  include ERB::Util
  include Scalarm::ServiceCore::ParameterValidation


=begin
apiDoc:
  @api {get} /chart_instances/:id Chart rendering
  @apiName chart_instances#show
  @apiGroup ChartInstances
  @apiDescription Return html rendered from file (located at /app/visualisation_methods/<chart_name>/chart in application) which add new window to modal with generated chart.
  When called, firstly validates chart name (:id) and then escapes all other parameters for safety.
  Next, invoke visualization class method handler (located at /app/visualisation_methods/plugin in application) to prepare data for loaded draw function content.
  Rendered view contain a hide button and JavaScript function which handle button clicks.


  @apiParam {String} id chart method name
  @apiParam {String} chart_id unique id for rendered chart

  @apiParam {String} param_x parameter id for chart x dimension
  @apiParam {String} param_y parameter id for chart y dimension
  @apiParam {String} param_z parameter id for chart z dimension - used in 3D
  @apiParam {String} output selected output moes parameter id - used in interaction, pareto

  @apiParam {List} array list of moes names - used in clustering
  @apiParam {String} clusters number of cluster - used in k-meas
  @apiParam {String} subclusters number of subcluster - used in k-means


  @apiParam {List} input_parameters list with all experiment input parameter
  @apiParam {List} moes list with  experiment moes


=end

  def show
    analysisMethodsConfig = AnalysisMethodsConfig.new
    methods = analysisMethodsConfig.get_method_names
    #validating chart_id (name of method)
    validate(
        id: Proc.new do |param_name, value|
          unless methods.include? value
            raise SecurityError.new("Wrong chart name")
          end
        end,
        chart_id: :integer
    )

    chart_name = params[:id].to_s #nazwa metody

    filter = {is_done: true, is_error: {'$exists' => false}}
    fields = {fields: {result: 1}}
    first_simulation_run = @experiment.simulation_runs.where(filter, fields).first

    params[:input_parameters] = @experiment.get_parameter_ids
    params[:moes] = first_simulation_run.blank? ? [] : first_simulation_run.result
    # class ogolna klasa z utilsami
    Utils::require_plugin(chart_name)

    #from 4.2 Rails version ... params html safety
    #params.transform_values {|v| ERB::Util.h(v)}

    #escaping html js all parameters for safety
    #params html safety (< 4.2 version)
    params.update(params){ |k, v| v.kind_of?(Array)?v.map!{|array_value| ERB::Util.h(array_value)} :ERB::Util.h(v)}

    chart_file_content = ''
    if standalone
      chart_file_content = render_to_string :file => Rails.root.join('app','visualisation_methods', chart_name,"chart.js"), layout: false
      chart_file_content = '<script>'.to_s.html_safe + chart_file_content + '</script>'.to_s.html_safe
    end

    @content = Utils::generate_content_with_plugin(chart_name, @experiment, params)
    chart_header = render_to_string :file => Rails.root.join('app','visualisation_methods', chart_name, 'chart.html.haml'), layout: standalone
    render :html => (chart_header + chart_file_content + @content.to_s.html_safe), content_type: 'text/html', layout: false
  end
end