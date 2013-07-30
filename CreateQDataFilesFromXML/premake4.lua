solution "QDataGeneratorNGUI"
	configurations { "Debug", "Release" }
	location "build"
	libdirs { "." }
	includedirs { "." }
	configuration "Debug"
		flags { "Symbols" }
		defines { "DEBUG" }

	configuration "Release"
		flags { "Optimize" }
		defines { "NDEBUG" }

	project "QDataNGUIGen"
		kind "ConsoleApp"
		language "C++"
		files { "src/**.cpp", "src/**.h", "src/*.cxx", "src/*.hxx" }
		links { "xerces-c", "yaml-cpp" }
