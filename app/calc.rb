class Calc < Vue
  OP = { add: :+, sub: :-, mul: :*, div: :/, mod: :% }

  data waiting: -> { [] }
  data calculator: -> { OP.keys.to_n }

  def new_card
    waiting << { num1: nil, num2: nil, dragging: false }.to_n
  end
end

module DragAndDropHelper
  def to_data
    "#{num1},#{num2}"
  end

  def apply_data(data)
    num1, num2 = data.scan(/[-+]?\d+(?:\.\d+)?/)[0, 2]
    self.num1 = str_to_number(num1)
    self.num2 = str_to_number(num2)
  end

  def str_to_number(str)
    return if str.nil? || str.empty?
    str.index('.') ? str.to_f : str.to_i
  end

  def set_dnd_data(ev, data)
    data_transfer(ev).JS.setData('text/plain', data)
  end

  def get_dnd_data(ev)
    data_transfer(ev).JS.getData('text/plain')
  end

  def set_drop_effect(ev, effect)
    data_transfer(ev).JS[:dropEffect] = effect
  end

  def data_transfer(ev)
    ev.JS[:dataTransfer]
  end
end

class CalcCard < VueComponent
  include DragAndDropHelper

  data :num1, :num2, dragging: false
  template '#card-template'

  def drag_start(ev)
    self.dragging = true
    set_dnd_data(ev, to_data);
  end

  def drag_end(ev)
    self.dragging = false
  end
end

class CalcPlace < VueComponent
  include DragAndDropHelper

  props :op
  data :num1, :num2
  template '#place-template'

  def drag_over(ev)
    set_drop_effect(ev, :copy)
  end

  def drop(ev)
    data = get_dnd_data(ev)
    apply_data(data)
  end

  computed

  def op_sym
    Calc::OP[op].to_n
  end

  def result
    sym = op_sym
    return unless sym
    return unless num1.is_a?(Numeric) && num2.is_a?(Numeric)

    num1.public_send(sym, num2)
  end
end

Document.ready? do
  CalcCard.activate!
  CalcPlace.activate!
  Calc.new('#calc') unless Element.find('#calc').empty?
end
