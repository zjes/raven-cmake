import sys, os
import runpy
import cmake

def targetType(target):
    if type(target) == cmake.SharedLib:
        return "SHARED"
    if type(target) == cmake.Executable:
        return "EXE"
    if type(target) == cmake.Static:
        return "STATIC"
    if type(target) == cmake.Interface:
        return "INTERFACE"

def collectDependecies(target):
    private = []
    public = []

    for dep in target.dependencies:
        if (isinstance(dep, str)):
            private.append(cmake.Dependency(dep))
        else:
            if dep.public:
                public.append(dep)
            else:
                private.append(dep)

    return {
        "private": private,
        "public": public,
    }

def writeDependencies(f, dependencies):
    if dependencies["private"]:
        f.write("    USES_PRIVATE\n")
        for dep in dependencies["private"]:
            f.write("        {}\n".format(dep.targetName if dep.targetName else dep.name))
    if dependencies["public"]:
        f.write("    USES_PUBLIC\n")
        for dep in dependencies["public"]:
            f.write("        {}\n".format(dep.targetName if dep.targetName else dep.name))

def writeResolveDeps(f, dependencies):
    def write(dep):
        f.write("resolve({}".format(dep.name))
        if dep.minVersion:
            f.write(" MIN_VERSION {}".format(dep.minVersion))
        if dep.maxVersion:
            f.write(" MAX_VERSION {}".format(dep.maxVersion))
        if dep.version:
            f.write(" VERSION {}".format(dep.version))
        if dep.targetName:
            f.write(" TARGET_NAME {}".format(dep.targetName))
        f.write(")\n")

    f.write("\n# resolve dependencies\n")
    for dep in dependencies["private"]:
        write(dep)
    for dep in dependencies["public"]:
        write(dep)


if __name__ == "__main__":
    here = os.path.dirname(os.path.realpath(__file__))
    sys.path.append(here)

    targets = []
    options = cmake.CmakeOptions()

    os.targets = targets
    os.options = options

    outputPath = os.path.dirname(sys.argv[2])
    result = runpy.run_path(sys.argv[1], init_globals = {"targets": targets, "options": options, "os": os})
    f = open(sys.argv[2], "w")

    for opt in options.options:
        f.write("option({} \"\" {})\n".format(opt.name, "ON" if opt.on else "OFF"))

    for target in targets:
        f.write("#######################################################################################################################\n")
        f.write("# Target {}\n".format(target.name))
        f.write("#######################################################################################################################\n")

        type = targetType(target)
        dependencies = collectDependecies(target)

        writeResolveDeps(f, dependencies)

        f.write("\n# create target\n")
        f.write("raven_target({} {}\n".format(target.name, type))
        f.write("    SOURCES\n")
        for source in target.sources:
            f.write("        {}\n".format(source))

        writeDependencies(f, dependencies)

        if hasattr(target, 'includes'):
            f.write("    INCLUDE_DIRS\n")
            for inc in target.includes:
                f.write("        {}\n".format(inc))

        if target.definitions:
            f.write("    PREPROCESSOR\n")
            for define in target.definitions:
                if (isinstance(define, str)):
                    f.write("        {}\n".format(define))
                else:
                    if define.value:
                        f.write("        {}={}\n".format(define.name, define.value))
                    else:
                        f.write("        {}\n".format(define.name))

        flags = target.flags
        flags += cmake.warnings()
        if target.flags:
            f.write("    FLAGS\n")
            for flag in target.flags:
                f.write("        {}\n".format(flag))

        f.write(")\n")

        if target.tests:
            f.write("\n# Testing\n\n")
            f.write("raven_test_target({}\n".format(target.name))
            f.write("    SOURCES\n")
            for test in target.tests:
                f.write("        {}\n".format(test))
            f.write(")\n")
