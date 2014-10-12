dsd
===

A small statusbar updater in ruby

## Configuration
Configuration is read from a yaml file at ~/.dsd.conf
See dot.dsd.conf.example for an example.

## Requirements
 * eventmachine
 * ffi
 * libxname (https://github.com/Igneous/libxname)
 * trollop
 * daemonize

## REPL
DSD features a built-in REPL, which is useful for debugging or adding new features.
To try it out you can simply connect using netcat to a port defined in configuration file, like this:
```ShellSession
$ nc localhost 1337
nc: using stream socket
Welcome to dsd repl.
$statusbar
> ["2014-10-12 08:43:07", "0.04 0.06 0.10", "64%", "Discharging", "42 C"]
```
Or you can add rlwrap to the mix, to make editing a bit easier:
```ShellSession
$ rlwrap nc localhost 1337
nc: using stream socket
Welcome to dsd repl.
(reverse-i-search)`.': $statusbar.timers[:cpu_temp].interval
```
The main object of interest is the `$statusbar` object and its `.timers` attribute.
Let's have a look:
```ShellSession
$ rlwrap nc localhost 1337
nc: using stream socket
Welcome to dsd repl.
$statusbar
> ["2014-10-12 08:51:18", "0.15 0.12 0.12", "61%", "Discharging", "42 C"]
$statusbar.timers[:cpu_temp]
> #<EventMachine::PeriodicTimer:0x00000001c3b0d0>
$statusbar.timers[:cpu_temp].interval
> 1
$statusbar.timers[:cpu_temp].interval = 5
> 5
```
Here we've just changed our cpu temperature monitor update interval to 5 seconds.
Let's try something a bit trickier now:
```ShellSession
$ rlwrap nc localhost 1337
nc: using stream socket
Welcome to dsd repl.
$statusbar.count
> 5
$statusbar.timers[:random] = EM.add_periodic_timer(0.3) { $statusbar[5] = rand(1024) }
> #<EventMachine::PeriodicTimer:0x00000001cb89b8>
```
Here we've just added a random number to our statusbar that changes every 0.3 seconds
You can also remove entries from the statusbar:
```ShellSession
$ rlwrap nc localhost 1337
nc: using stream socket
Welcome to dsd repl.
$statusbar.timers[:random].cancel
> true
$statusbar[5] = nil
>
$statusbar.compact!
> ["2014-10-12 09:05:10", "0.17 0.13 0.13", "55%", "Discharging", "43 C"]
```
Or completly stop the updater:
```ShellSession
$ rlwrap nc localhost 1337
nc: using stream socket
Welcome to dsd repl.
EM.stop
```
One thing to note is that the statusbar will not be reverted when the script is stopped.

## License
MIT, see LICENSE file.
