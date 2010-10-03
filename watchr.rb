ENV["WATCHR"] = "1"
system 'clear'

def result_regexp
  /\d+\stests,\s\d+\sassertions,\s\d+\sfailures,\s\d+\serrors,\s\d+\sskips/
end

def test_status result
  if result.is_a? Array
    result.all? { |m| m.include?('0 failures, 0 errors') }
  elsif result.is_a? String
    result.include?('0 failures, 0 errors')
  end
end

def growl(message)
  growlnotify = `which growlnotify`.chomp
  title = "Watchr Test Results"
  image = test_status(message) ? "~/.watchr/pass.png" : "~/.watchr/fail.png"
  options = "-w -n Watchr --image '#{File.expand_path(image)}' -m '#{message}' '#{title}'"
  system %(#{growlnotify} #{options} &)
end

def run(cmd)
  puts(cmd)
  `#{cmd}`
end

def run_test_file(file)
  system('clear')
  result = run(%Q(ruby -I"lib:test" -rubygems #{file}))
  growl result.scan(result_regexp).last rescue nil
  puts result
end

def run_all_tests
  system('clear')
  result = run "rake test"
  growl result.scan(result_regexp) rescue nil
  puts result
end

def related_test_files(path)
  Dir['test/**/*.rb'].select { |file| file =~ /#{File.basename(path).split(".").first}_test.rb/ }
end

def run_suite
  run_all_tests
end

watch('test/test_helper\.rb') { run_all_tests }
watch('test/.*/.*_test\.rb') { |m| run_test_file(m[0]) }
watch('app/.*/.*\.rb') { |m| related_test_files(m[0]).map {|tf| run_test_file(tf) } }

# Ctrl-\
Signal.trap 'QUIT' do
  puts " --- Running all tests ---\n\n"
  run_all_tests
end

@interrupted = false

# Ctrl-C
Signal.trap 'INT' do
  if @interrupted then
    @wants_to_quit = true
    abort("\n")
  else
    puts "Interrupt a second time to quit"
    @interrupted = true
    Kernel.sleep 1.5
    # raise Interrupt, nil # let the run loop catch it
    run_suite
  end
end
