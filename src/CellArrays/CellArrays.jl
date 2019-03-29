module CellArrays

using LinearAlgebra: det
import LinearAlgebra
using Base: @propagate_inbounds

using Numa.Helpers
using Numa.FieldValues

export CellArray
export IndexableCellArray
export CellArrayFromUnaryOp
export CellArrayFromElemUnaryOp
export ConstantCellArray
export cellsize
export celllength
export cellsum
export cellnewaxis
export binner
export bouter

include("CachedArray.jl")
include("AbstractCellArrays.jl")
include("Operators.jl")
include("ConstantCellArrays.jl")

end # module CellArrays