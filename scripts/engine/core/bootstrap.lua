local ffi_header = [[
//
// TYPES
//
typedef uint32_t u32;
typedef int32_t  i32;
typedef float f32;
typedef double f64;

typedef struct {
    char* data;
} tstring;

typedef struct {
    char* data;
} string;

typedef struct {
	float x;
	float y;
} Vector2;

typedef struct {
	float x;
	float y;
	float z;
	float w;
} Vector4;

typedef struct {
	u32 index;
	u32 generation;
} ArenaHandle;


void set_gl_name(u32 kind, u32 handle, u32 name_len, const char* name);

void IGE_PushGameFont(const char* font_name);
void IGE_GameImage(const char* image, float sx, float sy);
void IGE_OpenFileBrowser();
void IGE_CloseFileBrowser();
void IGE_SetFileBrowserWorkDir(const char* directory);
bool IGE_IsAnyFileSelected();
tstring IGE_GetSelectedFile();

//
// AUDIO
//
typedef struct {
  i32 index;
  i32 generation;
} ActiveSoundHandle;

ActiveSoundHandle play_sound(const char* name);
ActiveSoundHandle play_sound_loop(const char* name);
void stop_all_sounds();
void stop_sound(ActiveSoundHandle handle);
void pause_sound(ActiveSoundHandle handle);
void unpause_sound(ActiveSoundHandle handle);
bool is_sound_playing(ActiveSoundHandle handle);
void play_sound_after(ActiveSoundHandle current, ActiveSoundHandle next);

void set_volume(ActiveSoundHandle handle, float volume);
void set_cutoff(ActiveSoundHandle handle, float cutoff);

float get_master_cutoff();
float get_master_volume();
float get_master_volume_mod();
void set_threshold(float t);
void set_ratio(float v);
void set_attack_time(float v);
void set_release_time(float v);
void set_sample_rate(float v);
void set_master_volume(float v);
void set_master_cutoff(float v);
void set_butterworth(bool v);
void set_master_volume_mod(float v);

void set_window_size(int x, int y);


//
// INPUT
//
bool is_editor_requesting_input();
bool was_key_pressed(int key);
bool was_key_released(int key);
bool is_key_down(int key);
bool is_mod_down(int mod);
bool was_chord_pressed(int mod, int key);
u32 shift_key(u32 key);
Vector2 get_scroll();
Vector2 get_mouse_delta();
Vector2 get_mouse_delta_converted(u32 coordinate);
void set_game_focus(bool focus);

void show_text_input(const char* description, const char* existing_text);
bool is_text_input_dirty();
const char* read_text_input();


//
// TEXT
//
typedef struct {
    char text [1024];
	Vector2 position;
	Vector2 padding;
    Vector4 color;
	void* font;
	float wrap;
	float offset;
	bool world_space;

	int breaks [32];
	float width;
	float height;
	float baseline_offset;
	float baseline_offset_imprecise;
	float height_imprecise;
	bool precise;
} PreparedText;

PreparedText* prepare_text(const char* text, f32 px, f32 py, const char* font);
PreparedText* prepare_text_wrap(const char* text, f32 px, f32 py, const char* font, f32 wrap);
PreparedText* prepare_text_ex(const char* text, f32 px, f32 py, const char* font, f32 wrap, Vector4 color, bool precise);
void draw_prepared_text(PreparedText* text);

void create_font(const char* id, const char* family, u32 size);
void add_imgui_font(const char* id);


//
// ENGINE
//
void set_exit_game();
const char* get_game_hash();
void set_target_fps(f64 fps);
f64 get_target_fps();

void tm_add(const char* name);
void tm_begin(const char* name);
void tm_end(const char* name);
double tm_average(const char* name);
double tm_last(const char* name);
double tm_largest(const char* name);
double tm_smallest(const char* name);

void submit_feedback(const char* feedback);
void submit_analytics(const char* analytics);
void submit_crash(const char* crash);
void submit_image(const char* file_path);
void open_steam_page(const char* utm);
bool is_steam_deck();
void take_screenshot();
void write_screenshot_to_png(const char* file_name);

typedef struct {
    const char* name;
    const char* path;
} NamedPath;

typedef struct {
	NamedPath* named_paths;
	u32 size;
} NamedPathResult;

NamedPathResult find_all_named_paths();

void add_install_path(const char* name, const char* relative_path);
void add_write_path(const char* name, const char* relative_path);
tstring resolve_named_path(const char* name);
tstring resolve_format_path(const char* name, const char* file_name);

void add_script_directory(const char* name);

//
// WINDOW
//
typedef enum {
	DisplayMode_p480,
	DisplayMode_p720,
	DisplayMode_p1080,
	DisplayMode_p1440,
	DisplayMode_p2160,
	DisplayMode_p1280_800,
	DisplayMode_FullScreen
} DisplayMode;

typedef enum {
	CoordinateSystem_Screen,
	CoordinateSystem_Window,
	CoordinateSystem_Game,
	CoordinateSystem_World,
} CoordinateSystem;

void create_window(const char* title, u32 x, u32 y, u32 flags);
void set_window_icon(const char* file_path);
Vector2 get_content_area();
Vector2 get_game_area_size();
Vector2 get_native_resolution();
void set_game_area_size(f32 x, f32 y);
void set_game_area_position(f32 x, f32 y);
void set_display_mode(u32 mode);
u32 get_display_mode();
void hide_cursor();
void show_cursor();
void use_editor_layout(const char* file_name);
void save_editor_layout(const char* file_name);
void render_imgui();


//
// GPU
//
typedef enum {
    VertexAttributeKind_Float,
};

typedef enum {
    DrawMode_Triangles,
};

typedef enum {
    GlId_Framebuffer,
    GlId_Shader,
    GlId_Program,
};

typedef enum {
	GpuMemoryBarrier_ShaderStorage,
};


typedef struct {
	u32 handle;
	u32 color_buffer;
	Vector2 size;
} GpuRenderTarget;

typedef struct {
	u32 count;
	u32 kind;
} VertexAttribute;

typedef struct {
	VertexAttribute* vertex_attributes;
	u32 num_vertex_attributes;
    u32 max_vertices;
    u32 max_draw_calls;
} GpuCommandBufferDescriptor;

typedef void* GpuCommandBuffer;
typedef void* GpuBuffer;


typedef struct {
	GpuRenderTarget* target;
	GpuRenderTarget* ping_pong;
	
	bool clear_render_target;
} GpuRenderPassDescriptor;

typedef struct {
	GpuRenderTarget* render_target;
	GpuRenderTarget* ping_pong;

	bool clear_render_target;
  bool dirty;
} GpuRenderPass;





GpuRenderTarget*  gpu_create_target(float x, float y);
GpuRenderTarget*  gpu_acquire_swapchain();
void              gpu_bind_target(GpuRenderTarget* target);
void              gpu_clear_target(GpuRenderTarget* target);
void              gpu_blit_target(GpuCommandBuffer* command_buffer, GpuRenderTarget* source, GpuRenderTarget* destination);
void              gpu_swap_buffers();
GpuCommandBuffer* gpu_create_command_buffer(GpuCommandBufferDescriptor descriptor);
GpuRenderPass*    gpu_create_pass(GpuRenderPassDescriptor descriptor);
void              gpu_begin_pass(GpuRenderPass* render_pass, GpuCommandBuffer* command_buffer);
void              gpu_end_pass();
void              gpu_submit_commands(GpuCommandBuffer* command_buffer);
GpuBuffer*        gpu_create_buffer();
void              gpu_memory_barrier(u32 barrier);
void              gpu_bind_buffer(GpuBuffer* buffer);
void              gpu_bind_buffer_base(GpuBuffer* buffer, u32 base);
void              gpu_sync_buffer(GpuBuffer* buffer, void* data, u32 size);
void              gpu_zero_buffer(GpuBuffer* buffer, u32 size);
void              gpu_dispatch_compute(GpuBuffer* buffer, u32 size);

void set_active_shader(const char* name);
void set_draw_mode(u32 mode);
void set_orthographic_projection(float left, float right, float bottom, float top, float _near, float _far);

void set_uniform_texture(const char* name, i32 value);
void set_uniform_i32(const char* name, i32 value);
void set_uniform_f32(const char* name, float value);
void set_uniform_vec2(const char* name, Vector2 value);

void set_uniform_immediate_vec2(const char* name, Vector2 value);
void set_uniform_immediate_i32(const char* name, i32 value);
void set_uniform_immediate_f32(const char* name, float value);
void set_uniform_immediate_texture(const char* name, i32 value);

void push_quad(float px, float py, float dx, float dy, Vector2* uv, float opacity);

//
// DRAW
//
typedef enum {
	ZERO,
	ONE,
	SRC_COLOR,
	ONE_MINUS_SRC_COLOR,
	DST_COLOR,
	ONE_MINUS_DST_COLOR,
	SRC_ALPHA,
	ONE_MINUS_SRC_ALPHA,
	DST_ALPHA,
	ONE_MINUS_DST_ALPHA,
	CONSTANT_COLOR,
	ONE_MINUS_CONSTANT_COLOR,
	CONSTANT_ALPHA,
	ONE_MINUS_CONSTANT_ALPHA,
	SRC_ALPHA_SATURATE,
	SRC1_COLOR,
	ONE_MINUS_SRC1_COLOR,
	SRC1_ALPHA,
	ONE_MINUS_SRC1_ALPHA
} BlendMode;

void begin_scissor(f32 px, f32 py, f32 dx, f32 dy);
void end_scissor();
void begin_world_space();
void end_world_space();
void set_world_space(bool world_space);
void set_layer(i32 layer);
void set_camera(f32 px, f32 py);
void set_blend_enabled(bool enabled);
void set_blend_mode(i32 source, i32 destination);

void draw_quad(Vector2 position, Vector2 size, Vector4 color);
void draw_line(Vector2 start, Vector2 end, f32 thickness, Vector4 color);
void draw_circle(f32 px, f32 py, f32 radius, Vector4 color);
void draw_circle_sdf(f32 px, f32 py, f32 radius, Vector4 color, f32 edge_thickness);
void draw_ring_sdf(f32 px, f32 py, f32 inner_radius, f32 radius, Vector4 color, f32 edge_thickness);
void draw_image(const char* name, f32 px, f32 py);
void draw_image_size(const char* name, f32 px, f32 py, f32 dx, f32 dy);
void draw_image_ex(const char* name, float px, float py, float dx, float dy, float opacity);
void draw_image_pro(u32 texture, f32 px, f32 py, f32 dx, f32 dy, Vector2* uv, f32 opacity);
void draw_text(const char* text, f32 px, f32 py);
void draw_text_ex(const char* text, f32 px, f32 py, Vector4 color, const char* font, f32 wrap);

u32 find_texture_handle(const char* name);

//
// OS
//
bool does_path_exist(const char* path);
bool is_regular_file(const char* path);
bool is_directory(const char* path);
void create_directory(const char* path);
void remove_directory(const char* path);
void create_named_directory(const char* name);

typedef struct DateTime {
	int year;
	int month;
	int day;
	int hour;
	int minute;
	int second;
	int millisecond;
} DateTime;

DateTime get_date_time();

typedef struct {} MemoryAllocator;

void ma_add(const char* name, MemoryAllocator* allocator);
MemoryAllocator* ma_find(const char* name);
void* ma_alloc(MemoryAllocator* allocator, u32 size);
void ma_free(MemoryAllocator* allocator, void* buffer);

void copy_string(const char* str, char* buffer, u32 buffer_length);
void copy_string_n(const char* str, u32 length, char* buffer, u32 buffer_length);



//
// ACTIONS
//
void register_action(const char* name, u32 key, u32 key_event, const char* action_set);
void register_action_set(const char* name);
void activate_action_set(const char* name);
bool is_digital_active(const char* name);
bool was_digital_active(const char* name);
bool was_digital_pressed(const char* name);
i32 get_input_device();
i32 get_action_set_cooldown();
const char* get_active_action_set();

enum {
	KeyAction_Press = 0,
	KeyAction_Down = 1
};


//
// INTERPOLATION
//
typedef enum {
	InterpolationFn_Linear,
	InterpolationFn_SmoothDamp
} InterpolationFn;


//
// PARTICLES
//
typedef enum {
	ParticleKind_Quad,
	ParticleKind_Circle,
	ParticleKind_Image,
	ParticleKind_Invalid,
} ParticleKind;

typedef enum {
	ParticlePositionMode_Bottom,
} ParticlePositionMode;

typedef struct {
	i32 index;
	i32 generation;
} ParticleSystemHandle;

typedef struct {
	int spawned;
	int despawned;
	int alive;
} ParticleSystemFrame;

ParticleSystemHandle make_particle_system();
void free_particle_system(ParticleSystemHandle system);
ParticleSystemFrame check_particle_system(ParticleSystemHandle handle);
void stop_particle_emission(ParticleSystemHandle handle);
void start_particle_emission(ParticleSystemHandle handle);
void clear_particles(ParticleSystemHandle handle);
void update_particles(ParticleSystemHandle handle);
void draw_particles(ParticleSystemHandle handle);
void stop_all_particles();

void set_particle_lifetime(ParticleSystemHandle system, float lifetime);
void set_particle_max_spawn(ParticleSystemHandle handle, int max_spawn);
void set_particle_spawn_rate(ParticleSystemHandle handle, float spawn_rate);
void set_particle_size(ParticleSystemHandle handle, float x, float y);
void set_particle_radius(ParticleSystemHandle handle, float r);
void set_particle_sprite(ParticleSystemHandle handle, const char* sprite);
void set_particle_position_mode(ParticleSystemHandle handle, ParticlePositionMode mode);
void set_particle_position(ParticleSystemHandle handle, float x, float y);
void set_particle_area(ParticleSystemHandle handle, float x, float y);
void set_particle_kind(ParticleSystemHandle handle, ParticleKind kind);
void set_particle_color(ParticleSystemHandle handle, float r, float g, float b, float a);
void set_particle_layer(ParticleSystemHandle system, int layer);
void set_particle_velocity_fn(ParticleSystemHandle handle, InterpolationFn function);
void set_particle_velocity_base(ParticleSystemHandle handle, float x, float y);
void set_particle_velocity_max(ParticleSystemHandle handle, float x, float y);
void set_particle_velocity_jitter(ParticleSystemHandle handle, float x, float y);
void set_particle_jitter_base_velocity(ParticleSystemHandle system, bool jitter);
void set_particle_jitter_max_velocity(ParticleSystemHandle system, bool jitter);
void set_particle_size_jitter(ParticleSystemHandle handle, float jitter);
void set_particle_jitter_size(ParticleSystemHandle handle, bool jitter);
void set_particle_opacity_jitter(ParticleSystemHandle handle, float jitter);
void set_particle_jitter_opacity(ParticleSystemHandle handle, bool jitter);
void set_particle_opacity_interpolation(ParticleSystemHandle handle, bool active, float start_time, float interpolate_to);
void set_particle_warm(ParticleSystemHandle system, bool warm);
void set_particle_warmup(ParticleSystemHandle system, i32 warmup);
void set_particle_gravity_source(ParticleSystemHandle handle, float x, float y);
void set_particle_gravity_intensity(ParticleSystemHandle handle, float intensity);
void set_particle_gravity_enabled(ParticleSystemHandle handle, bool enabled);
void set_particle_master_opacity(ParticleSystemHandle handle, float opacity);

//
// MATH
//
f64 perlin(f64 x, f64 y, f64 vmin, f64 vmax);



//
// FLUID
//
	typedef struct {
		u32 next_unprocessed_index;
		u32 grid_size;
	} EulerianFluidSystem;

ArenaHandle lf_create(u32 num_particles);
void lf_destroy(ArenaHandle handle);
void lf_destroy_all();
void lf_init(ArenaHandle handle);
void lf_inspect(ArenaHandle handle);
void lf_set_volume(ArenaHandle handle, float ax, float ay, float bx, float by, float radius);
void lf_set_velocity(ArenaHandle handle, float x, float y);
void lf_set_smoothing_radius(ArenaHandle handle, float r);
void lf_set_particle_mass(ArenaHandle handle, float mass);
void lf_set_viscosity(ArenaHandle handle, float viscosity);
void lf_set_pressure(ArenaHandle handle, float pressure);
void lf_set_gravity(ArenaHandle handle, float gravity);
void lf_set_timestep(ArenaHandle handle, float dt);
void lf_bind(ArenaHandle handle);
void lf_update(ArenaHandle handle);
void lf_draw(ArenaHandle handle);

ArenaHandle ef_create(u32 grid_size);
void ef_destroy(ArenaHandle handle);
void ef_destroy_all();
void ef_init(ArenaHandle handle);
void ef_inspect(ArenaHandle handle);
u32 ef_pair_to_index(u32 grid_size, u32 x, u32 y);
void ef_set_render_size(ArenaHandle handle, u32 size);
void ef_set_velocity(ArenaHandle handle, u32 x, u32 y, float vx, float vy);
void ef_clear_density_source(ArenaHandle handle);
void ef_set_density_source(ArenaHandle handle, u32 x, u32 y, float amount);
void ef_set_gauss_seidel(ArenaHandle handle, u32 iterations);
void ef_bind(ArenaHandle handle);
void ef_update(ArenaHandle handle);
void ef_draw(ArenaHandle handle);
]]

ffi = require('ffi')

function tdengine.handle_error(message)
  -- Strip the message's filename the script filename to make it more readable
  local parts = split(message, ' ')
  local path = parts[1]
  local path_elements = split(path, '/')
  local filename = path_elements[#path_elements]

  local message = filename
  for index = 2, #parts do
    message = message .. ' ' .. parts[index]
  end

  local stack_trace = debug.traceback()
  stack_trace = stack_trace:gsub('stack traceback:\n', '')
  stack_trace = stack_trace:gsub('\t', '	')

  -- The stack trace contains absolute paths, which are just hard to read. Also, if the path is long, it is
  -- shortened with "...". Remove the absolute part of the path, including the "..."
  local install_dir = tdengine.ffi.resolve_named_path('install'):to_interned()
  local escaped_install = install_dir:gsub('%.', '%%.')
  local last_path_element = install_dir:match("([^/]+)$")
  local pattern = '%.%.%.(.*)/' .. last_path_element

  -- Replace the full path first
  stack_trace = stack_trace:gsub(escaped_install, '')

  -- Then replace any possible shortened versions with ...
  local shortened_path_pattern = '[^%.]+%.[^%.]+%.[^%.]+%.[^%.]+%.[^%.]+'
  stack_trace = stack_trace:gsub(pattern, '')

  -- Print
  local error_message = string.format('lua runtime error:\n\t%s', message)
  local trace_message = string.format('stack trace:\n%s', stack_trace)

  tdengine.debug.last_error = error_message
  tdengine.debug.last_trace = trace_message

  tdengine.log(error_message)
  tdengine.log(trace_message)

  tdengine.debug.open_debugger(1)
  --tdengine.analytics.submit_crash(error_message, trace_message)
  tdengine.ffi.render_imgui()

  return
end

function tdengine.init_phase_0()
  tdengine.types = {}
  tdengine.class = {}
  tdengine.lifecycle = {}

  tdengine.entity = {}
  tdengine.entity.entities = {}
  tdengine.entity.created_entities = {}
  tdengine.entity.destroyed_entities = {}
  tdengine.entity.persistent_entities = {}
  tdengine.entity.types = {}
  tdengine.entity.next_id = 1
  tdengine.persistent = {}

  tdengine.component = {}
  tdengine.component.types = {}

  tdengine.internal = {}
  tdengine.internal.enum_metatable = {}

  tdengine.debug = {}

  tdengine.constants = {}
  tdengine.enum = {}
  tdengine.enums = {}
  tdengine.enum_data = {}

  tdengine.editor = {}
  tdengine.editor.types = {}
  tdengine.editor.sentinel = '__editor'

  tdengine.save = {}

  tdengine.state = {}
  tdengine.state.data = {}

  tdengine.path_constants = {}

  tdengine.quests = {}

  tdengine.scene = {}
  tdengine.scene.save_data = {}
  tdengine.current_scene = nil
  tdengine.queued_scene = nil

  tdengine.callback = {}
  tdengine.callback.data = {}

  tdengine.data_types = {}

  tdengine.dialogue = {}
  tdengine.dialogue.node_type = {}
  tdengine.dialogue.node_kind = {}
  tdengine.dialogue.sorted_node_kinds = {}
  tdengine.dialogue.metrics = {
    words = 0,
    nodes = 0,
    dialogues = {}
  }
  tdengine.dialogue.cache = {}
  tdengine.dialogue.characters = {}

  tdengine.audio = {}

  tdengine.animation = {}
  tdengine.animation.data = {}

  tdengine.texture = {}
  tdengine.texture.data = {}

  tdengine.background = {}
  tdengine.background.data = {}

  tdengine.input = {}
  tdengine.input.data = {}

  tdengine.physics = {}
  tdengine.physics.requests = {}
  tdengine.physics.debug = false

  tdengine.interaction = {}
  tdengine.interaction.callbacks = {}
  tdengine.interaction.check_flag = false

  tdengine.interpolation = {}

  tdengine.gui = {}
  tdengine.gui.animation = {}
  tdengine.gui.scroll = {}
  tdengine.gui.drag = {}
  tdengine.gui.menu = {}

  tdengine.steam = {}

  tdengine.window = {}

  tdengine.action = {}
  tdengine.action.event_kind = {}

  tdengine.analytics = {}

  tdengine.fonts = {}

  tdengine.module = {}

  tdengine.paths = {}

  tdengine.shaders = {}

  tdengine.gpu = {}

  tdengine.app = {}

  tdengine.iterator = {}

  tdengine.time_metric = {}

  tdengine.subsystem = {}
  tdengine.subsystem.types = {}

  tdengine.dt = 0
  tdengine.elapsed_time = 0
  tdengine.frame = 0

  tdengine.tick = tdengine.is_packaged_build
  tdengine.next_tick = tdengine.tick

  imgui = {}
  imgui.extensions = {}
  imgui.internal = {}

  -- Bootstrap the FFI, so that we can resolve paths
  tdengine.ffi = {}
  ffi.cdef(ffi_header)

  -- Bootstrap the engine paths, so we can load the rest of the scripts
  local function collect_paths(paths, full_parent)
    full_parent = full_parent or ''

    local collected_paths = {}
    for name, data in pairs(paths) do
      local full_path = ''
      if type(data) == 'string' then
        full_path = full_parent .. data
        goto done
      else 
        full_path = full_parent .. data.path
      end
  
      if data.children then
        local child_paths = collect_paths(data.children, full_path .. '/')
        for index, path in pairs(child_paths) do
          table.insert(collected_paths, path)
        end
      end

      ::done::
      table.insert(collected_paths, {
        name = name,
        path = full_path
      })
    end
  
    return collected_paths
  end
  
  local file_path = ffi.string(ffi.C.resolve_named_path('engine_paths').data)
	local path_info = dofile(file_path)

	local install_paths = collect_paths(path_info.install_paths)
	for index, path in pairs(install_paths) do
		ffi.C.add_install_path(path.name, path.path)
	end

	local write_paths = collect_paths(path_info.write_paths)
	for index, path in pairs(write_paths) do
		ffi.C.add_write_path(path.name, path.path)
	end
end

function tdengine.init_phase_1()
  tdengine.enum.init()
  tdengine.ffi.init()
  tdengine.paths.init()
  tdengine.time_metric.init()
  tdengine.input.init()
  tdengine.gpu.init()
  tdengine.state.init()
  tdengine.animation.load()
  tdengine.texture.load()
  tdengine.background.load()
  tdengine.fonts.load()
  tdengine.dialogue.init()
  tdengine.audio.init()
  tdengine.gui.init()
  tdengine.scene.init()
end

function tdengine.init_phase_2()
  tdengine.subsystem.init()
  tdengine.app = tdengine.subsystem.find('App')

  tdengine.app:on_init_game()

  tdengine.window.init()
  tdengine.fonts.init()
  tdengine.shaders.init()
  tdengine.math.init()
  tdengine.save.init()
  tdengine.editor.init()
  tdengine.persistent.init()

  tdengine.lifecycle.run_callback(tdengine.lifecycle.callbacks.on_start_game)

end
