module graphics
import via.math
import via.window
import via.libs.sokol.gfx

pub struct OffScreenPass {
pub:
	color_tex Texture
	depth_tex Texture
	pass sg_pass
}

struct DefaultOffScreenPass {
pub:
	offscreen_pass OffScreenPass
	policy ResolutionPolicy
	scaler ResolutionScaler
}

pub fn offscreenpass(width, height int, min_filter gfx.Filter, mag_filter gfx.Filter) OffScreenPass {
	color_tex := rendertexture(width, height, min_filter, mag_filter, false)
	depth_tex := rendertexture(width, height, min_filter, mag_filter, true)

	// create an offscreen render pass into those images
	mut pass_desc := C.sg_pass_desc{
		label: 'Offscreen Pass'.str
	}
	pass_desc.color_attachments[0].image = color_tex.img
	pass_desc.depth_stencil_attachment.image = depth_tex.img

	return OffScreenPass{
		color_tex: color_tex
		depth_tex: depth_tex
		pass: sg_make_pass(&pass_desc)
	}
}

//#region DefaultOffscreenPass

fn defaultoffscreenpass(width, height int, policy ResolutionPolicy) &DefaultOffScreenPass {
	// fetch the ResolutionScaler first since it will decide the render texture size
	scaler := policy.get_scaler(width, height)
	return &DefaultOffScreenPass{
		offscreen_pass: offscreenpass(scaler.w, scaler.h, g.min_filter, g.mag_filter)
		policy: policy
		scaler: scaler
	}
}

fn (p &DefaultOffScreenPass) free() {
	p.offscreen_pass.free(true)
	unsafe { free(p) }
}

//#endregion

pub fn (p &OffScreenPass) free(free_images bool) {
	p.pass.free()

	if free_images {
		p.color_tex.free()
		p.depth_tex.free()
	}
}

//#region Resolution Policies for blitting the render target

pub fn (p &OffScreenPass) get_pixel_perfect_config() DrawConfig {
	w, h := window.drawable_size()

	mut scale := 1
	aspect_ratio := f32(w) / f32(h)
	if f32(p.color_tex.w) / f32(p.color_tex.h) > aspect_ratio {
		scale = w / p.color_tex.w
	} else {
		scale = h / p.color_tex.h
	}

	if scale == 0 {
		scale = 1
	}

	x := (w - (p.color_tex.w * scale)) / 2
	y := (h - (p.color_tex.h * scale)) / 2

	return {x:x y:y sx:scale sy:scale}
}

pub fn (p &OffScreenPass) get_pixel_perfect_no_border_config() DrawConfig {
	w, h := window.drawable_size()

	// we are going to do some cropping so we need to use floats for the scale then round up
	mut scale := 1
	aspect_ratio := f32(w) / f32(h)
	if f32(p.color_tex.w) / f32(p.color_tex.h) < aspect_ratio {
		scale_f := f32(w) / p.color_tex.w
		scale = math.iceil(scale_f)
	} else {
		scale_f := f32(h) / p.color_tex.h
		scale = math.iceil(scale_f)
	}

	if scale == 0 {
		scale = 1
	}

	x := (w - (p.color_tex.w * scale)) / 2
	y := (h - (p.color_tex.h * scale)) / 2

	return {x:x y:y sx:scale sy:scale}
}

//#endregion