module MotionGradle
  class Dependency
    attr_reader :name
    attr_reader :excludes

    def initialize(name, &block)
      @name = name
      @excludes = []
      instance_eval(&block) if block_given?
    end

    def exclude(options = {})
      @excludes << options
    end
  end
end
