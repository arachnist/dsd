#!/usr/bin/env ruby

require 'eventmachine'
require 'date'
require 'ffi'

module Xname
    extend FFI::Library
    ffi_lib 'xname'
    attach_function :xname, [ :string ], :int
end

$a = []

EM.run do
    EM.add_periodic_timer(1) { $a[0] = DateTime.now.to_s }
    EM.add_periodic_timer(5) { $a[1] = File.read("/proc/loadavg").split[0..2].join " " }

    EM.add_periodic_timer(0.1) { Xname.xname $a.join " " }
end
