module HDivRefFEs

##

using Gridap, Test
using Gridap: CellValuesGallery

p = Polytope(1,1)
d = dim(p)
order = 2

facets = nfaces_dim(p,d-1)
nc = length(facets)

verts = vertices_coordinates(p)
facet_vs = nface_connections(p,d-1,0)

fvs = Gridap.CellValuesGallery.CellValueFromArray(facet_vs)
vs = Gridap.CellValuesGallery.CellValueFromArray(verts)

# Facet vertices coordinates
cfvs = Gridap.CellValuesGallery.CellVectorFromLocalToGlobal(fvs,vs)

fps = nface_ref_polytopes(p)[facets]
@assert(all(extrusion.(fps) .== extrusion(fps[1])), "All facet must be of the same type")
# Facet ref polytope
fp = fps[1]

# Quad and RefFE at ref facet
fquad = Quadrature(fp,order*2)
fips = coordinates(fquad)
cfips = ConstantCellValue(fips,nc)
freffe = LagrangianRefFE(Float64,fp,1)
fshfs = shfbasis(freffe)
# Facet RefFE shape functions
cfshfs = ConstantCellValue(fshfs, nc)
# Geomap from ref facet to polytope facets
fgeomap = lincomb(cfshfs,cfvs)

# Test
fnodes = freffe.dofbasis.nodes
evaluate(fshfs,fnodes)
cpoints = ConstantCellValue(fnodes,nc)
basis =  ConstantCellMap(fshfs,nc)
vs_f = evaluate(fgeomap,cpoints)
@test isa(fgeomap,CellGeomap)
@test vs_f[1][1] == Point(0.0,0.0)
@test vs_f[1][2] == Point(1.0,0.0)
@test vs_f[2][1] == Point(0.0,1.0)
@test vs_f[2][2] == Point(1.0,1.0)
@test vs_f[3][1] == Point(0.0,0.0)
@test vs_f[3][2] == Point(0.0,1.0)
@test vs_f[4][1] == Point(1.0,0.0)
@test vs_f[4][2] == Point(1.0,1.0)

cvals = evaluate(cfshfs,cfips)
# Ref facet FE functions evaluated at the facet integration points (in ref facet)
fshfs_fips = collect(cvals)

# j = evaluate(gradient(geomap),cpoints)
# meas(j)

cquad = ConstantCellQuadrature(fquad,nc)
# Integration points at ref facet
xquad = coordinates(cquad)
wquad = weights(cquad)
# Integration points mapped at the polytope facets
pquad = evaluate(fgeomap,xquad)

# reffe = LagrangianRefFE(VectorValue{d,Float64},p,2)
# p_lshapes = shfbasis(reffe)
# basis = MonomialBasis(Float64,(1,1))
# cbasis = ConstantCellValue(basis, nc)
# cvals = evaluate(cbasis,pquad)

fshfs = Gridap.RefFEs._monomial_basis(fp,Float64,order-1)
cfshfs = ConstantCellValue(fshfs, nc)
cvals = evaluate(cfshfs,cfips)
# Ref facet FE functions evaluated at the facet integration points (in ref facet)
fshfs_fips = collect(cvals)

basis = CurlGradMonomialBasis(VectorValue{d,Float64},order)
cbasis = ConstantCellValue(basis, nc)
pquad
cvals = evaluate(cbasis,pquad)
# Ref FE shape functions at facet integration points
shfs_fips = collect(cvals)

# Facet normals
fns, o = facet_normals(p)

# Test
b = shfs_fips[1]
n = fns[1]
@test eltype(b) == typeof(n)
# Weird behavior, I don't understand why it does not work
# c = broadcast(*,n,b)
# c = mybroadcast(n,b)


function mybroadcast(n,b)
        c = Array{Float64}(undef,size(b))
        # for (n,b) in zip(fns,shfs_fips)
        for (ii, i) in enumerate(b)
                c[ii] = i*n
        end
        return c
        # end
end
shfs_fips
nxshfs_fips = [ mybroadcast(n,b) for (n,b) in zip(fns,shfs_fips)]
# CellValueFromArray(nxshfs_fips)

# missing weights!

_fmoments = [nxshfs_fips[i]*(wquad[i]'.*fshfs_fips[i])' for i in 1:nc]
_size = [size(_fmoments[1])...]
_size[end] = _size[end]*length(_fmoments)
nsize = Tuple(_size)
# Native Julia way to append these arrays in one array?
fmoments = Array{eltype(_fmoments[1])}(undef,nsize)
offs = size(_fmoments[1])[end]
for i in 1:length(_fmoments)
        fmoments[:,(i-1)*offs+1:i*offs] = _fmoments[i]
end
fmoments

if (order>1)
        # Now the same for interior DOFs
        ibasis = GradMonomialBasis(VectorValue{d,Float64},order-1)
        iquad = Quadrature(p,order*2)
        iips = coordinates(iquad)
        iwei = weights(iquad)
        # Interior DOFs-related basis evaluated at interior integration points
        ishfs_iips = evaluate(ibasis,iips)
        # Prebasis evaluated at interior integration points
        shfs_iips = evaluate(basis,iips)
        imoments = shfs_iips*(iwei'.*ishfs_iips)'
        # Matrix of all moments (columns) for all prebasis elements (rows)
        moments = hcat(fmoments,imoments)
else
        moments = fmoments
end
moments
det(moments)

##

end # module HDivRefFEs
