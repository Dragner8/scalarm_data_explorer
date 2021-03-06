class Panels
  attr_reader :methods
  attr_reader :groups
  
  def initialize(standalone)
    analysisMethodsConfig = AnalysisMethodsConfig.new
    @methods = analysisMethodsConfig.get_method_names
    @groups = analysisMethodsConfig.get_groups(standalone)
  end
end