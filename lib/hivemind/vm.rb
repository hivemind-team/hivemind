require_relative 'runtime'
require_relative 'universal_ast'

module Hivemind
  class VM
    def initialize(ast)
      @ast = ast
    end

    def run(env)
      @ast.run env
    end
  end

  class If
    def run(env)
      if @test.run(env) == env.top[:@true]
        @true_branch.run env
      else
        @else_branch.run env
      end
    end
  end

  class Assign
    def run(env)
      env[@left.value.to_sym] = @right.run(env)
    end
  end

  class Attribute
    def run(env)
      @object.run(env).data[@label.value]
    end
  end

  class AttributeAssign
    def run(env)
      @object.run(env).data[@label.value] = @right.run(env)
    end
  end

  class Call
    def run(env)
      args_values = {}
      function = @function.run(env)
      function.args.zip(@args) do |label, arg|
        args_values[label] = arg
      end
      body_env = Environment.new(env, args_values)
      function.body.map { |expr| expr.run(body_env) }[-1] || env.top[:@nil]
    end
  end

  class List
    def run(env)
      Runtime::HivemindObject.new({_elements: @elements.map { |elem| elem.run(env) }}, env.root[:List])
    end
  end

  class Dictionary
    def run(env)
      dict = {}
      @pairs.each do |pair|
        dict[pair.key.value.to_sym] = pair.value.run(env)
      end
      Runtime::HivemindObject.new({_dict: dict}, env.root[:Dict])
    end
  end

  class Value
    def run(env)
      self
    end
  end

  class ClassDefinition
    def run(env)
      definition = Runtime::HivemindClass.new(@class_name, {})
      @methods.each do |method|
        definition.methods[method.function_name] = method
      end
      env[@class_name] = definition
    end
  end

  class Function
    def run(env)
      self
    end
  end

  class Name
    def run(env)
      env[@value]
    end
  end
end
