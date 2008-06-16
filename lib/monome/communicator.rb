# for list of osc commands see
# - http://docs.monome.org/doku.php?id=tech:protocol:osc
# - http://docs.monome.org/doku.php?id=tech:protocol:osc2

require 'osc'
module Monome
  class Communicator
    attr_accessor :listeners
    attr_reader :max_x, :max_y, :led_status
    
    def initialize(monome, state, monome_type, prefix='ruby_monome', in_port=8000, out_port=8080)
      @monome = monome
      @monome_type = monome_type
      @state = state
      @prefix = "/#{prefix}"
      @client = OSC::SimpleClient.new('localhost', out_port)
      @server = OSC::SimpleServer.new(in_port)
    end
    
    def led_on(x,y)
      send_led(x,y,1)
      @state.notify(:message => :led_on, :time => Time.now, :x => x, :y => y)
    end
    
    def led_off(x,y)
      send_led(x,y,0)
      @state.notify(:message => :led_off, :time => Time.now, :x => x, :y => y)
    end
    
    def clear
      @state.notify(:message => :clear, :time => Time.now)
      send_frame_all(:off)
    end
    
    def all
      @state.notify(:message => :all, :time => Time.now)
      send_frame_all(:on)
    end
    
    # hook up methods to recieved osc messages
    def start
      @server.add_method(/^#{@prefix}\/press/i)  { |mesg| do_press(mesg)  } 
      @server.add_method(/^#{@prefix}\/adc/i)    { |mesg| do_adc(mesg)    }
      @server.add_method(/^#{@prefix}\/prefix/i) { |mesg| do_prefix(mesg) }
      @server.add_method(nil)                    { |mesg| do_dump(mesg)   }
      @server.run
    end
    
    def status
      @client.send(OSC::Message.new("/sys/report",nil))
    end
    
    private
      def send_led(x,y,led_status)
        @client.send(OSC::Message.new("#{@prefix}/led", nil, x,y, led_status))
      end
      
      def send_frame(offset_x, offset_y, col_1, col_2, col_3, col_4, col_5, col_6, col_7, col_8)
        @client.send(OSC::Message.new("#{@prefix}/frame", nil, offset_x, offset_y, col_1, col_2, col_3, col_4, col_5, col_6, col_7, col_8))
      end
    
      def send_frame_all(led_status)
        code = led_status == :on ? 255 : 0
        case @monome_type
        when '128'
          send_frame(0, 0, code, code, code, code, code, code, code, code)
          send_frame(8, 0, code, code, code, code, code, code, code, code)
        when '64', '40h'
          send_frame(0, 0, code, code, code, code, code, code, code, code)
        when '256'
          send_frame(0, 0, code, code, code, code, code, code, code, code) 
          send_frame(8, 0, code, code, code, code, code, code, code, code) 
          send_frame(8, 8, code, code, code, code, code, code, code, code) 
          send_frame(0, 8, code, code, code, code, code, code, code, code)
        end
      end
    
      # do_ hooks to reacto on messages from monomeserial
      def do_press mesg
        x,y =  mesg.to_a[0..1]
        if mesg.to_a[2] == 1 
          @monome.button_pressed(x,y)
          @state.notify(:message => :button_pressed, :time => Time.now, :x => x, :y => y)
        else
          @monome.button_released(x,y)
          @state.notify(:message => :button_released, :time => Time.now, :x => x, :y => y)
        end
      end
      
      def do_adc mesg
        #puts "#{mesg.to_a.to_s}"
      end
      
      def do_prefix mesg
        puts "#{mesg.to_a.to_s}"
      end
      
      def do_dump mesg
        params = mesg.to_a.join(',')
        puts "#{mesg.address}: #{params}"
      end
  end
end

