require 'test/unit'
#require "#{File.dirname(__FILE__)}/../init"

require 'ruby-state-machine/state_machine'

# Fixture for testing state machine:
class StateMachineFixture
  include StateMachine
  attr_accessor :test_val, :prev_test_val, :proc_val, :force_decide_nil, :name_for_decider
  
  
  state_machine :states => [:a_state, :b_state, :c_state, :d_state], :events => [:w_event, :x_event, :y_event, :z_event]
  state_transition :state=>:a_state, :event=>:w_event, :next=>{:state=>:b_state, :action=>lambda{|o, args| o.increment_value(5)} }
  state_transition :state=>:a_state, :event=>:x_event, :next=>:c_state
  state_transition :state=>:a_state, :event=>:y_event, :next=>:a_state
  state_transition :state=>:a_state, :event=>:z_event, :next=>:b_state
                                                            
  state_transition :state=>:b_state, :event=>:w_event, :next=>:b_state
  state_transition :state=>:b_state, :event=>:y_event, :next=>:c_state
  state_transition :state=>:b_state, :event=>:z_event, :next=>:a_state
                                                            
  state_transition :state=>:c_state, :event=>:x_event, :next=>:b_state
  state_transition :state=>:c_state, :event=>:y_event, :next=>{:state=>:a_state, :action=>lambda{|o, args| o.increment_value(-3)}}

  state_transition :state=>:c_state, :event=>:w_event, :decider => :c_state_decider, 
    :next=>[
      {:state=>:a_state, :action=>lambda{|o, args| o.increment_value(7)} }, 
      {:state=>:b_state, :action=>lambda{|o, args| o.increment_value(-10)} }
    ]
    
  state_transition :state=>:c_state, :event=>:z_event , :decider => :named_action_decider, 
      :next=>[
        {:name=>"foo", :state=>:a_state, :action=>lambda{|o, args| o.increment_value(7)} }, 
        {:name=>"bar", :state=>:d_state, :action=>lambda{|o, args| o.increment_value(-10)} }
      ]
  
  state_transition :state=>:d_state, :event=>:x_event, :next=>:stay
  
  def initialize
    super
    @test_val = nil
    @proc_val = 0
    @force_decide_nil = false
    @name_for_decider = "foo"
  end
  
  def increment_value(by)
    @proc_val += by
  end
  
  def bush(term)
    @prev_test_val = @test_val
    @test_val=term
    send_event(:w_event)
  end
  
  def c_state_decider(args)
    if @force_decide_nil
      # Hack to test nil decider:
      nil
    else
      refined = (@test_val and @prev_test_val and @test_val.index(@prev_test_val)==0)    
      refined ? :b_state : :a_state
    end
  end
  
  def named_action_decider(args)
    @name_for_decider
  end
    
end

# Test state machine:
class StateMachineTest < Test::Unit::TestCase

  def test_states
    assert_equal(:d_state, StateMachineFixture.states.last)
  end

  def test_events
    assert_equal(:w_event, StateMachineFixture.events.first)
  end
  
  def test_next_states
    assert_equal(:b_state, StateMachineFixture.next_state(:a_state, :w_event))
    assert_equal(:c_state, StateMachineFixture.next_state(:a_state, :x_event))
    assert_equal(:b_state, StateMachineFixture.next_state(:b_state, :w_event))
    assert_equal(:a_state, StateMachineFixture.next_state(:b_state, :z_event))
    assert_equal(:a_state, StateMachineFixture.next_state(:c_state, :y_event))
    assert_equal(:b_state, StateMachineFixture.next_state(:c_state, :x_event))    
    assert_nil(StateMachineFixture.next_state(:b_state, :x_event))
  end
  
  def test_event_sending
    sm = StateMachineFixture.new
    assert_equal(:a_state, sm.current_state)
    sm.send_event(:w_event)
    
    assert_equal(:b_state, sm.current_state)
    assert_raise(StateMachine::InvalidStateError){sm.send_event(:x_event)}

    sm.send_event(:w_event)    
    assert_equal(:b_state, sm.current_state)

    sm.send_event(:z_event)    
    assert_equal(:a_state, sm.current_state)
    
    sm.send_event(:x_event)    
    assert_equal(:c_state, sm.current_state)    
  end
  
  def test_action_calling
    sm = StateMachineFixture.new
    assert_equal(0, sm.proc_val)
    assert_equal(:a_state, sm.current_state)
    sm.send_event(:w_event)
    assert_equal(5, sm.proc_val)

    sm.send_event(:y_event)
    assert_equal(5, sm.proc_val)
    
    sm.send_event(:y_event)    
    assert_equal(2, sm.proc_val)    
  end
  
  def test_decider
    sm = StateMachineFixture.new
    assert_equal(:a_state, sm.current_state)
    sm.send_event(:x_event)
    sm.bush("foo")
    assert_equal(:a_state, sm.current_state)
    sm.bush("foobar")
    assert_equal(:b_state, sm.current_state)
    sm.send_event(:y_event)
    sm.bush("barfoo")
    assert_equal(:a_state, sm.current_state)    
  end
  
  def test_nil_decider
    sm = StateMachineFixture.new
    assert_equal(:a_state, sm.current_state)
    sm.send_event(:x_event)        
    assert_equal(:c_state, sm.current_state)
    sm.force_decide_nil=true
    assert_raise(StateMachine::InvalidStateError){sm.send_event(:w_event)}    
  end
  
  def test_multiple_actions_without_decider
    assert_raise(ArgumentError) do
      StateMachineFixture.state_transition :state=>:c_state, :event=>:z_event, #:decider => :c_state_decider, 
        :next=>[
          {:state=>:a_state, :action=>lambda{|o, args| o.increment_value(7)} }, 
          {:state=>:b_state, :action=>lambda{|o, args| o.increment_value(-10)} }
        ]
    end    
  end
  
  def test_named_actions_in_decider
    sm = StateMachineFixture.new
    assert_equal(:a_state, sm.current_state)
    sm.send_event(:x_event)        
    assert_equal(:c_state, sm.current_state)
    sm.send_event(:z_event)            
    
    # Default value (foo) for named decider:
    assert_equal(:a_state, sm.current_state)

    # Back to a_state:
    sm.send_event(:x_event)        
    assert_equal(:c_state, sm.current_state)

    # Alt value (bar) for named decider:
    sm.name_for_decider = 'bar'
    sm.send_event(:z_event)            
    assert_equal(:d_state, sm.current_state)    
  end
  
  def test_stay_state
    sm = StateMachineFixture.new
    
    # Get to :d state:
    sm.send_event(:x_event)        
    sm.name_for_decider = 'bar'
    sm.send_event(:z_event)        
    assert_equal(:d_state, sm.current_state)
    
    # Send event & make sure we are still in :d state:
    sm.send_event(:x_event)            
    assert_equal(:d_state, sm.current_state)     
  end
  
  def test_event_history
    sm = StateMachineFixture.new
    assert_equal(0, sm.event_history.size)     
    sm.send_event(:x_event)        
    assert_equal(1, sm.event_history.size)     
    assert_equal([:x_event], sm.event_history)     
    sm.send_event(:y_event)        
    assert_equal(2, sm.event_history.size)     
    assert_equal([:x_event, :y_event], sm.event_history)     
    sm.send_event(:y_event)        
    assert_equal(3, sm.event_history.size)     
    assert_equal([:x_event, :y_event, :y_event], sm.event_history)

    # Should max out at 10:
    15.times{sm.send_event(:z_event)}
    assert_equal(10, sm.event_history.size)     
    assert_equal(Array.new(10, :z_event), sm.event_history)
    
  end
  
end
