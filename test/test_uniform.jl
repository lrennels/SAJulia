using Distributions
using Test
using DataFrames
using CSVFiles
using DataStructures

################################################################################
## JULIA
################################################################################
include("../src/sample_sobol.jl")
include("../src/analyze_sobol.jl")
include("../src/test_functions/ishigami.jl")

# define the (uncertain) parameters of the problem and their distributions
data = SobolData(
    OrderedDict(:x1 => Uniform(-3.14159265359, 3.14159265359),
        :x2 => Uniform(-3.14159265359, 3.14159265359),
        :x3 => Uniform(-3.14159265359, 3.14159265359)),
    N = 1000
)

N = data.N
D = length(data.params)

# sampling
julia_sobolseq = sobol_sequence(N, D) |> DataFrame 
julia_samples = sample(data) |> DataFrame
julia_ishigami = ishigami(convert(Matrix, julia_samples)) |> DataFrame

# analysis
julia_A, julia_B, julia_AB = split_output(convert(Matrix, julia_ishigami), N, D)
analyze!(data, convert( Matrix, julia_ishigami)) 

################################################################################
## Python
################################################################################

# sampling
py_sobolseq = load("data/py_uniform/py_sobolseq.csv", header_exists=false, colnames = ["x1", "x2", "x3"]) |> DataFrame
py_samples = load("data/py_uniform/py_samples.csv", header_exists=false, colnames = ["x1", "x2", "x3"]) |> DataFrame
py_ishigami = load("data/py_uniform/py_ishigami.csv", header_exists=false) |> DataFrame

# analysis
py_A = load("data/py_uniform/py_A.csv", header_exists=false) |> DataFrame
py_B = load("data/py_uniform/py_B.csv", header_exists=false) |> DataFrame
py_AB = load("data/py_uniform/py_AB.csv", header_exists=false) |> DataFrame
py_firstorder = load("data/py_uniform/py_firstorder.csv", header_exists=false) |> DataFrame
py_totalorder = load("data/py_uniform/py_totalorder.csv", header_exists=false) |> DataFrame

################################################################################
## Testing
################################################################################

@testset "Uniform Sampling" begin
    @test convert(Matrix, julia_sobolseq) ≈ convert(Matrix, py_sobolseq) atol = 1e-9
    @test convert(Matrix, julia_samples) ≈ convert(Matrix, py_samples) atol = 1e-9
end

@testset "Uniform Analysis" begin
    @test convert(Matrix, julia_ishigami) ≈ convert(Matrix, py_ishigami) atol = 1e-9
    @test julia_A ≈ convert(Matrix, py_A) atol = 1e-9
    @test julia_B ≈ convert(Matrix, py_B) atol = 1e-9
    @test julia_AB ≈ convert(Matrix, py_AB) atol = 1e-9
    @test data.results["firstorder"] ≈ convert(Matrix, py_firstorder) atol = 1e-9
    @test data.results["totalorder"]≈ convert(Matrix, py_totalorder) atol = 1e-9
end