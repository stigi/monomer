module Monome
  class State    
    attr_reader :max_x, :max_y
    
    def initialize(monome_type='128')
      @monome_type = monome_type
      @max_x, @max_y = find_max_coords_from_monome_type
      @led_status = Hash.new(false)
      @num_messages = 0
    end
    
    def notify(message)
      message = Message.new(@num_messages, message[:message], message[:time], message[:x], message[:y])
      case message.message
      when :led_off
        @led_status[[message.x, message.y]] = false
      when :led_on
        @led_status[[message.x, message.y]] = true
      when :clear
        @led_status = Hash.new(false)
      when :all
        @led_status = Hash.new(true)
      end
      @num_messages += 1
    end
    
    def ascii_status(join_string="\n")
      result = ""
      (0..@max_y).each{|y| result << (0..@max_x).map{|x| @led_status[[x,y]] ? '* ' : '- '}.join + join_string}
      result
    end
    
    def led_status(x,y)
      @led_status[[x,y]]
    end
    
    def type=(type)
      raise 'illegal type' unless ['40h', '64', '128', '256'].include? type
      @monome_type = type
      @max_x, @max_y = find_max_coords_from_monome_type
    end
        
    private
    
    def find_max_coords_from_monome_type
      case @monome_type
      when '128'
        return [15,7]
      when '64', '40h'
        return [7,7]
      when '256'
        return [15,15]
      end
    end
  end
end

