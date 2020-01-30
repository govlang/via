module graphics
import via.math
import via.utils
import via.libs.sokol.gfx

pub struct AtlasBatch {
mut:
	bindings sg_bindings
	v_buffer_safe_to_update bool = true
	v_buffer_dirty bool
	verts []math.Vertex
	sprite_cnt int
	max_sprites int
	tex Texture
}

pub fn atlasbatch(tex Texture, max_sprites int) &AtlasBatch {
	mut sb := &AtlasBatch{
		// set default colors to white
		verts: utils.new_arr_with_default(max_sprites * 4, max_sprites * 4, math.Vertex{})
		max_sprites: max_sprites
	}

	indices := new_vert_quad_index_buffer(max_sprites)
	sb.bindings = bindings_create(sb.verts, .dynamic, indices, .immutable)
	sb.set_texture(tex)
	sb.update_verts()
	unsafe { indices.free() }

	return sb
}

// update methods
pub fn (sb mut AtlasBatch) update_verts() {
	if sb.v_buffer_safe_to_update {
		sg_update_buffer(sb.bindings.vertex_buffers[0], sb.verts.data, sizeof(math.Vertex) * sb.verts.len)
		sb.v_buffer_safe_to_update = false
		sb.v_buffer_dirty = false
	}
}

pub fn (sb mut AtlasBatch) set_texture(tex Texture) {
	sb.bindings.set_frag_image(0, tex.img)
	sb.tex = tex
}

pub fn (sb mut AtlasBatch) clear() {
	sb.sprite_cnt = 0
}

fn (sb &AtlasBatch) ensure_capacity() bool {
	if sb.sprite_cnt == sb.max_sprites {
		println('Error: sprite batch full. Aborting Add.')
		return false
	}
	return true
}

pub fn (sb mut AtlasBatch) set(index int, matrix &math.Mat32) {
	quad := math.quad(0, 0, sb.tex.width, sb.tex.width, sb.tex.height, sb.tex.height)
	sb.set_q(index, quad, matrix)
}

pub fn (sb mut AtlasBatch) set_q(index int, quad &math.Quad, matrix &math.Mat32) {
	base_vert := index * 4

	matrix.transform_vec2_arr(&sb.verts[base_vert], &quad.positions[0], 4)

	for i in 0..4 {
		sb.verts[base_vert + i].s = quad.texcoords[i].x
		sb.verts[base_vert + i].t = quad.texcoords[i].y
	}

	sb.v_buffer_dirty = true
}

pub fn (sb mut AtlasBatch) add(config DrawConfig) int {
	if !sb.ensure_capacity() {
		return -1
	}

	sb.set(sb.sprite_cnt, config.get_matrix())

	sb.v_buffer_dirty = true
	sb.sprite_cnt++
	return sb.sprite_cnt - 1
}

pub fn (sb mut AtlasBatch) add_q(quad &math.Quad, config DrawConfig) int {
	if !sb.ensure_capacity() {
		return -1
	}

	sb.set_q(sb.sprite_cnt, quad, config.get_matrix())

	sb.v_buffer_dirty = true
	sb.sprite_cnt++
	return sb.sprite_cnt - 1
}

pub fn (sb mut AtlasBatch) draw() {
	if sb.v_buffer_dirty {
		sb.update_verts()
	}

	sg_apply_bindings(&sb.bindings)
	sg_draw(0, sb.sprite_cnt * 6, 1)
	sb.v_buffer_safe_to_update = true
}

pub fn (sb &AtlasBatch) free() {
	sb.bindings.vertex_buffers[0].free()
	sb.bindings.index_buffer.free()

	unsafe {
		sb.verts.free()
		free(sb)
	}
}