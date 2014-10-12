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

class DSD < ObservableArray
    attr_accessor :timers

    def initialize(configuration, &callback)
        @callback = callback

        @timers = {}

        configuration["items"].each.with_index do |item, index|
            item = item["item"]
            @timers.merge!({
                item["name"].to_sym => EM.add_periodic_timer(item["period"]) do
                    case item["type"]
                    when "time"
                        self[index] = time item["format"]
                    when "file"
                        self[index] = file item["path"], item["unit"]
                    when "array_from_file"
                        self[index] = array_from_file item["path"], item["range"]
                    when "formatted_string_from_file"
                        self[index] = formatted_string_from_file item["path"], item["format"]
                    end
                end
            })
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
        File.read(path).strip.split[ends[0]..ends[1]].join " "
    end

    def formatted_string_from_file(path, format)
        sprintf format, File.read(path).strip
    end
end

opts = Trollop::options do
    opt :config, "Configuration file", :type => :io, :default => File.open("#{ENV["HOME"]}/.dsd.conf")
    opt :daemon, "Daemonize on startup", :type => :flag, :default => true
    opt :debug, "Save debug log at dsd.log", :type => :flag, :default => false
    opt :repl, "Start a repl", :type => :flag, :default => true
end

ConfigHash = YAML.parse(opts[:config].read).to_ruby

Daemons.daemonize({:app_name => "dsd", :backtrace => opts[:debug], :ontop => not(opts[:daemon])})

EM.run do
    $statusbar = DSD.new(ConfigHash["statusbar"]) { Xname.xname $statusbar.reverse.join " | " }
    EventMachine::start_server '127.0.0.1', ConfigHash["repl"]["port"], SimpleRepl if opts[:repl]
end
