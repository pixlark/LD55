local noise = {}

-- Geneate linearly interpolated noise at some frequency and amplitude.
-- The `phase` argument is optional, and can be used as a "seed" to shift
-- the noise function arbitrarily along its input axis.
function noise.linearNoise(t, amplitude, frequency, phase)
    phase = phase or 0

    t = (t + phase) * frequency
    local seed = math.floor(t)
    local first  = 2 * amplitude * (love.math.newRandomGenerator(seed)    :random() - 0.5)
    local second = 2 * amplitude * (love.math.newRandomGenerator(seed + 1):random() - 0.5)
    -- print("> "..tostring(seed).." "..tostring(first).." "..tostring(second))
    return std.math.lerp(first, second, t - seed)
end


return noise
