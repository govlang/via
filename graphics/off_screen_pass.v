module graphics
import via.math
import via.libs.sokol.gfx

pub struct OffScreenPass{
pub:
	color_tex Texture
	depth_tex Texture
    pass sg_pass
pub mut:
	pass_action sg_pass_action
}

pub fn offscreenpass(width, height int, min_filter gfx.Filter, mag_filter gfx.Filter, clear_color math.Color) OffScreenPass {
    color_tex := rendertexture(width, height, min_filter, mag_filter, false)
    depth_tex := rendertexture(width, height, min_filter, mag_filter, true)

	// create an offscreen render pass into those images
	mut pass_desc := sg_pass_desc{
        label: 'Offscreen Pass'.str
    }
	pass_desc.color_attachments[0].image = color_tex.img
    pass_desc.depth_stencil_attachment.image = depth_tex.img

	return OffScreenPass{
        color_tex: color_tex
        depth_tex: depth_tex
        pass_action: gfx.make_clear_pass(clear_color.r_f(), clear_color.g_f(), clear_color.b_f(), clear_color.a_f() )
        pass: sg_make_pass(&pass_desc)
    }
}

pub fn (p &OffScreenPass) free(free_images bool) {
    p.pass.free()

    if free_images {
        p.color_tex.free()
        p.depth_tex.free()
    }
}

pub fn (p mut OffScreenPass) set_depth_action(action gfx.Action, val f32) {
    p.pass_action.depth = sg_depth_attachment_action{
        action: action
        val: val
    }
}

pub fn (p mut OffScreenPass) set_stencil_action(action gfx.Action, val byte) {
    p.pass_action.stencil = sg_stencil_attachment_action{
        action: action
        val: val
    }
}

pub fn (p &OffScreenPass) get_pixel_perfect_config(w, h int) DrawConfig {
    mut scale := 1
    aspect_ratio := f32(w) / f32(h)
    if f32(p.color_tex.width) / f32(p.color_tex.height) > aspect_ratio {
        scale = w / p.color_tex.width
    } else {
        scale = h / p.color_tex.height
    }

    if scale == 0 {
        scale = 1
    }

    // scale--
    x := (w - (p.color_tex.width * scale)) / 2
    y := (h - (p.color_tex.height * scale)) / 2


    //ox:p.color_tex.width/2 oy:p.color_tex.height/2
    return {x:x y:y sx:scale sy:scale}
}

pub fn (p &OffScreenPass) begin() {
    sg_begin_pass(p.pass, &p.pass_action)
}