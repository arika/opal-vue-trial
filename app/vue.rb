class Vue
  class << self
    def inherited(sub)
      sub.class_eval do
        @_root_class = ::Vue
        @_method_mode = :public
        @_methods = []
        @_computed = []
        @_data = {}
        @_template = nil
        @_props = []
      end
    end

    def _methods
      _inject_ancestor(@_methods.dup) do |s, cls|
        s << cls._methods
      end
    end

    def _computed
      _inject_ancestor(@_computed.dup) do |s, cls|
        s << cls._computed
      end
    end

    def _data
      _inject_ancestor(@_data.dup) do |s, cls|
        s.merge(cls._data)
      end
    end

    def _inject_ancestor(initial)
      ancestors.inject(initial) do |s, cls|
        break s if cls == @_root_class
        next s if cls == self
        next s unless cls.is_a?(Class)
        yield(s, cls)
      end
    end

    def public(*names)
      @_method_mode = :public if names.empty?
      super
    end

    def private(*names)
      @_method_mode = :private if names.empty?
      super
    end

    def computed(*names)
      @_method_mode = :computed if names.empty?
      names.each do |name|
        @_computed << name unless @_computed.include?(name)
      end
    end

    def method_added(name)
      super
      if @_method_mode == :computed
        @_computed << name unless @_computed.include?(name)
      elsif @_method_mode == :public
        @_methods << name unless @_methods.include?(name)
      end
    end

    def _ignore_method_added
      save_method_mode = @_method_mode
      @_method_mode = :ignore
      yield
    ensure
      @_method_mode = save_method_mode
    end

    def data(*names, **defaults)
      _ignore_method_added do
        (names + defaults.keys).each do |name|
          @_data[name] = defaults[name]

          define_method(name) { _vue.JS[name] }
          define_method("#{name}=") {|value| _vue.JS[name] = value }
        end
      end
    end

    def props(*names)
      _ignore_method_added do
        names.each do |name|
          next if @_props.include?(name)
          @_props << name
          define_method(name) { _vue.JS[name] }
          define_method("#{name}=") {|value| _vue.JS[name] = value }
        end
      end
    end

    def template(template)
      @_template = template
    end

    def vue_options(defaults, data_as_function: false)
      options = { methods: {}, computed: {}, data: nil }.to_n

      data_proc = lambda do
        data = {}.to_n
        _data.each do |name, default|
          initial = defaults[name] || default
          initial = initial.call(self) if initial.respond_to?(:call)
          data.JS[name] = initial
        end
        data
      end

      if data_as_function
        options.JS[:data] = data_proc.to_n
      else
        options.JS[:data] = data_proc.call
      end

      options.JS[:template] = @_template.to_n unless @_template.nil?
      options.JS[:props] = @_props.to_n unless @_props.empty?

      options
    end
  end

  def initialize(selector, template = nil, **defaults)
    options = _vue_options(defaults)
    options.JS[:template] = template if template
    @vue = `new Vue(options)`
    _mount(selector)
  end

  def emit(*args)
    @vue.JS['$emit'].JS.apply(@vue, args)
  end

  def _mount(selector)
    return unless selector
    `#{@vue}.$mount(selector)`
  end

  def _vue_options(defaults)
    options = self.class.vue_options(defaults)

    methods = options.JS[:methods]
    self.class._methods.each do |name|
      methods.JS[name] = method(name).to_proc
    end

    computed = options.JS[:computed]
    self.class._computed.each do |name|
      computed.JS[name] = method(name).to_proc
    end

    options
  end

  def _vue
    @vue
  end
end
