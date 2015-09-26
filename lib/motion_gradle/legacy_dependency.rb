module MotionGradle
  class LegacyDependency
    def initialize(name, params)
      @options = normalized_dependency(name, params)
    end

    def parse
      options = @options.delete_if { |_, v| v.nil? }.map { |k, v| "#{k}: '#{v}'" }
      "compile #{options.join(', ')}"
    end

    protected

    def normalized_dependency(name, params)
      {
        group: name,
        version: params.fetch(:version, '+'),
        name: params.fetch(:artifact, name),
        ext: params.fetch(:extension, nil)
      }
    end
  end
end
