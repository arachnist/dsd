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

module DSD
    def time(format = "%Y-%m-%d %H:%M:%S")
        DateTime.now.strftime format
    end
    module_function :time

    def file(path, unit = "")
        File.read(path).strip + unit
    end
    module_function :file

    def array_from_file(path, range)
        ends = range.split('..').map { |s| Integer(s) }
        File.read(path).strip.split[ends[0]..ends[1]]
    end
    module_function :array_from_file
end

def initialize_statusbar(h)
    $a = eval("ObservableArray.new { #{h["statusbar"]["update_code"]} }")

    h["statusbar"]["items"].each.with_index do |item, index|
        eval("EM.add_periodic_timer(#{item["item"]["period"]}) { $a[#{index}] = #{item["item"]["code"]} }")
    end
end

opts = Trollop::options do
    opt :config, "Configuration file", :type => :io, :default => File.open("#{ENV["HOME"]}/.dsd.conf")
    opt :daemon, "Daemonize on startup", :type => :flag, :default => true
    opt :debug, "Save debug log at dsd.log", :type => :flag, :default => false
    opt :repl, "Start a repl", :type => :flag, :default => true
end

h = YAML.parse(opts[:config].read).to_ruby

Daemons.daemonize({:app_name => "dsd", :backtrace => opts[:debug], :ontop => not(opts[:daemon])})

EM.run do
    initialize_statusbar(h)
    EventMachine::start_server '127.0.0.1', h["repl"]["port"], SimpleRepl if opts[:repl]
end
