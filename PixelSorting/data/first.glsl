
uniform ivec2 uResolution;
uniform sampler2D uSecondPass;
uniform float uTime;
float t;

#define DIR true
#define THR ( sin( t * 1.0 ) * 0.5 + 0.5 )
#define SHADOW false
#define REVERSE true



float gray( vec3 c ) {
    return dot( c, vec3( 0.299, 0.587, 0.114 ) );
}

vec3 toRgb( float i ) {
    return vec3(
        mod( i, 256.0 ),
        mod( floor( i / 256.0 ), 256.0 ),
        floor( i / 65536.0 )
    ) / 255.0;
}

bool thr( float v ) {
    return SHADOW ? ( THR < v ) : ( v < THR );
}

vec4 draw( vec2 uv ) {
    vec2 dir = DIR ? vec2( 0.0, 1.0 ) : vec2( 1.0, 0.0 );
    float wid = DIR ? uResolution.y : uResolution.x;
    float pos = DIR ? floor( uv.y * uResolution.y ) : floor( uv.x * uResolution.x );
    
    float val = gray( texture( uSecondPass, uv ).xyz );
    
    if ( !thr( val ) ) {
        float post = pos;
        float rank = 0.0;
        float head = 0.0;
        float tail = 0.0;
        
        for ( int i = 0; i < int( wid ); i ++ ) {
            post -= 1.0;
            if ( post == -1.0 ) { head = post + 1.0; break; }
            vec2 p = dir * ( post + 0.5 ) / wid + dir.yx * uv;
            float v = gray( texture( uSecondPass, p ).xyz );
            if ( thr( v ) ) { head = post + 1.0; break; }
            if ( v <= val ) { rank += 1.0; }
        }
        
        post = pos;
        for ( int i = 0; i < int( wid ); i ++ ) {
            post += 1.0;
            if ( wid == post ) { tail = post - 1.0; break; }
            vec2 p = dir * ( post + 0.5 ) / wid + dir.yx * uv;
            float v = gray( texture( uSecondPass, p ).xyz );
            if ( thr( v ) ) { tail = post - 1.0; break; }
            if ( v < val ) { rank += 1.0; }
        }
        
        pos = REVERSE ? ( tail - rank ) : ( head + rank );
    }
    
    return vec4( toRgb( pos ), 1.0 );
}


void main(){
    t = uTime/1000;
    gl_FragColor = draw( gl_FragCoord.xy / uResolution.xy );
}