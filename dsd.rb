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

class DSD
    attr_accessor :values
    attr_accessor :timers

    def initialize(h = {})
        @values = ObservableArray.new { Xname.xname @values.reverse.join " | " }

        @timers = []

        h["items"].each.with_index do |item, index|
            @timers << EM.add_periodic_timer(item["period"]) do
                @values[index] = case item["type"]
                                 when "time"
                                     time item["format"]
                                 when "file"
                                     file item["path"], item["unit"]
                                 when "array_from_file"
                                     array_from_file item["path"], item["range"]
                                 end
            end
        end
    end

    def time(format = "%Y-%m-%d %H:%M:%S")
        DateTime.now.strftime format
    end

    def file(path, unit = "")
        File.read(path).strip + unit
    end

    def array_from_file(path, range)
        ends = range.split('..').map { |s| Integer(s) }
        File.read(path).strip.split[ends[0]..ends[1]]
    end
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
