## Ruby State Machine
Ruby State Machine (ruby-state-machine) is a full-featured state machine gem for use within ruby.  It can also be used in Rails.  This was written because we required a state machine that allowed different actions to be performed based on the previous and current events, as well as injecting logic (a "decider") to determine the next event.  

## Installation:

Add this line to your application's Gemfile:

    gem 'ruby-state-machine'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ruby-state-machine

## Location:
Here: http://github.com/tangledpath/ruby-state-machine

RDocs: http://ruby-state-mach.rubyforge.org/


## USAGE:

```ruby
require 'ruby-state-machine/state_machine'

# Note, a state machine is not created directly; instead, the behavior of a state
# machine is added through a mixin, e.g.:
class SampleMachine
  include StateMachine
  state_machine :states => [:a_state, :b_state, :c_state, :d_state], :events => [:w_event, :x_event, :y_event, :z_event]
  state_transition :state=>:a_state, :event=>:x_event, :next=>:c_state # Define next state for :a_state when :x_event is sent
  state_transition :state=>:a_state, :event=>:y_event, :next=>:a_state # Define next state for :a_state when :y_event is sent
  state_transition :state=>:a_state, :event=>:z_event, :next=>:b_state # ...
                                                            
  state_transition :state=>:b_state, :event=>:w_event, :next=>:b_state
  state_transition :state=>:b_state, :event=>:y_event, :next=>:c_state
  state_transition :state=>:b_state, :event=>:z_event, :next=>:a_state
                                                            
  state_transition :state=>:c_state, :event=>:x_event, :next=>:b_state
end
```

sm = SampleMachine.new
puts sm.current_state # :a_state
sm.send_event(:x_event)
puts sm.current_state # :c_state
```

For examples of other functionality, including branching, deciders, lambdas, etc, see http://ruby-state-mach.rubyforge.org/StateMachine/ClassMethods.html#state_transition-instance_method.


## CONTRIBUTE

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## LICENSE:

(The MIT License)

Copyright (c) 2007-2013 Steven Miers

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

