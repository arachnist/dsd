#!/usr/bin/env ruby

require 'eventmachine'
require 'date'
require 'ffi'
require 'yaml'
require 'trollop'
require 'daemons'

require_relative 'em-simplerepl'

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

    EventMachine::start_server '127.0.0.1', h["repl"]["port"], SimpleRepl
end

opts = Trollop::options do
    opt :config, "Configuration file", :type => :io, :default => File.open("#{ENV["HOME"]}/.dsd.conf")
    opt :daemon, "Daemonize on startup", :type => :flag, :default => true
end

h = YAML.parse(opts[:config].read).to_ruby

Daemons.daemonize({:app_name => "dsd"}) if opts[:daemon]

EM.run do
    parse_config(h)
end
