OPTIONS = { :yes => "y", :no => "n" }

dfiles = Dir.glob(File.join("**", "*.*dmp"))
dfiles.each do |file|
	puts "Do you want to delete #{file}? (y/n)?"
	ans = gets.chomp.to_s.downcase
	if ans.match(OPTIONS[:yes])
		File.delete(file)
		puts "Deleted #{file}."
	elsif ans.match(OPTIONS[:no])
		puts "Skipping #{file}."
	else
		puts "Please input (at least) y or n."
		redo
	end
end
