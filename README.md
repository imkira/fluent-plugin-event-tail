# fluent-plugin-event-tail

event-tail is an input plugin for [fluentd](http://fluentd.org) based on
[in_tail](http://docs.fluentd.org/articles/in_tail) but for reading
[tag, time, record] JSON messages from a file.

If you use ```fluent-logger-ruby```, ```fluent-logger-node```, and so on, you
are probably connecting to 'localhost' (or worse, to a remote host) and sending
messages via TCP sockets.

That's all fine but what happens if fluentd is down for some reason?
Well, most (if not all) logger implementations keep a list of pending failed
messages and try sending them periodically. But what if your application dies
before having the chance to flush everything to fluentd? Well, you will
probably lose those pending messages.

The reason I made this plugin is to allow me (and hopefully you too) to rather
send those messages, not via TCP sockets, but directly to a file and have
fluentd read them. The obvious advantage is that you always have backups of
your logs in your hard disks in case fluentd is not running or the DB where you
are aggregating them died for some reason. Another reason is, your logs are
still human readable and easily transformable (they are just newline separated
JSON strings).

The format of the messages is based on
[in_forward](http://docs.fluentd.org/articles/in_forward) plugin:

```
stream:
  message...

message:
  [tag, time, record]
  or
  [tag, [[time,record], [time,record], ...]]

example:
  ["myapp.access", [1308466941, {"a"=>1}], [1308466942, {"b"=>2}]]
```

This plugin is mostly based on
[in_tail](http://docs.fluentd.org/articles/in_tail),
and therefore you are expected to append newline separated JSON strings of
messages in the above format. Also note that this plugin supports formatted
time strings via the ```time_format``` config parameter, not just numeric UNIX
timestamps.

## Installation

Add this line to your application's Gemfile:

    gem 'fluent-plugin-event-tail'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fluent-plugin-event-tail

## Configuration

This plugin has the same configuration as
[in_tail](http://docs.fluentd.org/articles/in_tail),
with the exception of ```tag``` and ```format``` that were removed.

```
# fluent.conf
<match prefix.**>
  type event_tail
  path /var/log/your_app.log
  pos_file /var/log/your_app.log.pos
# disable next line to enable custom time formatting
# time_format %d %b %Y %H:%M:%S
</match>
```

## Usage

After running fluentd, you can emit events by appending to the file:

```
# time 0 means "current time on server"
echo '["prefix.debug",0,{"foo":"bar"}]' >> /var/log/your_app.log
# time passed as UNIX timestamp (2013-02-20 01:18:31 +0900)
echo '["prefix.debug1",1361290711,{"foo1":"bar1"}]' >> /var/log/your_app.log
# same time but passed as string
echo '["prefix.debug2","2009-03-26 22:33:12 +0900",{"foo2":"bar2"}]' >> /var/log/your_app.log
# group multiple events in one line by tag
echo '["prefix.debug3",[[1361290714,{"foo3":"bar3"}],[1361290716,{"foo4":"bar4"}]]]' >> /var/log/your_app.log
```

fluentd will report something like:
```
prefix.debug: {"foo":"bar"}
prefix.debug1: {"foo1":"bar1"}
prefix.debug2: {"foo2":"bar2"}
prefix.debug3: {"foo3":"bar3"}
prefix.debug3: {"foo4":"bar4"}
````

Please note that contrarily to ```in_forward``` that only accepts UNIX
timestamps, fluent-plugin-event-tail supports the original in_tail
```time_format``` parameter, so you can also pass strings as event times.
The default value of ```time_format``` is ```'%Y-%m-%d %H:%M:%S %z```.
If you pass a numeric UNIX timestamp then ```time_format``` will be ignored.

## Contributing

You are very welcome to submit patches or improve this plugin.
Just make sure you send me a pull request.

## License

fluent-plugin-event-tail is licensed under the MIT license:

www.opensource.org/licenses/MIT

## Copyright

Copyright (c) 2013 Mario Freitas. See
[LICENSE.txt](http://github.com/imkira/fluent-plugin-event-tail/blob/master/LICENSE.txt) for further details.
