Shader "Hakanai/Clock Hands"
{
    Properties
    {
        _FractionOfDay ("Fraction of Day", Float) = 0.0

        _GearRatios ("Gear Ratios", Vector) = (1,1,1,1)
        [Toggle(_)]
        _MechanicalSimulation ("Mechanical Simulation", Float) = 0

        _MainTex ("Albedo (RGB)", 2D) = "white" {}
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
            float2 uv_MainTex;
        };

        uniform float _FractionOfDay;

        uniform float4 _GearRatios;
        uniform bool _MechanicalSimulation;

        uniform sampler2D _MainTex;
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
            float fractionOfDay = _FractionOfDay;

            if (_MechanicalSimulation)
            {
                #define SECONDS_PER_DAY (60.0 * 60.0 * 24.0)
                float secondsOfDay = fractionOfDay * SECONDS_PER_DAY;
                float fractionOfSecond = frac(secondsOfDay);
                secondsOfDay -= fractionOfSecond;
                if (fractionOfSecond < 0.1)
                {
                    secondsOfDay = secondsOfDay + easeOutBack(fractionOfSecond * 0.1);
                }
                fractionOfDay = secondsOfDay / SECONDS_PER_DAY;
            }

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
        }

        void Surface(Input input, inout SurfaceOutputStandard output)
        {
            fixed4 c = tex2D(_MainTex, input.uv_MainTex) * _Color;
            output.Albedo = c.rgb;
            output.Emission = tex2D(_EmissionTex, input.uv_MainTex) * _EmissionColor;
            output.Metallic = _Metallic;
            output.Smoothness = _Smoothness;
            output.Alpha = c.a;
        }

        ENDCG
    }
    FallBack "Diffuse"
}
