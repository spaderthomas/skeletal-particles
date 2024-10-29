import os, platform, subprocess, tempfile, datetime, shutil, sys, distutils, enum, time, zipfile, io

# PackagedDebug will build the game and copy all scripts and assets to a new folder, just like
# in a regular packaged build -- except, it won't compile any Lua, and it'll keep hotloading
# enabled in the resulting executable. It'll also keep full debug information.
#
# Without this, it's really hard to figure out why something is wrong in a packaged build! Be
# careful: since all the scripts are still copied to a new folder, editing the *source* scripts
# won't work. You'll need to add your debugging code to the *copied* scripts, and then apply
# whatever fix back to the source.
class BuildType(enum.Enum):
    PackagedDebug = 1
    PackagedRelease = 2
    Editor = 3

class BuildDestination(enum.Enum):
    NewFolder = 1
    Steam = 2
    VisualStudio = 3

class Builder():
    def __init__(self):
        package_script_dir = os.path.realpath(os.path.dirname(__file__))
        self.project_dir = os.path.realpath(os.path.join(package_script_dir, '..'))

        self.build_type = BuildType.Editor

        if '--release' in sys.argv:
            self.build_type = BuildType.PackagedRelease
        elif '--debug_release' in sys.argv:
            self.build_type = BuildType.PackagedDebug
        elif '--editor' in sys.argv:
            self.build_type = BuildType.Editor

        self.source_dir   = os.path.join(self.project_dir, 'src')
        self.script_dir   = os.path.join(self.source_dir, 'scripts')
        self.lib_dir      = os.path.join(self.project_dir, 'lib', self.get_lib_subdir())
        self.build_dir    = os.path.join(self.project_dir, 'build', 'windows')
        self.asset_dir    = os.path.join(self.project_dir, 'asset')
        self.atlas_dir    = os.path.join(self.asset_dir, 'images', 'atlas')
        self.audio_dir    = os.path.join(self.asset_dir, 'audio')
        self.font_dir     = os.path.join(self.asset_dir, 'fonts')
        self.shader_dir   = os.path.join(self.asset_dir, 'shaders')
        self.build_file   = os.path.join(self.build_dir, 'DeepCopy.sln')
        self.bytecode_dir = os.path.join(self.build_dir, 'bytecode')

        self.executable_filename = 'deepcopy.exe'

        if self.build_type == BuildType.PackagedRelease:
            self.build_destination = BuildDestination.Steam
            self.demo_folder = os.path.join(self.project_dir, 'build', 'steam')
            self.is_steam = True
        if self.build_type == BuildType.PackagedDebug:
            self.build_destination = BuildDestination.Steam
            self.demo_folder = os.path.join(self.project_dir, 'build', 'steam')
            self.is_steam = True
        if self.build_type == BuildType.Editor:
            self.build_destination = BuildDestination.VisualStudio
            
        if '--standalone' in sys.argv:
            self.build_destination = BuildDestination.NewFolder
            time = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
            self.demo_folder = os.path.join(self.project_dir, 'deepcopy_{0}'.format(time))
            self.is_steam = False

        if '--package-crt' in sys.argv:
            self.package_crt = True
        else:
            self.package_crt = False
            
    def build_type_id(self):
        if self.build_type == BuildType.PackagedDebug:
            return 'PackagedDebug'
        elif self.build_type == BuildType.PackagedRelease:
            return 'PackagedRelease'
        elif self.build_type == BuildType.Editor:
            return 'Editor'

    def get_lib_subdir(self):
        if self.build_type == BuildType.PackagedDebug:
            return 'debug'
        elif self.build_type == BuildType.Editor:
            return 'debug'
        elif self.build_type == BuildType.PackagedRelease:
            return 'release'

    def executable_path(self):
        return os.path.join(self.build_dir, 'x64', self.build_type_id(), self.executable_filename)
            
    def build_command(self):
        return ['msbuild', self.build_file, f'/p:Configuration={self.build_type_id()}']
        

builder = Builder()

def _build_executable():
    subprocess.run(builder.build_command())

def _build_lua():
    print('Building Lua scripts...')
    
    # Make directory for all these object files
    if os.path.exists(builder.bytecode_dir):
        shutil.rmtree(builder.bytecode_dir)

    if builder.build_type == BuildType.PackagedDebug:
        shutil.copytree(builder.script_dir, os.path.join(builder.bytecode_dir, 'scripts'))
    else:
        _build_bytecode()
        
    excluded_dirs = [
        os.path.join('scripts', 'data', 'boonbane')
    ]
    for excluded_dir in excluded_dirs:
        absolute_dir = os.path.join(builder.bytecode_dir, excluded_dir)
        print(f'Excluding path from bytecode: {absolute_dir}')
        if os.path.exists(absolute_dir):
            shutil.rmtree(absolute_dir)

def _build_bytecode():
    # LuaJIT needs its JIT modules in the path. Instead of wrangling that, just work out of the
    # directory that has them
    luajit_dir = _get_luajit_dir()
    os.chdir(luajit_dir)
    
    # Build the object files
    for root, dirs, files in os.walk(builder.script_dir):
        for name in files:
            # Make sure the file is actually a Lua script, and change it to luac
            script_name = name.split('.')[0]
            script_ext = name.split('.')[1]
            if script_ext != 'lua':
                continue
            
            script = os.path.join(root, name)
            bytecode_file = script_name  + '.lua'

            # We want to put the compiled Lua files in the same directory structure as the
            # source files, so that we modify as little as possible between debug builds
            # and release builds
            #
            # Build the path to the bytecode file, relative to the build directory
            # e.g. build/bytecode/src/scripts/core/bootstrap.luac
            bytecode_destination = os.path.relpath(root, bytecode_file)
            bytecode_destination = bytecode_destination.split(os.sep)
            bytecode_destination = [d for d in bytecode_destination if d != '..' and d != 'src']
            bytecode_destination = os.sep.join(bytecode_destination)
            bytecode_destination = os.path.join(builder.bytecode_dir, bytecode_destination) 

            # Make sure this directory exists
            try:
                os.makedirs(bytecode_destination)
            except:
                pass

            # Compile the bytecode
            #
            # LuaJIT is very particular about exact version matches when it comes to compiling
            # bytecode and then decompiling it. 2.1.0-beta3 and the latest commit off of master
            # (still under 2.1.0, albeit a couple hundred commits in between) are not
            # compatible. Ergo, the executable we use to compile bytecode has to be EXACTLY
            # the same as the LuaJIT library we link into the game.
            #
            # I compiled it and put it in the build folder. It's cut from the 2.1.0-beta3 release,
            # or commit 8271c643c21d1b2f344e339f559f2de6f3663191.
            lj = os.path.join(luajit_dir, 'luajit-2.1.0-beta3')
            lj_compile = [lj, '-b', '$lua_file', '$bytecode_file']
            lj_compile[2] = script
            lj_compile[3] = os.path.join(builder.bytecode_dir, bytecode_file)
            subprocess.run(lj_compile)

            # Copy the bytecode
            bytecode_destination = os.path.join(bytecode_destination, bytecode_file)
            shutil.move(os.path.join(builder.bytecode_dir, bytecode_file), bytecode_destination)

def _get_project_dir():
    package_script_dir = os.path.realpath(os.path.dirname(__file__))
    return os.path.realpath(os.path.join(package_script_dir, '..'))

def _get_build_tools_dir():
    return os.path.join(_get_project_dir(), 'build', 'windows')

def _get_luajit_dir():
    return _get_build_tools_dir()

def _setup_demo_folder():
    os.makedirs(builder.demo_folder, exist_ok=True)
    
    for file_name in os.listdir(builder.demo_folder):
        file_path = os.path.join(builder.demo_folder, file_name)
        if os.path.isfile(file_path) or os.path.islink(file_path):
            os.unlink(file_path)
        elif os.path.isdir(file_path):
            shutil.rmtree(file_path)

def _copy_everything():
    _copy_executable()
    _copy_lua()
    _copy_assets()
    _copy_steam()
    
def _copy_executable():
    shutil.copy(builder.executable_path(), builder.demo_folder)

def _copy_lua():
    shutil.copytree(builder.bytecode_dir, builder.demo_folder, dirs_exist_ok=True)
        
def _copy_assets():
    shutil.copytree(builder.asset_dir, os.path.join(builder.demo_folder, 'asset'))

def _copy_steam():
    # Even if we're not making a Steam build, we still link to the Steam DLL. It's just easier to do it this
    # way than to have a separate configuration just for Steam; keep build surface minimal
    steam_api = 'steam_api64.dll'
    shutil.copyfile(os.path.join(builder.lib_dir, steam_api), os.path.join(builder.demo_folder, steam_api))

    steam_appid = 'steam_appid.txt'
    shutil.copyfile(os.path.join(builder.asset_dir, 'steam', steam_appid), os.path.join(builder.demo_folder, steam_appid))

def cloc():
    # Cloc doesn't like Windows path separators, even on Windows
    exclude = [
        'src/imgui',
        'scripts/engine/data',
        'scripts/engine/libs',
        'scripts/user/data',
    ]
    not_match_d = '|'.join(exclude)

    exclude_files = [
        'scripts/engine/core/cimgui.lua',
        'scripts/engine/data/cimgui.lua',
    ]
    exclude_files = '|'.join(exclude_files)
    command = ['cloc', '--fullpath', f'--not-match-d="{not_match_d}"', f'--not-match-f="{exclude_files}"', 'PATH']
    
    command[-1] = '../src'
    subprocess.run(' '.join(command))

    command[-1] = '../scripts'
    subprocess.run(' '.join(command))


if __name__ == '__main__':
    if '--cloc' in sys.argv:
        cloc()
        exit()

    if builder.build_type == BuildType.Editor:
        _build_executable()
        exit()
        
    #build_binary_assets()
    _build_executable()
    _build_lua()
    _setup_demo_folder()
    _copy_everything()
    print(f'Finished building for {builder.build_type_id()}')
