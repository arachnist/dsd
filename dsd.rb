#!/usr/bin/env ruby

require 'eventmachine'
require 'date'
require 'ffi'
require 'yaml'
require 'trollop'

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

def parse_config(h)
    $a = eval("ObservableArray.new { #{h["statusbar"]["update_code"]} }")

    h["statusbar"]["items"].each.with_index do |item, index|
        eval("EM.add_periodic_timer(#{item["item"]["period"]}) { $a[#{index}] = #{item["item"]["code"]} }")
    end
end

opts = Trollop::options do
    opt :config, "Configuration file", :type => :io, :default => File.open("#{ENV["HOME"]}/.dsd.conf")
end

h = YAML.parse(opts[:config].read).to_ruby

EM.run do
    parse_config(h)
end
