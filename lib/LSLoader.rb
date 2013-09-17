$LOAD_PATH << "."
require 'lib'
require 'boolean-fix'
OPTIONS = { :yes => { :full => "yes", :short => "y" }, :no => { :full => "no", :short => "n" }}

module LinuxSecaR
	class LSLoader
		attr_accessor :lsmain
		attr_accessor :lmarshal
		def initialize
			@lsmain = nil
			@lmarshal = LSMarshal.new()
			# Attempts to load the previous session (pdata.lsydmp)
			if lmarshal.loadData("pdata").is_a? NilClass
				# Load Unsuccessful: Load for first time
				start_first_time
			else
				# Load Successful: Ask user if they want to load it
				puts "Do you wish to reload the previous session? (yes/no)"
				ans = gets.to_s.chomp.downcase
				if ans.match(OPTIONS[:yes][:full]) or ans.match(OPTIONS[:yes][:short])
					# User answers yes: Load VM and continue
					load_previous
				elsif ans.match(OPTIONS[:no][:full]) or ans.match(OPTIONS[:no][:short])
					# User answers no: Load as if first time
					start_first_time
				else
					# Application doesn't understand input
					puts "...\nI don't know how to respond."
				end
			end
		end
		
		def start_first_time
			# Try to load userdata.lsy
			ldata = @lmarshal.loadData("userdata")
			cuser = ldata['currentuser']
			if ldata.is_a? NilClass
				# Load userdata.lsy and dump it while you are at it
				ldata = @lmarshal.dumpYAMLData("userdata")
				# If ldata is still nil (userdata.lsy couldn't be found), raise LinuxSecaR::LSRuntimeError,
				if ldata.is_a? NilClass
					raise LinuxSecaR::LSRuntimeError, 'userdata.lsy is missing!'
				end
			end
			qfiles = {}
			iter = 1
			ans = 0
			# Cache the question data files and ask user which on they wish to use if there is more than 1
			Dir.glob(File.join("data", "*.lsybin")).each do |filename|
				qfiles[:"#{iter}"] = filename
				iter = iter + 1
			end
			if qfiles.length > 1
				if !ldata.fetch('selectquiztext', false).is_a? Boolean
					raise LinuxSecaR::LSRuntimeError, 'Userdata selectquiztext is set to an invalid value.'
				end
				if ldata.fetch('selectquiztext', false) == false
					puts "Which quiz file do you wish to load?"
					qfiles.each do |key, value|
						puts "Quiz ##{key}: #{value}"
					end
					1.times do
						ans = gets.to_i
						if ans == 0 or ans > qfiles.length
							puts "Please input a valid quizfile number."
							redo
						end
					end
				elsif ldata.fetch('selectquiztext', false) == true
					text = ldata.fetch('quiz', nil)
					if text.is_a? NilClass
						raise LinuxSecaR::LSRuntimeError, 'Userdata quiz is set to an invalid value.'
					end
					qfiles.each do |key, value|
						if value.inspect == text.to_s.inspect
							ans = key.to_s.to_i
							break
						end
					end
					if ans == 0
						raise LinuxSecaR::LSRuntimeError, 'Userdata quiz does not point to a valid quiz file.'
					end
				end
			else
				if qfiles.length == 0
					raise LinuxSecaR::LSRuntimeError, "No quiz files installed!"
				end
				ans = 1
			end
			# Start Quiz VM
			@lsmain = LinuxSecaR::LSRMain.new(ldata['users'][cuser]['name'], ldata['users'][cuser]['age'], ldata['users'][cuser]['quote'], qfiles[:"#{ans}"])
			# Set template file location
			@lsmain.templatef = ldata['users'][cuser].fetch("templatefile", "")
			# Get skipenabled and errorlevel data
			tempse = ldata['users'][cuser].fetch("skipenabled", false)
			if tempse.is_a? Boolean
				@lsmain.enable_skip = tempse
			else
				raise LinuxSecaR::LSRuntimeError, "Current users skipenabled tag is set to an invalid value"
			end
			tempel = ldata['users'][cuser].fetch("errorlevel", 1)
			if tempel > -1 and tempel < 3
				@lsmain.error_level = tempel
			else
				raise LinuxSecaR::LSRuntimeError, "Current users errorlevel tag is set to an invalid value"
			end
			# Dump VM (for previous session loading)
			@lmarshal.dumpData(lsmain, "pdata")
			# Start VM
			@lsmain.start()
		end
		
		def load_previous
			@lsmain = @lmarshal.loadData("pdata")
			@lsmain.start()
		end
	end
end
