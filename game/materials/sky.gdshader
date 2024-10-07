shader_type sky;

#ifndef AT_CUBEMAP_PASS
#define AT_CUBEMAP_PASS false
#endif

uniform float luminance = 1.05; // formerly uniform
const float night_luminance = 1.125;
uniform float turbidity = 8.0; // formerly uniform
uniform float reileigh = 1.25; // formerly uniform
uniform float mieCoefficient = 0.005;
uniform float mieDirectionalG = 0.8;
uniform float light_power = 0.5;
uniform float light_power_adjust = 4.0;
uniform float exposure = -4.0;
uniform float ambient_boost = 0.0;

// constants for atmospheric scattering
const float e = 2.71828182845904523536028747135266249775724709369995957;

// refractive index of air
const float n = 1.0003;

// number of molecules per unit volume for air at 288.15K and 1013mb (sea level -45 celsius)
const float N = 2.545E25;

// depolatization factor for standard air
const float pn = 0.035;

// wavelength of used primaries, according to preetham
const vec3 kLambda = vec3(680E-9, 550E-9, 450E-9);

// mie stuff
// K coefficient for the primaries
const vec3 kK = vec3(0.686, 0.678, 0.666);
const float v = 4.0;

// optical length at zenith for molecules
const float rayleighZenithLength = 8.4E3;
const float mieZenithLength = 1.25E3;
const vec3 up = vec3(0.0, 1.0, 0.0);

const float EE = 1000.0;
// increased size so it can bloom
const float sunAngularDiameterCos = 0.99996192306417 * 0.999925;//*0.9995; // probably correct size, maybe

// earth shadow hack
const float steepness = 1.5;

vec3 totalRayleigh(vec3 lambda) {
	return (8.0 * pow(PI, 3.0) * pow(pow(n, 2.0) - 1.0, 2.0) * (6.0 + 3.0 * pn)) / (3.0 * N * pow(lambda, vec3(4.0)) * (6.0 - 7.0 * pn));
}

// see http://blenderartists.org/forum/showthread.php?321110-Shaders-and-Skybox-madness
// A simplied version of the total Rayleigh scattering to works on browsers that use ANGLE
vec3 simplifiedRayleigh() {
	return 0.00054532832366 / vec3(94.0, 40.0, 18.0);
}

float rayleighPhase(float cosTheta) {
	return (3.0 / (16.0*PI)) * (1.0 + pow(cosTheta, 2.0));
}

vec3 totalMie(vec3 lambda, vec3 K, float T) {
	float c = (0.2 * T ) * 10E-18;
	return 0.434 * c * PI * pow(TAU / lambda, vec3(v - 2.0)) * K;
}

float hgPhase(float cosTheta, float g) {
	return (1.0 / (4.0*PI)) * ((1.0 - pow(g, 2.0)) / pow(1.0 - 2.0*g*cosTheta + pow(g, 2.0), 1.5));
}

float sunIntensity(float zenithAngleCos) {
	// See https://github.com/mrdoob/three.js/issues/8382
	float cutoffAngle = PI/1.95;
	return EE * max(0.0, 1.0 - pow(e, -((cutoffAngle - acos(zenithAngleCos))/steepness)));
}

vec3 generate_sky(vec3 in_dir, vec3 sun_dir, vec3 moon_dir) {
	// several of these could be precomputed (not view dependent) outside of this shader (cpu or vs)
	float sunfade = 1.0-clamp(1.0-exp((sun_dir.y/450000.0)),0.0,1.0);
	float reileighCoefficient = reileigh - (1.0 * (1.0-sunfade));
	vec3 sunDirection = normalize(sun_dir.xyz);
	float sunE = sunIntensity(dot(sunDirection, up));

	// extinction (absorbtion + out scattering)
	// rayleigh coefficients
	vec3 betaR = simplifiedRayleigh() * reileighCoefficient;

	// mie coefficients
	vec3 betaM = totalMie(kLambda, kK, turbidity) * mieCoefficient;

	// optical length
	// cutoff angle at 90 to avoid singularity in next formula.
	float zenithAngle = acos(max(0.0, dot(up, normalize(in_dir.xyz))));
	float sR = rayleighZenithLength / (cos(zenithAngle) + 0.15 * pow(93.885 - ((zenithAngle * 180.0) / PI), -1.253));
	float sM = mieZenithLength / (cos(zenithAngle) + 0.15 * pow(93.885 - ((zenithAngle * 180.0) / PI), -1.253));

	// combined extinction factor
	vec3 Fex = exp(-(betaR * sR + betaM * sM));

	// in scattering
	float cosTheta = dot(normalize(in_dir.xyz), sunDirection);

	float rPhase = rayleighPhase(cosTheta*0.5+0.5);
	vec3 betaRTheta = betaR * rPhase;

	float mPhase = hgPhase(cosTheta, mieDirectionalG);
	vec3 betaMTheta = betaM * mPhase;

	vec3 Lin = pow(sunE * ((betaRTheta + betaMTheta) / (betaR + betaM)) * (1.0 - Fex),vec3(1.5));
	float sun_dot_up = dot(up, sunDirection);

	Lin *= mix(vec3(1.0), pow(sunE * ((betaRTheta + betaMTheta) / (betaR + betaM)) * Fex, vec3(1.0/2.0)), clamp(pow(1.0-sun_dot_up,5.0),0.0,1.0));

	// night sky
	vec3 direction = normalize(in_dir.xyz);
	float theta = acos(direction.y); // elevation --> y-axis, [-pi/2, pi/2]
	float phi = atan(direction.z / direction.x); // azimuth --> x-axis [-pi/2, pi/2]
	//vec3 L0 = vec3(0.1) * Fex;
	vec3 L0 = Fex;

	// composition + solar disc
	if (!AT_CUBEMAP_PASS) {
		float sundisk = smoothstep(sunAngularDiameterCos, sunAngularDiameterCos + 0.001, cosTheta);
		vec3 halo = kK * kLambda * pow(max(0.0, cosTheta * cosTheta * cosTheta), 100.0) * (0.5 + 0.5 * vec3(4.0, 10.0, 17.0)) * sunE * 0.001;
		vec3 halo2 = kK * kLambda * pow(max(0.0, cosTheta), 2.0) * (0.5 + 0.5 * vec3(4.0, 10.0, 17.0)) / max(1.0, sunE) * EE * 0.05;
		L0 += (sunE * 19000.0 * LIGHT0_ENERGY * Fex) * (sundisk + halo + halo2) * LIGHT0_COLOR * 20.0;

		float moonCosTheta = dot(normalize(in_dir.xyz), moon_dir);
		float moondisk = smoothstep(sunAngularDiameterCos,sunAngularDiameterCos+0.0005,moonCosTheta) * 20.0;
		float mhalo = pow(max(0.0, moonCosTheta), 2.0) * 0.0001;
		L0 += (moondisk + mhalo) * 50000.0;// * LIGHT1_ENERGY; // doesn't help
	}

	vec3 texColor = (Lin + L0);
	texColor *= 0.06 * light_power_adjust;
	texColor += vec3(0.0, 0.001, 0.0025) * 0.3;

	float night_lum = mix(1.125, luminance, max(0.0, dot(sunDirection, up)));
	vec3 color = log2(2.0/pow(night_lum,4.0))*texColor;

	vec3 retColor = pow(color,vec3(1.0/(1.2+(1.2*sunfade))));
	retColor = mix(retColor * 0.75, retColor, clamp(dot(direction, up) * 0.5 + 0.5, 0.0, 1.0));
	//retColor *= exp2(0.25); // why?
	retColor *= exp2(exposure);
	retColor = pow(retColor, vec3(1.5));
	if (LIGHT0_ENABLED) {
		retColor *= exp2(LIGHT0_ENERGY * light_power);
	}
	if (AT_CUBEMAP_PASS) {
		retColor *= exp2(ambient_boost);
	}
	return retColor;
}

float dither17(vec2 pos, float index_mod_4) {
	return fract(dot(vec3(pos.xy, index_mod_4), vec3(2.0, 7.0, 23.0) / 17.0));
}

void sky() {
	//vec2 star_uv = EYEDIR.xz / EYEDIR.y;
	float sky_mix = smoothstep(-0.1, 0.5, dot(EYEDIR, vec3(0.0, 1.0, 0.0)));
	COLOR = generate_sky(EYEDIR, LIGHT0_DIRECTION, LIGHT1_DIRECTION);
	COLOR += length(COLOR) * (dither17(FRAGCOORD.xy, 0) * 2.0 - 1.0) * 0.01;
}
