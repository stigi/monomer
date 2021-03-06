#!/usr/bin/env jruby -wKU

#introduction of a nicer api, natively supporting threads (without you needing to know about it)

require File.dirname(__FILE__) + '/../lib/monomer'

class Toggle < Monome::Listener
  
  on_key_down do |x,y|
    monome.toggle_led(x,y)
  end

end

Monome::Monome.create.with_listeners(Toggle).start if $0 == __FILE__