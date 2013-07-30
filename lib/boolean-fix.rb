# A small fix to add a kind of "Boolean" type to Ruby
module Boolean
end

class TrueClass
	include Boolean
end

class FalseClass
	include Boolean
end
