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
    attr_accessor :callback, :suppress

    def initialize(&callback)
        @callback = callback
    end

    def []=(index, value)
        super(index, value)
        @callback.call unless @suppress
        self
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
                    self[index] = self.send item["type"], item["args"]
                end
            })
        end
    end

    def time(hash = {"format" => "%Y-%m-%d %H:%M:%S"})
        DateTime.now.strftime hash["format"]
    end

    def file(hash = {})
        File.read(hash["path"]).strip + hash["unit"]
    end

    def array_from_file(hash = {})
        ends = hash["range"].split('..').map { |s| Integer(s) }
        File.read(hash["path"]).strip.split[ends[0]..ends[1]].join " "
    end

    def formatted_string_from_file(hash = {})
        sprintf hash["format"], File.read(hash["path"]).strip
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
    $statusbar = DSD.new(ConfigHash["statusbar"]) do
        $statusbar.suppress = true
        Xname.xname $statusbar.reverse.join " | "
        EM.add_timer(0.5) { $statusbar.suppress = false }
    end
    EventMachine::start_server '127.0.0.1', ConfigHash["repl"]["port"], SimpleRepl if opts[:repl]
end
