module MotionGradle
  class Template
    attr_accessor :destination

    def initialize(name)
      template_path = File.expand_path("../templates/#{name}.erb", __FILE__)
      @template = ERB.new(File.new(template_path).read)
    end

    def write(locals = {})
      File.open(self.destination, 'w') do |io|
        struct = OpenStruct.new(locals)
        io.puts(@template.result(struct.instance_eval { binding }))
      end
    end
  end
end
