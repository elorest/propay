module Propay
  module Fixnum
    def fibo
      self.times.each_with_object([0,1]) { |num, obj| obj << obj[-2] + obj[-1] }
    end
  end
  ::Fixnum.send(:include, Propay::Fixnum) if configuration.fib
end

