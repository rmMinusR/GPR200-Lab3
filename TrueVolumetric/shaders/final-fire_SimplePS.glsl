#version 430

in float z;
in vec4 color;
out vec4 outColor;
out float depth;

void main() {
   outColor = vec4(color);
   depth = z;
}