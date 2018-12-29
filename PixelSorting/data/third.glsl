#define DIR true

uniform ivec2 uResolution;
uniform sampler2D uFirstPass;
uniform sampler2D uSecondPass;


float fromRgb( vec3 v ) {
    return ( ( v.z * 256.0 + v.y ) * 256.0 + v.x ) * 255.0;
}

vec4 draw( vec2 uv ) {
    //return texture( iChannel0, uv );
    
    vec2 dir = DIR ? vec2( 0.0, 1.0 ) : vec2( 1.0, 0.0 );
    float wid = DIR ? uResolution.y : uResolution.x;
    float pos = DIR ? floor( uv.y * uResolution.y ) : floor( uv.x * uResolution.x );
    
    for ( int i = 0; i < int( wid ); i ++ ) {
        vec2 p = uv + dir * float( i ) / wid;
        if ( p.x < 1.0 && p.y < 1.0 ) {
            float v = fromRgb( texture( uFirstPass, p ).xyz );
            if ( abs( v - pos ) < 0.5 ) {
                return texture( uSecondPass, p );
                break;
            }
        }
        
        p = uv - dir * float( i ) / wid;
        if ( 0.0 < p.x && 0.0 < p.y ) {
            float v = fromRgb( texture( uFirstPass, p ).xyz );
            if ( abs( v - pos ) < 0.5 ) {
                return texture( uSecondPass, p );
                break;
            }
        }
    }
    
    return vec4( 1.0, 0.0, 1.0, 1.0 );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    fragColor = draw( fragCoord / uResolution.xy );
}

void main() {
    mainImage(gl_FragColor, gl_FragCoord.xy);
}