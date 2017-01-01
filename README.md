### Enable UDP

Ensure that syslogd has udp sockets enabled:
[OS X](http://wiki.springsurprise.com/2010/01/30/enable-remote-logging-on-mac-os-x/)

Rsyslogd documentation can help you on Linux.

You can cheat with netcat :

		sudo nc -lu  514


### Build

		./rebar compile
		sudo ./rebar install
    
### Log

A macro helps you to log

Include it:

		-include_lib("syslog/src/syslog.hrl").

Start it:

		application:start(syslog),
		ok = syslog:settings("localhost", 514, user),

You can use default settings, and forget this line.

Use it:

		?SYSLOG_INFO(wombat, "~p is happy", ["Wombat"])

### Logged

    $ syslog
    ...
    Tue Mar 16 18:36:48 192.168.1.101  wombat/test[<0.39.0>]: 47: Wombat is happy

In th log, you've got : _application_, "/", _module_, "[", _pid_, "]: ", _line_, ":", _message_

### TODO
 * √ UDP
 * _ TCP
 * √ destination host
 * √ destination port
 * √ level
 * √ facility
