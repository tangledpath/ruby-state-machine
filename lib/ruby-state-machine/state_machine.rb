require 'ruby-state-machine/bounded_array'

# StateMachine
# Simple and flexible state machine.  Define a state machine with an array of states,
# an array of events, and one or more transition actions.  A transition can be
# as simple as the symbol for the next state, a lambda (code) to execute.  Primitive
# branching can also be achieved if necessary by using a "decider" instance method.
#
# The {StateMachineTest} (view source) also contains examples and unit tests for most (if not all)
# of the available functionality.  
# Also see {http://ruby-state-mach.rubyforge.org/ README} for examples
# @see ClassMethods#state_transition StateTransition for full details on the variations available.
# @see StateMachineTest
module StateMachine
  def self.included(base)
    base.extend StateMachine::ClassMethods
  end
  
  
  module ClassMethods  
    attr_accessor :machine    
    
    # Create state machine with the following options:
    #  states Array[symbols], each symbol is name of state
    #  events Array[symbols], each symbol is name of event
    #  default_state symbol, symbol is one of states
    def state_machine(opts)
      @machine = StateMachine::Machine.new(opts)
      self.send(:include, StateMachine::InstanceMethods)
    end      

    # Add a transition to state machine with the following keys:
    # :state=>state (symbol) for which transition is being declared
    # :event=>event (symbol) which causes transition
    # :decider=>name of instance method on state machine specialization that "decides"
    #           next state in case of multiple actions for next state (see below).
    #           Method in question should return name of next state, or name of action
    #           if actions are named (not required).
    # :next=>action to take for this transition, one of:
    #     1) state name(symbol), or special symbol (:stay), which stays at current state
    #     2) hash{:state=>state name(symbol), :action=>code/lambda(string), :name=>id of action, for decider}
    #     3) array of 1 and/or 2.  Decider required in this case.      
    #
    # Example 1:
    #   state_transition :state=>:c_state, :event=>:w_event, :decider => :c_state_decider, 
    #     :next=>[
    #       {:state=>:a_state, :action=>lambda{|o, args| o.increment_value(7)} }, 
    #       {:state=>:b_state, :action=>lambda{|o, args| o.increment_value(-10)} }
    #     ]        
    #
    # Example 2 (stays at current state):
    #   state_transition :state=>:c_state, :event=>:y_event, :next=>{:state=>:stay, :action=>lambda{|o, args| o.increment_value(-3)}}
    #                   
    # Example 3:
    #   state_transition :state=>:b_state, :event=>:z_event, :next=>:a_state
    def state_transition(opts)
      @machine.add_transition(opts)
    end
    
    def default_state; @machine.default_state; end
    def states; @machine.states; end
    def events; @machine.events; end
    def transitions; @machine.transitions; end
    def next_state(*args); @machine.next_state(*args); end
    def next_state_instruction(*args); @machine.next_state_instruction(*args); end
  end
  
  module InstanceMethods
    attr_accessor :event_history

    def initialize(args=nil)
      @current_state = default_state
      @event_history = BoundedArray.new
      # Attempt to call super:
      begin
        super(args)
      rescue ArgumentError
        super() 
      end
      #puts "Current state is #{@current_state} #{@current_state.class}"
    end
    
    def send_event(event)
      # puts "Sending event: #{event}"
      check_current_state
      next_state_instruction = self.class.next_state_instruction(@current_state, event)
      if next_state_instruction.nil?
        cs = @current_state
        # This was causing problems in unit tests:
        # @current_state = default_state
        # puts "Returned to default state: [#{@current_state}]."
        raise InvalidStateError, "No valid next state for #{cs.inspect} using event #{event.inspect} (#{cs.class}/#{event.class})." 
      end
      
      if(next_state_instruction)
        if(!String(next_state_instruction[:decider]).empty?)
          # Decider present, call method:
          decide_id = execute(next_state_instruction[:decider], event)
          
          # Error checking:
          if String(decide_id).empty?
            raise InvalidStateError, 
              "Decider returned blank/nil for #{@current_state} using event #{event}.  Next state from decider: [#{decide_id.inspect}].  Possible next states are [#{next_state_instruction[:next].inspect}]"  
          end
          
          # Find next state:
          instruction = Array(next_state_instruction[:next]).detect { |i| 
            i[:state].to_sym==decide_id.to_sym or i[:name].to_sym==decide_id.to_sym
          } 

          # Error checking:
          if instruction.nil?
            raise InvalidStateError, 
              "No valid next instruction for #{@current_state} using event #{event}.  Next state from decider: [#{decide_id.inspect}(#{decide_id.class})].  Possible next states are [#{next_state_instruction[:next].inspect}]"  
          end
          
          # Do it:
          process_instruction(instruction, event)
        else            
          # Do it:
          process_instruction(next_state_instruction[:next], event)
        end
        @current_state
      end
      @event_history.push(event)
    end
  
    def current_state
      check_current_state
      @current_state
    end
    
    def current_state=state
      @current_state = state.to_sym
    end
    
    def default_state
      (self.class.default_state) ? self.class.default_state : self.class.states.first
    end

  private 
          
    def process_instruction(instruction, event)
      if instruction.nil?
        @current_state = default_state
        puts "Returned to default state: [#{@current_state}]."
        raise InvalidStateError, "No valid next instruction for #{@current_state} using event #{event}" 
      end
      
      if(instruction.is_a?Symbol)
        change_state(instruction)
      else
        #puts "Processing action: #{instruction[:action]}"
        execute(instruction[:action], event)
        change_state(instruction[:state])
      end
    end
    
    def execute(action, event)
      unless action.nil?
        if Symbol === action
          self.method(action).call(:event=>event) 
        else
          action.call(self, :event=>event)
        end
      end
    end
    
    def change_state(state_sym)
      case(state_sym)
        when :back
          raise InvalidStateError, "Back is reserved but not yet implemented." 
        when :stay
          @current_state = @current_state # nop, but should queue
        else
          @current_state = state_sym    
      end        
    end
    
    def check_current_state
      raise InvalidStateError, "No valid current state.  Please call super() from state machine impl." if @current_state.nil?
    end
          
  end
  
  class Machine
    attr_accessor :states
    attr_accessor :events
    attr_accessor :transitions
    attr_accessor :default_state
    
    def initialize(opts)
      @states=opts[:states].collect{|state| state.to_sym}
      @events=opts[:events].collect{|event| event.to_sym}
      @default_state=opts[:default_state].to_sym if opts[:default_state]
      @transitions=[]
    end
    
    def add_transition(opts)
      new_opts=strings_to_sym(opts)
      
      # Some validation for arrays of actions:
      if (new_opts[:next].is_a?Array)
        if new_opts[:next].length==1
          new_opts[:next] = new_opts[:next].first
        elsif new_opts[:next].length>1
          raise ArgumentError, "A decider must be present for multiple actions." if String(new_opts[:decider]).empty?
        end
      end
      
      @transitions << new_opts
    end
    
    def strings_to_sym(hash)
      new_hash=hash.dup
      hash.each do |k, v| 
        unless (v.nil? or (v.respond_to?:empty? and v.empty? ))
          if (v.is_a?(Hash))
            new_hash[k] = strings_to_sym(v)
          elsif (v.is_a?(Array))
            new_array = v.dup
            v.each_with_index do |array_hash, index|
              new_array[index] = strings_to_sym(array_hash) if array_hash.is_a?(Hash)
            end
            new_hash[k]=new_array
          elsif (v.is_a?(String))
            new_hash[k] = v.to_sym
          end
        end
      end
      new_hash
    end
    
    # Next state (symbol only) for given state and event.
    # (equivalent to next_state_instruction(state, event)[:next_state])
    def next_state(state, event)
      transition = next_state_instruction(state, event)
      ns = transition ? transition[:next] : nil
      (ns.is_a?Symbol) ? ns : ns && ns[:state]
    end
    
    # Next state instruction (as hash) for given state and event:
    def next_state_instruction(state, event)
      @transitions.detect{|t| t[:state]==state and t[:event]==event}
    end
  end
  
  class InvalidStateError < Exception #:nodoc:
    
  end
  
end
