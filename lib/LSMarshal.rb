require 'yaml'

module LinuxSecaR
	class LSMarshal
		def dumpYAMLData(filename)
			dumpYAMLDataCustomExtension(filename, "lsy")
		end
		
		def dumpYAMLDataCustomExtension(filename, ext)
			begin
				file = File.open("#{filename}.#{ext}")
			rescue SystemCallError
				return nil
			end
		
			data = YAML.load(file)
			file.close()

			dumpData(data, filename)
			return data
		end
		
		def dumpData(data, filename)
			dumpDataCustomExtension(data, filename, "lsydmp")
		end

		def dumpDataCustomExtension(data, filename, ext)
			begin
				file = File.open("#{filename}.#{ext}", "w")
			rescue SystemCallError
				return nil
			end

			Marshal.dump(data, file)
			file.close()
			return data
		end

		def saveYAMLData(data, filename)
			saveYAMLDataCustomExtension(data, filename, "lsy")
		end

		def saveYAMLDataCustomExtension(data, filename, ext)
			begin
				file = File.open("#{filename}.#{ext}", "w")
			rescue SystemCallError
				return nil
			end

			YAML.dump(data, file)
			return data
		end

		def loadData(filename)
			loadDataCustomExtension(filename, "lsydmp")
		end

		def loadDataCustomExtension(filename, ext)
			begin
				file = File.open("#{filename}.#{ext}")
			rescue SystemCallError
				return nil
			end
		
			data = Marshal.load(file)
			file.close()
			return data
		end
	end
end
