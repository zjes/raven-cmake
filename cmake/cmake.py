import os, sys

############################################################################################################################################

class Config:
    buildType = ""
    compiler = ""
    sourceDir = ""
    binaryDir = ""
    buildTesting = False
    variables = {}

    def check(name, value):
        return name in Config.variables and Config.variables[name] == value

    def isLinux():
        return Config.check("UNIX", "1") and not Config.check("APPLE", "1")

    def isWindows():
        return Config.check("MSVC", "1") or Config.check("MSYS", "1") or Config.check("MINGW", "1")

    def isApple():
        return Config.check("APPLE", "1")

    def isGcc():
        return Config.check("CMAKE_CXX_COMPILER_ID", "GNU")

    def isClang():
        return Config.check("CMAKE_CXX_COMPILER_ID", "Clang")

    def isMsvc():
        return Config.check("CMAKE_CXX_COMPILER_ID", "MSVC")

############################################################################################################################################

class Private(object):
    def __init__(self, name):
        self.name = name

class Public(object):
    def __init__(self, name):
        self.name = name

class Dependency(object):
    def __init__(self, name, public = False, minVersion = "", maxVersion = "", version = "", targetName = ""):
        self.name = name
        self.public = public
        self.minVersion = minVersion
        self.maxVersion = maxVersion
        self.version = version
        self.targetName = targetName

class Dependencies(list):
    def __init__(self):
        pass

    def append(self, name, minVersion = ""):
        super().append(Dependency(name, minVersion=minVersion))

class Target:
    def __init__(self, name, sources = [], dependencies = [], options = [], flags = []):
        self.name = name
        self.sources = sources
        self.dependencies = Dependencies()
        self.dependencies.extend(dependencies)
        self.options = options
        self.definitions = []
        self.flags = flags
        os.targets.append(self)
        self.warnings = warnings()
        self.tests = None

    def addTest(self, sources = []):
        self.tests = sources;

    def setIncludes(self, includes):
        self.includes = includes

class SharedLib(Target):
    pass

class Executable(Target):
    pass

class Static(Target):
    pass

class Interface(Target):
    pass

############################################################################################################################################

class OptionBase:
    def __init__(self, name, on):
        self.name = name
        self.on = on

class Option(OptionBase):
    class Qt:
        def AutoMoc(on):
            return OptionBase("AUTOMOC", on)
        def AutoRcc(on):
            return OptionBase("AUTORCC", on)
        def AutoUic(on):
            return OptionBase("AUTOUIC", on)

    def Include(dir):
        return OptionBase("INCLUDE_DIR", dir)

    def __init__(self, name, on):
        super().__init__(name, on)
        os.options.append(self)

    def isSet(self):
        return Config.check(self.name, "ON")

class Definition:
    def __init__(self, name, value = ""):
        self.name = name
        self.value = value

    class Qt:
        def NoCastFromAscii():
            return Definition("QT_NO_CAST_FROM_ASCII")
        def NoCastToAscii():
            return Definition("QT_NO_CAST_TO_ASCII")

############################################################################################################################################

class CmakeOptions:
    def __init__(self):
        self.options = []

    def append(self, option):
        self.options.append(option)

    def check(self, name):
        return Config.check(name, "ON")

############################################################################################################################################

def collectConfig(path):
    with open(os.path.join(path, "raven-cmake.vars")) as conf:
        for line in conf.readlines():
            pos = line.find("=")
            name = line[:pos]
            value = line[pos+1:]
            if name == "CMAKE_BUILD_TYPE":
                Config.buildType = value.strip()
            elif name == "CMAKE_CXX_COMPILER":
                Config.compiler = value.strip()
            elif name == "CMAKE_CURRENT_SOURCE_DIR":
                Config.sourceDir = value.strip()
            elif name == "CMAKE_CURRENT_BINARY_DIR":
                Config.binaryDir = value.strip()
            elif name == "BUILD_TESTING":
                Config.buildTesting = value.strip() == "ON"
            else:
                Config.variables[name] = value.strip()

collectConfig(os.path.dirname(sys.argv[2]))

def warnings():
    if (Config.isClang()):
        return [
            "-Wall",
            "-Wextra",
            "-Weverything",
            "-Wno-c++98-compat",
            "-Wno-c++98-compat-pedantic",
            "-Wno-padded",
            "-Wno-exit-time-destructors",
            #"-Wno-weak-vtables",
            "-Wno-gnu-zero-variadic-macro-arguments",
            "-Wno-unused-macros",
            "-Wno-global-constructors",
            "-Wno-unused-local-typedef",
            "-Wno-reserved-identifier",
            "-Wno-switch-default",
            "-Wno-unsafe-buffer-usage",
            "-Wno-unused-member-function"
        ]
    if (Config.isGcc()):
        return [
            "-Wall",
            "-Wextra", # reasonable and standard
            "-Wshadow", # warn the user if a variable declaration shadows one from a parent context
            "-Wnon-virtual-dtor", # warn the user if a class with virtual functions has a non-virtual destructor. This helps catch hard to track down memory errors
            "-Wold-style-cast", # warn for c-style casts
            "-Wcast-align", # warn for potential performance problem casts
            "-Wunused", # warn on anything being unused
            "-Woverloaded-virtual", # warn if you overload (not override) a virtual function
            "-Wpedantic", # warn if non-standard C++ is used
            "-Wconversion", # warn on type conversions that may lose data
            "-Wsign-conversion", # warn on sign conversions
            "-Wdouble-promotion", # warn if float is implicit promoted to double
            "-Wformat=2", # warn on security issues around functions that format output (ie printf)
            "-Wno-redundant-move",
            "-Wno-unused-local-typedef",
        ]
