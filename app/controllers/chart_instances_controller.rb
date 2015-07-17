require 'erb'
class ChartInstancesController < ApplicationController
  before_filter :load_experiment, only: :show
  include ERB::Util

  def show


    analysisMethodsConfig = AnalysisMethodsConfig.new
    methods = analysisMethodsConfig.get_method_names
    #validating chart_id (name of method)
    validate(
        id: Proc.new do |param_name, value|
          unless methods.include? value
            raise "Wrong chart name"
          end
        end
    )

    chart_id = params[:id].to_s #nazwa metody

    filter = {is_done: true, is_error: {'$exists'=> false}}
    fields = {fields: {result: 1}}
    moes = @experiment.simulation_runs.where(filter, fields).first

    params[:input_parameters] = @experiment.get_parameter_ids
    params[:moes] = moes.blank? ? [] : moes.result
    # class ogolna klasa z utilsami
    path = Rails.root.join('app','visualisation_methods',"#{chart_id}","plugin")
    require(path)

    handler = chart_id.camelize.constantize.new
    handler.experiment = @experiment
    #from 4.2 Rails version ... params html safety
    #params.transform_values {|v| ERB::Util.h(v)}

    #params html safety (< 4.2 version)
    params.each do |parameter|
       params.update(params){ |k, v| ERB::Util.h(v)}
    end
    handler.parameters = params

    @content = handler.handler
    #waiting for better time ...
    chart_header =""
    #if(!@parameters["type"] || @parameters["type"]=="scalarm")
    chart_header = render_to_string :file => Rails.root.join('app','visualisation_methods', chart_id, "chart.html.haml"), layout: false
    #end
    render :html => (chart_header + @content.to_s.html_safe), layout: false

    #else
    #  raise 'Not authorised'
    #end

  end
end