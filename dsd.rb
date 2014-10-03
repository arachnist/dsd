#!/usr/bin/env ruby

require 'eventmachine'
require 'date'
require 'ffi'
require 'yaml'

module Xname
    extend FFI::Library
    ffi_lib 'xname'
    attach_function :xname, [ :string ], :int
end

class ObservableArray < Array
    def initialize(&callback)
        @callback = callback
    end

    def []=(index, value)
        @callback.call
        super(index, value)
    end
end

class String
    def to_proc
        eval "Proc.new { |*args| #{self} }"
    end
end

$a = ObservableArray.new { Xname.xname $a.join " " }

EM.run do
    EM.add_periodic_timer(1) { $a[0] = DateTime.now.to_s }
    EM.add_periodic_timer(5) { $a[1] = File.read("/proc/loadavg").split[0..2].join " " }
end
