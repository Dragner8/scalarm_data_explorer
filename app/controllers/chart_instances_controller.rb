require 'erb'
class ChartInstancesController < ApplicationController
  before_filter :load_experiment, only: :show
  include ERB::Util
  include Scalarm::ServiceCore::ParameterValidation

  def show
    analysisMethodsConfig = AnalysisMethodsConfig.new
    methods = analysisMethodsConfig.get_method_names
    #validating chart_id (name of method)
    validate(
        id: Proc.new do |param_name, value|
          unless methods.include? value
            raise SecurityError.new("Wrong chart name")
          end
        end
    )

    chart_id = params[:id].to_s #nazwa metody

    filter = {is_done: true, is_error: {'$exists' => false}}
    fields = {fields: {result: 1}}
    first_simulation_run = @experiment.simulation_runs.where(filter, fields).first

    params[:input_parameters] = @experiment.get_parameter_ids
    params[:moes] = first_simulation_run.blank? ? [] : first_simulation_run.result
    # class ogolna klasa z utilsami
    Utils::require_plugin(chart_id)

    #from 4.2 Rails version ... params html safety
    #params.transform_values {|v| ERB::Util.h(v)}

    #escaping html js all parameters for safety
    #params html safety (< 4.2 version)
    params.update(params){ |k, v| v.kind_of?(Array)?v.map!{|array_value| ERB::Util.h(array_value)} :ERB::Util.h(v)}

    # set layout
    if params[:stand_alone] == 'false' || params[:stand_alone].nil?
      layout_value = false
    else
      layout_value = true
    end
    @content = Utils::generate_content_with_plugin(chart_id, @experiment, params)
    chart_header = render_to_string :file => Rails.root.join('app','visualisation_methods', chart_id, 'chart.html.haml'), layout: layout_value
    render :html => (chart_header + @content.to_s.html_safe), content_type: 'text/html', layout: false
  end
end