class VueComponent < Vue
  class << self
    def inherited(sub)
      super
      sub.class_eval do
        @_root_class = ::VueComponent
      end
    end

    def component_name
      self.name.scan(/[A-Z][^A-Z]*/).map(&:downcase).join('-').gsub(/[-_]+/, '-')
    end

    def activate!
      options = vue_options({}, data_as_function: true)

      # JS側VueComponentインスタンスから
      # Ruby側VueComponentインスンスを生成するためのフック
      initializer = -> (vue) { new(vue) }.to_n
      %x{
        options['beforeCreate'] = function() {
          initializer(this);
        };
        Vue.component(#{component_name}, options);
      }
    end
  end

  # JS側Vueコンポーネントのインスタンスを
  # Ruby側VueComponentインスタンスに紐付ける
  #
  # templateはコンポーネント定義で提供し、
  # それ以外の、特にメソッド類は紐付け時に設定する。
  #
  # NOTE:
  # vm.$optionsは読み込み専用と説明されている
  # (https://jp.vuejs.org/v2/api/#vm-options)ので
  # この実装はよくないやり方かもしれない。
  def initialize(vue)
    options = _vue_options({})
    %x{
      Object.keys(options).forEach(function(key) {
        if (key === 'data') return;
        if (key === 'template') return;
        if (key === 'props') return;
        vue.$options[key] = options[key];
      });
    }
    @vue = vue
  end

  def _vue
    @vue
  end
end
