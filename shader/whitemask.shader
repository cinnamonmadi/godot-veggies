shader_type canvas_item;

uniform bool whitemask_enabled = false;

void fragment(){
	COLOR = texture(TEXTURE, UV);
	if(whitemask_enabled && COLOR.a == 1.0){

		COLOR.r = 1.0;
		COLOR.g = 1.0;
		COLOR.b = 1.0;
	}
}