#!/usr/bin/env ruby

require 'eventmachine'
require 'date'

$a = []

EM.run do
    EM.add_periodic_timer(1) { $a[0] = DateTime.now.to_s }
    EM.add_periodic_timer(5) { $a[1] = File.read("/proc/loadavg").split[0..2].join " " }

    EM.add_periodic_timer(0.1) { puts $a.join " " }
end
