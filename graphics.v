module via
import filepath
import via.fonts
import via.graphics
import via.libs.physfs
import via.libs.sokol.gfx

struct Graphics {
mut:
	min_filter gfx.Filter
	mag_filter gfx.Filter
	def_shader sg_shader
	def_pip sg_pipeline
	def_text_shader sg_shader
	def_text_pip sg_pipeline
}

fn new_graphics(config &ViaConfig) &Graphics {
	return &Graphics{
		min_filter: .nearest
 		mag_filter: .nearest
	}
}

fn (g &Graphics) free() {
	g.def_shader.free()
	g.def_pip.free()
	g.def_text_shader.free()
	g.def_text_pip.free()
	unsafe { free(g) }
}

fn (g mut Graphics) init_defaults() {
	desc := sg_desc{}
	sg_setup(&desc)

	pip, shader := graphics.pipeline_make_default()
	g.def_pip = pip
	g.def_shader = shader

	text_pip, text_shader := graphics.pipeline_make_default_text()
	g.def_text_pip = text_pip
	g.def_text_shader = text_shader
}

pub fn (g &Graphics) get_default_pipeline() sg_pipeline {
	return g.def_pip
}

pub fn (g &Graphics) get_default_text_pipeline() sg_pipeline {
	return g.def_text_pip
}

pub fn (g mut Graphics) set_default_filter(min, mag gfx.Filter) {
	g.min_filter = min
	g.mag_filter = mag
}

pub fn (g &Graphics) new_texture(src string) graphics.Texture {
	buf := physfs.read_bytes(src)
	tex := graphics.texture(buf, g.min_filter, g.mag_filter)
	unsafe { buf.free() }
	return tex
}

pub fn (g &Graphics) new_texture_atlas(src string) graphics.TextureAtlas {
	tex_src := src.replace(filepath.ext(src), '.png')
	tex := g.new_texture(tex_src)

	buf := physfs.read_bytes(src)
	return graphics.texture_atlas(tex, buf)
}

pub fn (g &Graphics) new_shader(vert, frag string, shader_desc &sg_shader_desc) C.sg_shader {
	mut vert_needs_free := false
	vert_src := if vert.len > 0 && vert.ends_with('.vert') {
		vert_needs_free = true
		physfs.read_text(vert)
	} else {
		vert
	}

	mut frag_needs_free := false
	frag_src := if frag.len > 0 && vert.ends_with('.frag') {
		frag_needs_free = true
		physfs.read_text(frag)
	} else {
		frag
	}

	shader := graphics.shader_make(vert_src, frag_src, mut shader_desc)

	if vert_needs_free {
		unsafe{ vert_src.free() }
	}
	if frag_needs_free {
		unsafe{ frag_src.free() }
	}

	return shader
}

pub fn (g &Graphics) new_pipeline(pipeline_desc &sg_pipeline_desc) sg_pipeline {
	return sg_make_pipeline(pipeline_desc)
}

pub fn (gg &Graphics) new_clear_pass(r, g, b, a f32) sg_pass_action {
	return gfx.create_clear_pass(r, g, b, a)
}

pub fn (g &Graphics) new_atlasbatch(tex graphics.Texture, max_sprites int) &graphics.AtlasBatch {
	return graphics.atlasbatch(tex, max_sprites)
}

pub fn (g &Graphics) new_fontstash(width, height int) &fonts.FontStash {
	return fonts.fontstash(width, height, g.min_filter, g.mag_filter)
}