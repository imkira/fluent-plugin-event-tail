require 'fluent/test'
require 'fluent/plugin/in_event_tail'

class EventTailInputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
    FileUtils.rm_rf(TMP_DIR)
    FileUtils.mkdir_p(TMP_DIR)
  end

  TMP_DIR = File.dirname(__FILE__) + "/../tmp"

  CONFIG = %[
    path #{TMP_DIR}/tail.log
    tag t1
    rotate_wait 2s
    pos_file #{TMP_DIR}/tail.pos
  ]

  def create_driver(conf = CONFIG)
    Fluent::Test::InputTestDriver.new(Fluent::EventTailInput).configure(conf)
  end

  def unlink_file(path)
    begin
      File.unlink(path)
    rescue Errno::ENOENT
    end
  end

  def test_configure
    d = create_driver
    assert_equal ["#{TMP_DIR}/tail.log"], d.instance.paths
    assert_equal "t1", d.instance.tag
    assert_equal 2, d.instance.rotate_wait
    assert_equal "#{TMP_DIR}/tail.pos", d.instance.pos_file
  end

  def test_simple_emit
    unlink_file("#{TMP_DIR}/tail.pos")
    File.open("#{TMP_DIR}/tail.log", "w") {|f|
      f.puts '["foo",123,{"bar":"hoge"}]'
    }

    d = create_driver

    d.run do
      sleep 1

      File.open("#{TMP_DIR}/tail.log", "a") {|f|
        f.puts '["foo3",789,{"bar3":"hoge3"}]'
      }
      sleep 1
    end

    emits = d.emits
    assert_equal(emits.length, 1)
    assert_equal("foo3", emits[0][0])
    assert_equal(789, emits[0][1])
    assert_equal({"bar3"=>"hoge3"}, emits[0][2])
  end

  def test_default_time_format
    unlink_file("#{TMP_DIR}/tail.pos")
    File.open("#{TMP_DIR}/tail.log", "w") {|f|
      f.puts '["foo","10/Oct/2010:20:57:59 -0700",{"bar":"hoge"}]'
    }

    d = create_driver

    d.run do
      sleep 1

      File.open("#{TMP_DIR}/tail.log", "a") {|f|
        f.puts '["foo4","2012-10-22 11:57:59 -0100",{"bar4":"hoge4"}]'
      }
      sleep 1
    end

    emits = d.emits
    assert_equal(emits.length, 1)
    assert_equal("foo4", emits[0][0])
    assert_equal(1350910679, emits[0][1])
    assert_equal({"bar4"=>"hoge4"}, emits[0][2])
  end

  def test_composed_emit
    unlink_file("#{TMP_DIR}/tail.pos")
    File.open("#{TMP_DIR}/tail.log", "w") {|f|
      f.puts '["foo",123,{"bar":"hoge"}]'
    }

    d = create_driver

    d.run do
      sleep 1

      File.open("#{TMP_DIR}/tail.log", "a") {|f|
        f.puts '["foo5",[[91011,{"bar5":"hoge5"}],' +
          '["2011-10-24 12:30:20 -0400",{"bar6":"hoge6"}]]]'
      }
      sleep 1
    end

    emits = d.emits
    assert_equal(emits.length, 2)
    assert_equal("foo5", emits[0][0])
    assert_equal(91011, emits[0][1])
    assert_equal({"bar5"=>"hoge5"}, emits[0][2])
    assert_equal("foo5", emits[1][0])
    assert_equal(1319473820, emits[1][1])
    assert_equal({"bar6"=>"hoge6"}, emits[1][2])
  end

  def test_composed_emit_skips_invalid_json_lines
    unlink_file("#{TMP_DIR}/tail.pos")
    File.open("#{TMP_DIR}/tail.log", "w") {|f|
      f.puts '["foo",123,{"bar":"hoge"}]'
    }

    d = create_driver

    d.run do
      sleep 1

      File.open("#{TMP_DIR}/tail.log", "a") {|f|
        f.puts 'test invalid 1'
        f.puts '["foo5",[[91011,{"bar5":"hoge5"}],' +
          '["2011-10-24 12:30:20 -0400",{"bar6":"hoge6"}]]]'
        f.puts 'test invalid 3'
      }
      sleep 2
    end

    emits = d.emits
    assert_equal(emits.length, 2)
    assert_equal("foo5", emits[0][0])
    assert_equal(91011, emits[0][1])
    assert_equal({"bar5"=>"hoge5"}, emits[0][2])
    assert_equal("foo5", emits[1][0])
    assert_equal(1319473820, emits[1][1])
    assert_equal({"bar6"=>"hoge6"}, emits[1][2])
  end

  def test_custom_time_format
    unlink_file("#{TMP_DIR}/tail.pos")
    File.open("#{TMP_DIR}/tail.log", "w") {|f|
      f.puts '["foo",123,{"bar":"hoge"}]'
    }

    conf = CONFIG + %[
      time_format %d %b %Y %H:%M:%S
    ]

    d = create_driver(conf)

    time = "6 Dec 2001 12:33:45"
    d.run do
      sleep 1

      File.open("#{TMP_DIR}/tail.log", "a") {|f|
        f.puts %Q|["foo7","#{time}",{"bar7":"hoge7"}]|
      }
      sleep 1
    end

    time = Time.parse(time)
    emits = d.emits
    assert_equal(emits.length, 1)
    assert_equal("foo7", emits[0][0])
    assert_equal(time.to_f, emits[0][1])
    assert_equal({"bar7"=>"hoge7"}, emits[0][2])
  end
end
