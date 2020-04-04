Shader "Hakanai/Clock Hands"
{
    Properties
    {
        _MainTex ("Clock Data Texture", 2D) = "black" {}
        _GearRatios ("Gear Ratios", Vector) = (1,1,1,1)
        [Toggle(_)]
        _MechanicalSimulation ("Mechanical Simulation", Float) = 0

        _AlbedoTex ("Albedo (RGB)", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)

        _EmissionTex ("Emission Map (RGB)", 2D) = "white" {}
        [HDR]
        _EmissionColor ("Emission Color", Color) = (0,0,0,0)

        _Smoothness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
        }

        CGPROGRAM
        #pragma surface Surface Standard fullforwardshadows addshadow vertex:Vertex
        #pragma target 3.5

        struct Input
        {
            float2 uv_AlbedoTex;
        };

        #if defined(SHADER_STAGE_VERTEX) || defined(SHADER_STAGE_FRAGMENT) || defined(SHADER_STAGE_DOMAIN) || defined(SHADER_STAGE_HULL) || defined(SHADER_STAGE_GEOMETRY)
        #define SamplerState float4
        #endif

        // Texture2D _MainTex;
        // SamplerState my_point_clamp_sampler;
        uniform sampler2D _MainTex;
        uniform float4 _GearRatios;
        uniform bool _MechanicalSimulation;

        uniform sampler2D _AlbedoTex;
        uniform float4 _Color;
        uniform sampler2D _EmissionTex;
        uniform float4 _EmissionColor;
        uniform float _Smoothness;
        uniform float _Metallic;

        /**
         * Rotates a vertex around the Z axis by `turns` turns.
         *
         * @param vertex the input vertex.
         * @param turns the number of turns, generally a fraction if you want it to be useful.
         * @return the resulting vertex.
         */
        float4 rotateAroundZInTurns(float4 vertex, float turns)
        {
            float alpha = turns * UNITY_TWO_PI;
            float sina, cosa;
            sincos(alpha, sina, cosa);
            float2x2 m = float2x2(cosa, -sina, sina, cosa);
            return float4(mul(m, vertex.xy), vertex.zw);
        }

        /**
         * Converts linear colour to sRGB colour.
         *
         * @param x the input linear colour.
         * @return the colour converted to sRGB.
         */
        float3 LinearToSRGB(float3 x)
        {
            return (x <= 0.0031308) ? (12.92 * x) : (pow(x, 1.0/2.4) * 1.055 - 0.055);
        }

        /**
         * Converts a float in the range 0.0 ~ 1.0 to an int in the range 0 ~ 255.
         *
         * @param x the input float.
         * @return the resulting int.
         */
        uint4 Float01ToInt(float4 x)
        {
            return (uint4) round(saturate(x) * 255.0);
        }

        /**
         * Gets a cell value in the range 0 to 2^32-1 from the clock data texture.
         *
         * @param x the cell index.
         * @return the cell valuje.
         */
        uint getCellValue(uint x)
        {
            float4 a = tex2Dlod(_MainTex, float4(0.125 + 0.25 * (float) x, 0.5, 0.0, 0.0));
            a.rgb = LinearToSRGB(a.rgb);
            uint4 i = Float01ToInt(a);
            return dot(i, uint4(256 * 256 * 256, 256 * 256, 256, 1));
        }

        /**
         * Maps the input t-value 0.0 ~ 1.0 to an "ease out back" animation curve,
         * i.e., an animation which slightly overshoots and then bounces back.
         *
         * @param t the input t-value.
         * @return the output t-value.
         */
        float easeOutBack(float t)
        {
            const float s = 1.70158;
            t -= 1;
            return t * t * ((s + 1) * t + s) + 1;
        }

        void Vertex(inout appdata_full v)
        {
            float relTimeSeconds = _Time[1];

            uint epochSecondsUtcAtStart = getCellValue(0);
            uint epochSecondsUtc = epochSecondsUtcAtStart + (uint) relTimeSeconds;
            uint currentOffset = getCellValue(1);
            uint nextTransitionEpochSecondsUtc = getCellValue(2);
            uint nextTransitionOffset = getCellValue(3);

            // Image contains 0 for the next transition time if there isn't one.
            uint offset = (nextTransitionEpochSecondsUtc != 0 && epochSecondsUtc > nextTransitionEpochSecondsUtc) ?
                          nextTransitionOffset : currentOffset;
            uint epochSecondsLocal = epochSecondsUtc + offset;

            const uint secondsInDay = 60 * 60 * 24;
            const float inverseSecondsInDay = 1.0 / (float) secondsInDay;

            float fractionOfSecond = frac(relTimeSeconds);

            float secondsOfDay = (float) (epochSecondsLocal % secondsInDay);
            if (_MechanicalSimulation)
            {
                if (fractionOfSecond < 0.1)
                {
                    secondsOfDay += easeOutBack(fractionOfSecond / 0.1) - 1.0;
                }
            }
            else
            {
                secondsOfDay += frac(fractionOfSecond);
            }

            float fractionOfDay = secondsOfDay * inverseSecondsInDay;
            float fractionOfTurn = 0.0;

            bool hand = false;
            if (v.color.r > 0.5)
            {
                if (v.color.g > 0.5)
                {
                    // white
                }
                else
                {
                    // red
                    fractionOfTurn = frac(fractionOfDay * _GearRatios[0]);
                    hand = true;
                }
            }
            else if (v.color.g > 0.5)
            {
                if (v.color.b > 0.5)
                {
                    // cyan
                    fractionOfTurn = frac(fractionOfDay * _GearRatios[3]);
                    hand = true;
                }
                else
                {
                    // green
                    fractionOfTurn = frac(fractionOfDay * _GearRatios[1]);
                    hand = true;
                }
            }
            else if (v.color.b > 0.5)
            {
                // blue
                fractionOfTurn = frac(fractionOfDay * _GearRatios[2]);
                hand = true;
            }

            v.vertex = rotateAroundZInTurns(v.vertex, fractionOfTurn);

            // Hide hands until we have some data.
            if (epochSecondsUtcAtStart == 0 && hand)
            {
                v.vertex = 0.0;
            }
        }

        void Surface(Input input, inout SurfaceOutputStandard output)
        {
            fixed4 c = tex2D(_AlbedoTex, input.uv_AlbedoTex) * _Color;
            output.Albedo = c.rgb;
            output.Emission = tex2D(_EmissionTex, input.uv_AlbedoTex) * _EmissionColor;
            output.Metallic = _Metallic;
            output.Smoothness = _Smoothness;
            output.Alpha = c.a;
        }

        ENDCG
    }
    FallBack "Diffuse"
}
