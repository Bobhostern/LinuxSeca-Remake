$LOAD_PATH << "."
require 'LSMarshal'
require 'LSError'
require 'boolean-fix'

=begin
Error Levels: 
0 - No Errors
1 - SystemCallError allowed
2 - Any Errors allowed
=end


module LinuxSecaR
	class LSRMain
		attr_accessor :name
		attr_accessor :age
		attr_accessor :quote
		attr_accessor :datamap
		attr_accessor :templatef
		attr_accessor :error_level
		attr_accessor :enable_skip
		private
		attr_accessor :fcont
		attr_accessor :qachecksheet
		attr_accessor :disp
		attr_accessor :ansnuminput
		attr_accessor :correct
		attr_accessor :incorrect
		attr_accessor :skipped
		attr_accessor :skipincorrect
		attr_accessor :quizmode
		public
		def initialize(name, age, quote, quizfilename)
			@name = name
			@age = age
			@quote = quote
			@datamap = LSMarshal.new().loadDataCustomExtension(File.join("data", quizfilename), "lsybindmp")
			@correct = 0
			@incorrect = 0
			@skipped = 0
			@fcont = ""
			@qachecksheet = {}
			@disw = false
			quizfilenamec = quizfilename.split(".")
			if @datamap.is_a? NilClass
				begin
					@datamap = YAML.load(File.open(quizfilename))
					LSMarshal.new().dumpDataCustomExtension(@datamap, quizfilenamec[0], "#{quizfilenamec[1]}dmp")
				rescue SystemCallError
					abort "Failed to initialize datamap. Exiting..."
				end
			end
			if @datamap['header'].fetch('answernumberinput', false).is_a? Boolean
				@ansnuminput = @datamap['header'].fetch('answernumberinput', false)
			else
				@ansnuminput = false
			end
			if @datamap['header'].fetch('skipisincorrect', true).is_a? Boolean
				@skipincorrect = @datamap['header'].fetch('skipisincorrect', true)
			else
				@skipincorrect = true
			end
			if @datamap['header'].fetch('quizmode', false).is_a? Boolean
				@quizmode = @datamap['header'].fetch('quizmode', false)
			else
				@ansnuminput = false
			end
		end

		def start
			if @datamap['header'].fetch('skipoverride', nil).is_a? Boolean
				if !@datamap['header'].fetch('skipoverride', nil).is_a? NilClass
					@enable_skip = @datamap['header'].fetch('skipoverride')
				end
			end
			puts "============IMPORTANT============"
			if @ansnuminput
				puts "Answer number input has been enabled for this test.\n" \
					 "Input the answer NUMBER, not the answer inself.\n"
			end
			if @skipincorrect and @enable_skip
				puts "WARNING: Skipping a question is considered incorrect."
			end
			if @quizmode
				puts "This test is in quiz mode.\n" \
					 "One incorrect answer will end the test.\n"
			end
			puts "================================="
			iters = @datamap['header']['maxquestions'].to_i
			item = 1
			iters.times do
				puts "Question ##{item}: " + @datamap['questions']["q#{item}"]['question']
				ans_item = 1
				@datamap['questions']["q#{item}"]['answers'].each do |text|
					puts "\tAnswer ##{ans_item}: #{text}"
					ans_item = ans_item + 1
				end
				loop do
					print "Answer> "
					answer = gets.chomp.to_s
					ans = 0
					ans_item = 1
					if !@ansnuminput
						@datamap['questions']["q#{item}"]['answers'].each do |text|
							if answer.downcase.inspect == text.to_s.downcase.inspect
								ans = ans_item
								break
							end
							ans_item = ans_item + 1
						end
					else
						ans = answer.to_i
					end
					rs = interpretAnswer(item, ans, answer)
					if rs
						item = item + 1
						break
					else
						redo
					end
				end
			end
			createResultDocument()
		end

		def interpretAnswer(qnmb, ansn, tans)
			cansn = @datamap['questions']["q#{qnmb}"]['correctanswer'].to_i
			@qachecksheet[:"#{qnmb}"] = {}
			@qachecksheet[:"#{qnmb}"][:canswer] = @datamap['questions']["q#{qnmb}"]['answers'][cansn - 1].to_s
			@qachecksheet[:"#{qnmb}"][:ncanswer] = cansn
			if ansn > 0 and ansn < (@datamap['questions']["q#{qnmb}"]['answers'].length + 1)
				@qachecksheet[:"#{qnmb}"][:nuanswer] = ansn
				@qachecksheet[:"#{qnmb}"][:uanswer] = @datamap['questions']["q#{qnmb}"]['answers'][ansn - 1].to_s
				if cansn == ansn
					@correct = @correct + 1
					@qachecksheet[:"#{qnmb}"][:result] = 1
				else
					@incorrect = @incorrect + 1
					@qachecksheet[:"#{qnmb}"][:result] = 0
					if @quizmode
						createResultDocument()
						exit!
					end
				end
				return true
			else
				if @enable_skip
					if tans.downcase.inspect == "skip".inspect
						if @skipincorrect
							@incorrect = @incorrect + 1
							if @quizmode
								createResultDocument()
								exit!
							end
						else
							@skipped = @skipped + 1
						end
						@qachecksheet[:"#{qnmb}"][:result] = 2
						return true
					end
				end
				puts "Please input a valid answer."
				return false
			end
		end

		def grabResults
			map = { :correct => @correct, :incorrect => @incorrect, :skipped => @skipped }
		end
	
		def createResultDocument
			map = grabResults()
			if !Dir.exist? "result"
				Dir.mkdir "result"
			end
			file = File.new(File.join("result", "result#{@name}#{@datamap['header']['name']}.txt"), "w")
			begin
				templfile = File.open(@templatef + ".rtmpl")
				templfile.readlines.each do |lin|
					@fcont = @fcont + lin
				end
				@fcont = eval("#{@fcont}")
			rescue Exception => e
				if @error_level == 0
					raise
				elsif @error_level == 1
					if !e.is_a? SystemCallError
						raise
					end
				elsif @error_level == 2
				else
					raise LSRuntimeError, "Error level is not 0, 1, or 2"
				end
				@disp = "#-#-#-#_#-#-#-#LinuxSeca Remake Results#-#-#-#_#-#-#-#\n" \
						"#-#-#-#-#-#-#-#-#-#-#-#-#--#-#-#-#-#-#-#-#-#-#-#-#-#-#\n" \
						"Test Taker Info:\n" \
						"	Name: #{@name}\n" \
						"	Age: #{@age}\n" \
						"	Quote: #{@quote}\n" \
						"Test Results:\n" \
						"	Correct: #{map[:correct]}\n" \
						"	Incorrect: #{map[:incorrect]}\n" \
						"	Test Info: #{@datamap['header']['name']} by #{@datamap['header']['author']}\n" \
						"	Test Description: #{@datamap['header']['description']}\n" \
						"	Extra: #{@datamap['header']['extra']}\n" \
						"#-#-#-#-#-#-#-#-#-#-#-#-#--#-#-#-#-#-#-#-#-#-#-#-#-#-#"
			end
			file.write(@disp)
			file.close()
			puts @disp
		end

		def to_s
			data = { 'name' => "#{self.name}", 'age' => "#{self.age}", 'quote' => "#{self.quote}" }
			"#{data.to_s}\n#{datamap}"
		end
	end
end
