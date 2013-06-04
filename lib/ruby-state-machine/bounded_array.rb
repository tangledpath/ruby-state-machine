class BoundedArray < Array
  attr_accessor :bounded_size
  def push(args)
    super
    @bounded_size ||= 10
    shift until size <= bounded_size
  end
end