
# -*- encoding: utf-8 -*-

# Copyright (c) 2013 Mario Freitas (imkira@gmail.com)
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'fluent/plugin/in_tail'

module Fluent
  class EventTailInput < Fluent::TailInput
    Fluent::Plugin.register_input('event_tail', self)

    config_param :time_format, :string, :default => '%Y-%m-%d %H:%M:%S %z'

    # don't need tag parameter
    config_set_default(:tag, '')

    # don't need format parameter
    config_set_default(:format, '')

    def configure_parser(conf)
      # just disable the default parser
    end

    def receive_lines(lines)
      array = []
      last_tag = nil
      lines.each do |line|
        begin
          line.chomp!
          parse_line(line) do |tag, time, record|
            if last_tag != tag
              emit_array(last_tag, array)
              array = []
              last_tag = tag
            end
            array.push([time, record])
          end
        rescue
          $log.warn line.dump, :error=>$!.to_s
          $log.debug_backtrace
        end
      end
      emit_array(last_tag, array)
    end

    def emit_array(tag, array)
      unless tag.nil? || array.empty?
        begin
          Engine.emit_array(tag, array)
        rescue => e
          # ignore errors. Engine shows logs and backtraces.
        end
      end
    end

    def parse_line(line, &block)
      msg = Yajl.load(line)
      tag = msg[0].to_s
      entries = msg[1]

      # [tag, [[time,record], [time,record], ...]]
      if entries.is_a? Array
        entries.each do |e|
          time = parse_time(e[0])
          record = e[1]
          block.call(tag, time, record)
        end

        # [tag, time, record]
      else
        time = parse_time(msg[1])
        record = msg[2]
        block.call(tag, time, record)
      end
    end

    def parse_time(time)
      if !@time_format.nil? and time.is_a? String
        Time.strptime(time, @time_format).to_f
      else
        time = time.to_i
        time = Engine.now if time == 0
        time
      end
    end
  end
end
